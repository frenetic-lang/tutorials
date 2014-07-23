open OxPlatform
open OpenFlow0x01
open OpenFlow0x01_Core
open Network_Common

module Topology = Net.Topology

module MyApplication = struct

  include OxStart.DefaultTutorialHandlers

  let topology = Net.Parse.from_dotfile "topology.dot"

  let () = 
    let fd = open_out "topology.py" in 
    Printf.fprintf fd "%s" (Net.Pretty.to_mininet topology);
    close_out fd

  let is_host v = 
    match Node.device (Topology.vertex_to_label topology v) with 
    | Node.Host -> true 
    | _ -> false  
  
  let hosts = 
    Topology.VertexSet.filter is_host (Topology.vertexes topology)

  let all_hops = 
    let t = Topology.VertexHash.create 17 in 
    Topology.VertexSet.iter
      (fun h -> Topology.VertexHash.add t h (Net.UnitPath.all_shortest_paths topology h))
      hosts;
    t
       
  let prev_hop src curr = 
    try 
      let paths = Topology.VertexHash.find all_hops src in 
      let prev = Topology.VertexHash.find paths curr in 
      Some (Topology.edge_src (Topology.find_edge topology prev curr))
    with _ -> 
      None

  let rule mac port = 
    let pat = { match_all with dlDst = Some mac } in 
    let acts = [Output (PhysicalPort(Int32.to_int port))] in 
    (pat,acts)    

  let path_rules src dst = 
    let mac = Node.mac (Topology.vertex_to_label topology dst) in 
    let rec loop src curr rules = 
      if src = curr then rules 
      else 
	match prev_hop src curr with
	| Some (prev,port) -> 
	   let sw = Node.id (Topology.vertex_to_label topology prev) in 
	   loop src prev ((sw, rule mac port)::rules)
	| None -> rules in 
    loop src dst []

  let all_rules = 
    Topology.VertexSet.fold 
      (fun src rules ->          
       Topology.VertexSet.fold 
	 (fun dst rules -> 
	  if src = dst then rules
	  else 		
	    (path_rules src dst)@rules)
	 hosts rules)
      hosts []
		
  let switch_connected (sw: switchId) (feats : SwitchFeatures.t) : unit = 
    List.iter 
      (fun (sw',(pat,acts)) -> 
       if sw = sw' then send_flow_mod sw 0l (add_flow 100 pat acts))
      all_rules

  let packet_in (sw : switchId) (xid : xid) (pk : packetIn) : unit =
    ()

end

module Controller = OxStart.Make (MyApplication)

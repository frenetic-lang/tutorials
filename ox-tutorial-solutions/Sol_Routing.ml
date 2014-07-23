open OxPlatform
open OpenFlow0x01
open OpenFlow0x01_Core
open Network_Common

module Network = Net
module Topology = Network.Topology

module MyApplication = struct

  include OxStart.DefaultTutorialHandlers

  let topology = Network.Parse.from_dotfile "topology.dot"

  let is_host topo v = 
    match Node.device (Topology.vertex_to_label topo v) with 
    | Node.Host -> true 
    | _ -> false  
  
  let hosts = 
    Topology.VertexSet.filter (is_host topology) (Topology.vertexes topology)

  let rules = 
    Topology.VertexSet.fold 
      (fun src rules ->          
         let src_paths = Network.UnitPath.all_shortest_paths topology src in 
         Topology.VertexSet.fold 
	   (fun dst rules -> 
	      if src = dst then rules
	      else 		
		begin
		  let dst_addr = Node.ip (Topology.vertex_to_label topology dst) in 
		  let rec loop curr next rules = 
		    if curr = src then rules
		    else 
		      let sw = Node.id (Topology.vertex_to_label topology curr) in 
		      let _,out_port = Topology.edge_src (Topology.find_edge topology curr next) in
		      let rules' = (sw, dst_addr, Int32.to_int out_port)::rules in 
		      loop (Topology.VertexHash.find src_paths curr) curr rules' in 
		  loop (Topology.VertexHash.find src_paths dst) dst rules
		end)
	   hosts rules)
      hosts []
		
  let switch_connected (sw: switchId) (feats : SwitchFeatures.t) : unit = 
    List.iter 
      (fun (sw', ip, pt) -> 
       if sw = sw' then
	 let match_ip = 
	   { match_all with 
	     dlTyp = Some 0x800;
	     nwDst = Some { m_value = ip; m_mask = None } } in 
	 send_flow_mod sw 0l (add_flow 100 match_ip [Output (PhysicalPort pt)])
       else ())
      rules
         

  let packet_in (sw : switchId) (xid : xid) (pk : packetIn) : unit =
    ()

end

module Controller = OxStart.Make (MyApplication)

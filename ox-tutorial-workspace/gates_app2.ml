open OxPlatform
open OpenFlow0x01
open OpenFlow0x01_Core
open Network_Common
open Packet

let topology_dot_file = "gates.dot"

module Topology = Net.Topology

module GatesApp : OxStart.OXMODULE = struct

  include OxStart.DefaultTutorialHandlers

  let topology = Net.Parse.from_dotfile topology_dot_file

  (****************************** Shortest Path Routing ******************************)

  let is_host v = 
    match Node.device (Topology.vertex_to_label topology v) with 
    | Node.Host -> true 
    | _ -> false  
	     
  let hosts = 
    Topology.VertexSet.filter (Topology.vertexes topology) ~f:is_host

  let all_hops = 
    let t = Topology.VertexHash.create () in 
    Topology.VertexSet.iter 
      hosts
      ~f:(fun h -> Topology.VertexHash.add_exn t h (Net.UnitPath.all_shortest_paths topology h));
    t
      
  let prev_hop src curr = 
    try
      let paths = Topology.VertexHash.find_exn all_hops src in
      let prev = Topology.VertexHash.find_exn paths curr in
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
      hosts 
      ~init:[]
      ~f:(fun rules src ->
	  Topology.VertexSet.fold 
	    hosts 
	    ~init:rules
	    ~f:(fun rules dst ->
		if src = dst then rules
		else (path_rules src dst)@rules))

  (***********************************************************************)
  (******* New host joins or host moved ports ****************************)

  let original_hosts : (dlAddr, (sw,portId)) Hashtbl.t = Hashtbl.create 50 

  (* rule = (pattern, list of actions , priority - int)*)
  let hosts_policies : (dlAddr, (sw, rule) list) Hashtbl.t = Hashtbl.create 50

  let get_original_policies (hosts : dlAddr list) (pol : (dlAddr, (sw,rule)) Hashtbl.t) =
    List.flatten (List.fold_left (fun a e -> (Hashtbl.find pol e)::a) [] hosts)

  (* return all the new policies from and to the new host added *)
  let compute_new_policies new_host original_hosts = 
    let p1 = Topology.VertexSet.fold 
      new_host 
      ~init: []
      ~f:(fun rules src ->
	  Topology.VertexSet.fold 
	    hosts 
	    ~init:rules
	    ~f:(fun rules dst ->
		if src = dst then rules
		else (path_rules src dst)@rules))
    in
    let p2 = Topology.VertexSet.fold 
      hosts 
      ~init:p1
      ~f:(fun rules src ->z
	  Topology.VertexSet.fold 
	    new_hosts
	    ~init:rules
	    ~f:(fun rules dst ->
		if src = dst then rules
		else (path_rules src dst)@rules))

  let check_new_host new_host =
    let (dlAddr, (sw,portId)) = new_host in
    try 
      let old_pt = Hashtbl.find original_hosts dlAddr in
      (*also check switch*)
      if portId = old_pt then []
      else 
	let _ = Hashtbl.remove original_hosts dlAddr in
	compute_new_policies new_host original_hosts
    with Not_found ->
	 compute_new_policies new_host original_hosts

  (****************************** Learning ******************************)

  let known_hosts : (dlAddr, portId) Hashtbl.t = Hashtbl.create 50 

  (* Store the location (port) of each host in the
     known_hosts hashtable. *)
  let learning_packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
    let pk = parse_payload pktIn.input_payload in
    Hashtbl.add known_hosts pk.Packet.dlSrc pktIn.port

  (* Route packets to known hosts out the correct port, otherwise flood them. *)
  let routing_packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
    let pk = parse_payload pktIn.input_payload in
    let pkt_dst = pk.Packet.dlDst in
    let pkt_src = pk.Packet.dlSrc in
    try
      let out_port = Hashtbl.find known_hosts pkt_dst in
      let src_port = pktIn.port in
      let src_dst_match = {match_all with dlDst = Some pkt_dst; dlSrc = Some pkt_src} in
      let dst_src_match = {match_all with dlDst = Some pkt_src; dlSrc = Some pkt_dst} in
      Printf.printf "<routing_packet_in>: Installing rule for host %Ld to %Ld.\n" pkt_src pkt_dst;
      send_flow_mod sw 0l (add_flow 100 src_dst_match [Output (PhysicalPort out_port)]);
      Printf.printf "<routing_packet_in>: Installing rule for host %Ld to %Ld.\n" pkt_dst pkt_src;
      send_flow_mod sw 0l (add_flow 100 dst_src_match [Output (PhysicalPort src_port)]);
      send_packet_out sw 0l {
			output_payload = pktIn.input_payload;
			port_id = None;
			apply_actions = [Output (PhysicalPort out_port)]
		      } 
    with Not_found ->
      (
        Printf.printf "<routing_packet_in>: Flooding to %Ld.\n" pkt_dst;
	send_packet_out sw 0l {
			  output_payload = pktIn.input_payload;
			  port_id = None;
			  apply_actions = [Output AllPorts]
      })

  (****************************** ********* ******************************)
	
  let switch_connected (sw: switchId) (feats : SwitchFeatures.t) : unit = 
    List.iter 
      (fun (sw',(pat,acts)) -> 
       if sw = sw' then send_flow_mod sw 0l (add_flow 100 pat acts))
      all_rules;
    send_flow_mod sw 0l (add_flow 0 match_all [])
		  
  let packet_in (sw : switchId) (xid : xid) (pk : packetIn) : unit =
    Printf.printf "<packet_in>: %s\n%!" (packetIn_to_string pk);
    learning_packet_in sw xid pk;
    routing_packet_in sw xid pk

end

module Controller = OxStart.Make (GatesApp)

let () = Controller.run ()

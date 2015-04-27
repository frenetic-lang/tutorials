open OxPlatform
open OpenFlow0x01
open OpenFlow0x01_Core
open Network_Common
open Packet

(* The .dot file must include switches only and no hosts in the topology *)
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

  (****************************** spanning tree rules ***************************)
  (* 
    In the topology, there are two kinds of ports on each switch: 
    1) inner network ports (INP): ports that connect to other switches 
    2) outer network ports (ONP): ports that do not connect to other switches

    INPs on a switch are split into two categories:
    a) spanning tree ports (STP): ports that have an edge in the spanning tree 
    b) non-spanning tree ports (N-STP): ports that connect to other switches but the 
      edges associated with these ports are not part of the spanning tree. 

    At the start of the controller, these low priority rules are installed on each switch
    ---------------------------------------------------------------------------------
    | src port type   | output ports                                  | priority    |
    ---------------------------------------------------------------------------------
    | STP             | all ports (excluding src port)                | 30          |
    ---------------------------------------------------------------------------------
    | N-STP           | DROP                                          | 20          |
    ---------------------------------------------------------------------------------
    | ONP             | all ports (excluding src port) + controller   | 10          |
    ---------------------------------------------------------------------------------
 *)
  
  let switch_stps_hash = Hashtbl.create 50
  let routing_rules = Hashtbl.create 50 

  let is_switch v = 
    match Node.device (Topology.vertex_to_label topology v) with 
    | Node.Switch -> true 
    | _ -> false  
  
  let all_switches = 
    Topology.VertexSet.filter (Topology.vertexes topology) ~f:is_switch

  let spanningtree_edges (root: Topology.vertex) (subroot_edges_lst: ((Topology.vertex * (Topology.edge list)) list)) : (Topology.vertex * (Topology.edge list)) =
    let f subroot edges = 
      (Topology.find_edge topology root subroot)::edges in
    let edges = 
      List.fold_left 
        (fun acc (subroot, edges) -> (f subroot edges)@acc)
        []
        subroot_edges_lst in
    (root, edges)

  (* returns a pair of PortSet's (stps, n_stps) for switch sw. stps and n_stps are
     the spanning tree ports and the non-spanning tree ports, respectively, 
     associated with switch sw *)
  let switch_to_inps (sw : Topology.vertex) : Topology.PortSet.t * Topology.PortSet.t = 
    let nhbrs = Topology.neighbors topology sw in
    let edges = 
      Topology.VertexSet.fold 
        nhbrs 
        ~init: Topology.EdgeSet.empty 
        ~f:(fun edges nhbr->
          Topology.EdgeSet.add edges (Topology.find_edge topology sw nhbr)) in
    let inps = 
     Topology.EdgeSet.fold 
        edges 
        ~init: Topology.PortSet.empty 
        ~f:(fun ports edge -> 
          Topology.PortSet.add ports (snd (Topology.edge_src edge))) in
    let stps = Hashtbl.find switch_stps_hash sw in
    let n_stps = Topology.PortSet.diff inps stps in 
    Printf.printf "<switch_to_inps>: (%d, %d)\n" (List.length (Topology.PortSet.elements stps)) (List.length (Topology.PortSet.elements n_stps));
    (stps, n_stps)

  let in_port_rule priority in_port acts= 
    let pat = { match_all with inPort = Some (Int32.to_int in_port)} in 
    (priority, pat, acts)

  let switch_rules (sw: Topology.vertex) =
    let (stps, n_stps) = switch_to_inps sw in 
    let all_rules = 
      Topology.PortSet.fold 
        stps 
        ~init:[]
        ~f:(fun rules in_port ->
          (in_port_rule 30 in_port [Output AllPorts])::rules) in
    let all_rules = 
      Topology.PortSet.fold 
        n_stps 
        ~init:all_rules
        ~f:(fun rules in_port -> 
          (in_port_rule 20 in_port [])::rules) in 
    (10, match_all, [Output (Controller 1024); Output AllPorts]):: all_rules

  let () = 
    let root = 
      match Topology.VertexSet.choose all_switches with 
      | Some sw -> sw
      | None -> failwith "Network has no switches" in
    let (_, st_edges) = Net.spanningtree_from spanningtree_edges topology root in
    let add_to_hash edge = 
      let (sw1, port1) = Topology.edge_src edge in
      let (sw2, port2) = Topology.edge_dst edge in
      let sw1_ports =  Hashtbl.find switch_stps_hash sw1 in
      let sw2_ports =  Hashtbl.find switch_stps_hash sw2 in
      let sw1_ports = Topology.PortSet.add sw1_ports port1 in
      let sw2_ports = Topology.PortSet.add sw2_ports port2 in
      Hashtbl.add switch_stps_hash sw1 sw1_ports;
      Hashtbl.add switch_stps_hash sw2 sw2_ports 
    in 
    Topology.VertexSet.fold 
      all_switches 
      ~init:()
      ~f:(fun () sw -> Hashtbl.add switch_stps_hash sw Topology.PortSet.empty);
    List.fold_left (fun () edge -> add_to_hash edge) () st_edges;
    Topology.VertexSet.fold 
      all_switches 
      ~init:()
      ~f:(fun () sw -> 
        Hashtbl.add 
          routing_rules 
          (Node.id (Topology.vertex_to_label topology sw)) 
          (switch_rules sw))

  (****************************** ********* ******************************)
    
  let switch_connected (sw: switchId) (feats : SwitchFeatures.t) : unit =
    try 
      let rules = Hashtbl.find routing_rules sw in
      List.iter
        (fun (priority, pat, acts) -> 
          send_flow_mod sw 0l (add_flow priority pat acts))
        rules;
      Printf.printf "<switch_connected>: switch %d connected. %d\n" (Int64.to_int sw) (List.length rules);
      send_flow_mod sw 0l (add_flow 0 match_all [])
    with _ -> 
      Printf.printf "<switch_connected>: switch %d connected...\n" (Int64.to_int sw);
      send_flow_mod sw 0l (add_flow 0 match_all [])

  let packet_in (sw : switchId) (xid : xid) (pk : packetIn) : unit =
    Printf.printf "<packet_in>: %s\n%!" (packetIn_to_string pk);
    (* learning_packet_in sw xid pk; *)
    (* routing_packet_in sw xid pk *)

end

module Controller = OxStart.Make (GatesApp)

let () = Controller.run ()

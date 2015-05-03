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

  let topology : Topology.t ref = ref (Net.Parse.from_dotfile topology_dot_file)

  (*************************** spanning tree rules ***************************)
  (* 
    In the topology, there are two kinds of ports on each switch:
    1) inner network ports (INP): ports that connect to other switches 
    2) outer network ports (ONP): ports that do not connect to other switches

    INPs on a switch are split into two categories:
    a) spanning tree ports (STP): ports that have an edge in the spanning tree 
    b) non-spanning tree ports (N-STP): ports that connect to other switches but
      the edges associated with these ports are not part of the spanning tree. 

    At the start of the controller, these low priority rules are installed on 
    each switch:
    ----------------------------------------------------------------------------
    | src port type | output ports                                  | priority |
    ----------------------------------------------------------------------------
    | STP           | all ports (excluding src port)                | 30       |
    ----------------------------------------------------------------------------
    | N-STP         | DROP                                          | 20       |
    ----------------------------------------------------------------------------
    | ONP           | all ports (excluding src port) + controller   | 10       |
    ----------------------------------------------------------------------------
 *)

  (* The hashtables switch_stps_hash, switch_n_stps_hash, and switch_inps_hash
    map a switch vertex to its spanning tree ports (STPs), non-spanning tree 
    ports (N-STPs), and inner network ports (INPs), respectively.
    For each switch, INPs is the union of STPs and N-STPs *)
  let switch_stps_hash : (Topology.vertex, Topology.PortSet.t) Hashtbl.t = 
    Hashtbl.create 50
  let switch_n_stps_hash : (Topology.vertex, Topology.PortSet.t) Hashtbl.t = 
    Hashtbl.create 50
  let switch_inps_hash : (Topology.vertex, Topology.PortSet.t) Hashtbl.t = 
    Hashtbl.create 50  

  (* maps a switch ID to the low priority rules described in the main 
    comment above *)
  let spanning_tree_rules 
      : (switchId, (int * pattern * (action list)) list) Hashtbl.t = 
    Hashtbl.create 50 

  let is_switch (v: Topology.vertex) : bool = 
    match Node.device (Topology.vertex_to_label !topology v) with 
    | Node.Switch -> true 
    | _ -> false  
  
  let all_switches : (Topology.VertexSet.t) = 
    Topology.VertexSet.filter (Topology.vertexes !topology) ~f:is_switch

  let spanningtree_edges (root: Topology.vertex) 
      (subroot_edges_lst: ((Topology.vertex * (Topology.edge list)) list)) 
      : (Topology.vertex * (Topology.edge list)) =
    let f subroot edges = 
      (Topology.find_edge !topology root subroot)::edges in
    let edges = 
      List.fold_left 
        (fun acc (subroot, edges) -> (f subroot edges)@acc)
        []
        subroot_edges_lst in
    (root, edges)

  (* populates the two hashtables switch_inps_hash and switch_n_stps_hash.
    Precondition: the hashtable switch_stps_hash has been populated already *)
  let populate_hashes (sw : Topology.vertex) : unit = 
    let nhbrs = Topology.neighbors !topology sw in
    let edges = 
      Topology.VertexSet.fold 
        nhbrs 
        ~init: Topology.EdgeSet.empty 
        ~f:(fun edges nhbr->
          Topology.EdgeSet.add edges (Topology.find_edge !topology sw nhbr)) in
    let inps = 
     Topology.EdgeSet.fold 
        edges 
        ~init: Topology.PortSet.empty 
        ~f:(fun ports edge -> 
          Topology.PortSet.add ports (snd (Topology.edge_src edge))) in
    let stps = Hashtbl.find switch_stps_hash sw in
    let n_stps = Topology.PortSet.diff inps stps in
    let () = Hashtbl.add switch_inps_hash sw inps in 
    Hashtbl.add switch_n_stps_hash sw n_stps

  let in_port_rule (priority: int) (in_port: Topology.port) (acts: action list)
      : int * pattern * (action list) = 
    let pat = { match_all with inPort = Some (Int32.to_int in_port)} in 
    (priority, pat, acts)

  let switch_rules (sw: Topology.vertex) : (int * pattern * (action list)) list =
    let stps = Hashtbl.find switch_stps_hash sw in 
    let n_stps = Hashtbl.find switch_n_stps_hash sw in 
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
    (* populate the hashtable switch_stps_hash *)
    let root = 
      match Topology.VertexSet.choose all_switches with 
      | Some sw -> sw
      | None -> failwith "Network has no switches" in
    let (_, st_edges) = Net.spanningtree_from spanningtree_edges !topology root in
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
    (* populate the hashtables switch_inps_hash and switch_n_stps_hash *)
    Topology.VertexSet.fold 
      all_switches 
      ~init:()
      ~f:(fun () sw -> populate_hashes sw);
    (* compute spanning tree rules and save them in spanning_tree_rules hashtable *)
    Topology.VertexSet.fold 
      all_switches 
      ~init:()
      ~f:(fun () sw -> 
        Hashtbl.add 
          spanning_tree_rules 
          (Node.id (Topology.vertex_to_label !topology sw)) 
          (switch_rules sw))

  (************************** Shortest Path Routing ***************************)
       
  let prev_hop all_hops (src: Topology.vertex) (curr: Topology.vertex) = 
    try
      let paths = Topology.VertexHash.find_exn all_hops src in
      let prev = Topology.VertexHash.find_exn paths curr in
      Some (Topology.edge_src (Topology.find_edge !topology prev curr))
    with _ -> 
      None

  let rule (mac: dlAddr) (port: Topology.port) : pattern * (action list) = 
    let pat = { match_all with dlDst = Some mac } in 
    let acts = [Output (PhysicalPort(Int32.to_int port))] in 
    (pat,acts)    

  let compute_rules_type_1 (sw_vertex: Topology.vertex) 
      (rule: dlAddr * (switchId * int * pattern * (action list)))
      : (dlAddr * (switchId * int * pattern * (action list))) list = 
    let (mac, (sw, priority, pat, acts)) = rule in 
    let inps = Hashtbl.find switch_inps_hash sw_vertex in 
    Topology.PortSet.fold
      inps
      ~init: []
      ~f: (fun rules in_port ->
          let updated_pat = {pat with inPort = Some (Int32.to_int in_port)} in 
          (mac, (sw, priority, updated_pat, acts))::rules)

  let path_rules all_hops (src: Topology.vertex) (dst: Topology.vertex) 
      : (dlAddr * (switchId * int * pattern * (action list))) list = 
    let mac = Node.mac (Topology.vertex_to_label !topology dst) in 
    let rec loop src curr rules = 
      if src = curr then rules 
      else begin
        match prev_hop all_hops src curr with
        | Some (prev,port) -> 
          let sw = Node.id (Topology.vertex_to_label !topology prev) in 
          let (pat, acts) = rule mac port in 
          let rule_1_list = compute_rules_type_1 prev (mac, (sw, 200, pat, acts)) in 
          let rule_2 = (mac, (sw, 100, pat, (Output (Controller 1024))::acts)) in 
          loop src prev (rule_1_list@(rule_2::rules))
        | None -> rules  
      end 
    in loop src dst []     


  (************************** Routing Between Hosts **************************)

  (* maps host's mac address to (sw, port, v), where sw and port are the switch
    and the port the host is connected to, and v is the vertex representing 
    the host in the topology. Use (sw, port) to check if the host has moved.
    Use v to delete the host's from the topology, or to iterate over hosts 
    vertices when calculating shortest path routing between hosts. *)
  let known_hosts : (dlAddr, switchId * portId * Topology.vertex) Hashtbl.t = 
    Hashtbl.create 50 

  let switch_id_to_vertex : (switchId, Topology.vertex) Hashtbl.t =
    Hashtbl.create 50 	

  let known_host_verticies : Topology.VertexSet.t ref = 
    ref (Topology.VertexSet.empty)

  let _ = Topology.VertexSet.iter 
    all_switches
    ~f: (fun sw  -> let sw_id = Node.id (Topology.vertex_to_label !topology sw) in 
          Hashtbl.add switch_id_to_vertex sw_id sw) 

  (* maps host's mac address to the list of installed rules that route 
    packets TO that host. 
    Each rule in the list is (switch, priority, pattern, action list). *)
  let hosts_installed_rules 
      : (dlAddr, (switchId * int * pattern * (action list)) list) Hashtbl.t = 
    Hashtbl.create 50 

  (* deletes the rules given in [rules_list] from the flow tables of the 
    appropriate switches *)
  let delete_rules_from_switches 
      (rules_list : (switchId * int * pattern * (action list)) list) : unit =
    let delete_rule rule = 
      let (sw, priority, pat, _) = rule in
      send_flow_mod sw 0l (delete_flow_strict priority pat None) in
    List.iter delete_rule rules_list 

  (* installs the rules given in [rules_list] in the flow tables of the 
    appropriate switches *)
  let install_rules_on_switches 
      (rules_list : (switchId * int * pattern * (action list)) list) : unit =
    let install_rule rule = 
      let (sw, priority, pat, acts) = rule in
      send_flow_mod sw 0l (add_flow priority pat acts) in
    List.iter install_rule rules_list

  (* returns (t, v), where t is a new topology with the host with the given 
    [mac] and [ip] address is added to switch [sw] on port [p], and v is the vertex 
    representing this new host in the new topology. 
    the new returned topology should have a new edge added from the host 
    to its switch AND vice versa. *)
  let add_host_to_topology (old_topology : Topology.t) (mac: int64) (ip: int32)
      (sw : switchId) (p: portId) : (Topology.t * Topology.vertex) = 
    let host_node = Node.create "" mac Node.Host ip mac in 
    let host_edge = Link.create 1L Int64.max_int in 
    let (t, v) = Topology.add_vertex old_topology host_node in
    let sw_vertex = Hashtbl.find switch_id_to_vertex sw in
    let sw_port = Int32.of_int(p) in
    let t_with_port = Topology.add_port (Topology.add_port t sw_vertex sw_port) v Int32.zero in
    let (t_with_edge,_) = Topology.add_edge t_with_port sw_vertex sw_port host_edge v Int32.zero in
    let (final_t,_) = Topology.add_edge t_with_edge v Int32.zero host_edge sw_vertex sw_port in
    (final_t,v)
      
  (* returns a new topology with the host given by its vertex representation
    is removed with all the edges relating to that vertex. *)
  let remove_host_from_topology (old_topology : Topology.t) 
      (host_vertex: Topology.vertex) : Topology.t = 
    let neighbor_set = Topology.neighbors old_topology host_vertex in
    let edge_removed_topology = Topology.VertexSet.fold neighbor_set ~init: old_topology
			 ~f:(fun a e ->
			  let edges = Topology.find_all_edges old_topology e host_vertex in
			  Topology.EdgeSet.fold edges ~init: a 
						~f:(fun a e -> Topology.remove_edge a e))
    in
    Topology.remove_vertex edge_removed_topology host_vertex

  (* computes shortest path routing rules from the old_hosts to new_host and 
    vice versa. The elements of the returned list are of the form (mac, rule)
    where mac is the host's mac address for which the associated rule 
    is routing TO *)
  let get_new_routing_rules (old_hosts: Topology.VertexSet.t) 
      (new_host: Topology.vertex)
      : (dlAddr * (switchId * int * pattern * (action list))) list =
    let all_hops =     
      let t = Topology.VertexHash.create () in 
      Topology.VertexSet.iter 
        (Topology.VertexSet.add old_hosts new_host)
        ~f:(fun h -> 
          Topology.VertexHash.add_exn t h 
          (Net.UnitPath.all_shortest_paths !topology h));
      t
    in 
    Topology.VertexSet.fold 
      old_hosts 
      ~init:[]
      ~f:(fun rules host -> 
        (path_rules all_hops host new_host)@(path_rules all_hops new_host host)@rules)

  (** MAIN FUNCTION: This gets called when a packet from a host is sent to 
      the controller. This should do the following: 
      1) extract the mac address and location of the src host of this packet
      2) check if this host is in known_hosts
        a) if no, then do the following in THIS order: 
          - add the host to the topology in the correct location 
            (use add_host_to_topology function);
          - compute the routing rules from the old hosts to this new host and 
            vice versa (use get_new_routing_rules function);
          - installed these new rules in the appropriate switches 
            (use install_rules_on_switches function); 
          - add the new host and its location and vertex to known_hosts;
          - sort the new rules computed earlier by the mac address of the host
            each rule is routing TO; 
          - add the sorted rules to hosts_installed_rules; return.
        b) if yes and host's location didn't change, then just return.
        c) if yes and host's location changed, then do the following in 
          THIS order: 
          - get the installed rules for this host from hosts_installed_rules;
          - remove these rules from the switches affected
            (use delete_rules_from_switches function); 
          - remove host from topology (use remove_host_from_topology function);
          - do the same steps taken in part (2.a); return.
  *)
  let process_packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
    let pk = parse_payload pktIn.input_payload in
    let (host_mac, host_ip, host_sw, host_port) = 
      (pk.Packet.dlSrc, (try nwSrc pk with _ -> 0l), sw, pktIn.port) in
    let add_new_host () = 
      let (new_t, v) = add_host_to_topology !topology host_mac host_ip host_sw host_port in  
      let new_rules = get_new_routing_rules !known_host_verticies v in
      let rules_to_install = List.map snd new_rules in
      install_rules_on_switches rules_to_install;
      Hashtbl.add known_hosts host_mac (host_sw, host_port, v);
      (List.iter(fun (ad,rule) -> 
		     try 
		       let prev_rule = Hashtbl.find hosts_installed_rules ad in
		       Hashtbl.replace hosts_installed_rules ad (rule::prev_rule)
		     with Not_found -> Hashtbl.add hosts_installed_rules ad [rule]) new_rules);
      known_host_verticies := Topology.VertexSet.add !known_host_verticies v;
      topology := new_t
    in
    if (Hashtbl.mem known_hosts host_mac) then
      let (sw_id, pt_id, v) = Hashtbl.find known_hosts host_mac in
      if (sw_id = host_sw) && (pt_id = host_port) then ()
      else 
	let old_rules = Hashtbl.find hosts_installed_rules host_mac in
	delete_rules_from_switches old_rules;
	topology := (remove_host_from_topology !topology v);
	Hashtbl.remove known_hosts host_mac;
        known_host_verticies := Topology.VertexSet.remove !known_host_verticies v;
	add_new_host ()
    else
      add_new_host ()
      

  (****************************** ********* ******************************)
    
  let switch_connected (sw: switchId) (feats : SwitchFeatures.t) : unit =
    try 
      let rules = Hashtbl.find spanning_tree_rules sw in
      List.iter
        (fun (priority, pat, acts) -> 
          send_flow_mod sw 0l (add_flow priority pat acts))
        rules;
      (* Printf.printf "<switch_connected>: switch %d connected. %d\n" 
        (Int64.to_int sw) (List.length rules); *)
      send_flow_mod sw 0l (add_flow 0 match_all [])
    with _ -> 
      (* Printf.printf "<switch_connected>: switch %d connected...\n" 
        (Int64.to_int sw); *)
      send_flow_mod sw 0l (add_flow 0 match_all [])

  let packet_in (sw : switchId) (xid : xid) (pk : packetIn) : unit =
    Printf.printf "<packet_in>: %s\n%!" (packetIn_to_string pk);
    process_packet_in sw xid pk;

end

module Controller = OxStart.Make (GatesApp)

let () = Controller.run ()

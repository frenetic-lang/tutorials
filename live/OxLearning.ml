open OxPlatform
open OpenFlow0x01_Core
open Packet

module MyApplication = struct

  include OxStart.DefaultTutorialHandlers

  let known_hosts : (dlAddr, portId) Hashtbl.t = 
    Hashtbl.create 50 

  let install_rules (sw:switchId) (src_mac:dlAddr) (src_port:portId) (dst_mac:dlAddr) (dst_port:portId) : unit = 
    let src_dst_match = {match_all with dlSrc = Some src_mac; dlDst = Some dst_mac} in 
    let dst_src_match = {match_all with dlSrc = Some dst_mac; dlDst = Some src_mac} in
    send_flow_mod sw 0l (add_flow 10 src_dst_match [Output (PhysicalPort dst_port)]);
    send_flow_mod sw 0l (add_flow 10 dst_src_match [Output (PhysicalPort src_port)])

  let emit_packet (sw:switchId) (pay:payload) (pseudo:pseudoPort) : unit = 
    send_packet_out sw 0l 
      { output_payload = pay;
	port_id = None;
	apply_actions = [Output pseudo] }

  let packet_in (sw:switchId) (xid:xid) (pktIn:packetIn) : unit =
    let pk = parse_payload pktIn.input_payload in
    (* learn source location *)
    Hashtbl.add known_hosts pk.dlSrc pktIn.port;
    (* forward to destination *)
    if Hashtbl.mem known_hosts pk.dlDst then 		
      let dst_port = Hashtbl.find known_hosts pk.dlDst in
      install_rules sw pk.dlDst pktIn.port pk.dlDst dst_port;
      emit_packet sw pktIn.input_payload (PhysicalPort dst_port)
    else
      emit_packet sw pktIn.input_payload AllPorts
end

module Controller = OxStart.Make (MyApplication)

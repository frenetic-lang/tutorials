open Frenetic_OpenFlow0x01
open Frenetic_Ox
module Packet = Frenetic_Packet

module MyApplication = struct
  include DefaultHandlers
  open Platform

  let rec periodic_stats_request (sw : switchId) (interval : float) 
      (xid : xid) (pat : pattern) : unit =
    let callback () =
      Printf.printf "Sending stats request to %Ld\n%!" sw; 
      send_stats_request sw xid
        (AggregateRequest {sr_of_match = pat;
                                 sr_table_id = 0xff;
                                 sr_out_port = None});
      periodic_stats_request sw interval xid pat in
    timeout interval callback
      
  let match_http_response = 
    { match_all with dlTyp = Some 0x800; nwProto = Some 6; tpSrc = Some 80 }

  let match_http_request = 
    { match_all with dlTyp = Some 0x800; nwProto = Some 6; tpDst = Some 80 }

  let match_icmp =
    { match_all with dlTyp = Some 0x800; nwProto = Some 1}

  let switch_connected (sw : switchId) _ : unit =
    Printf.printf "Switch %Ld connected.\n%!" sw;
    periodic_stats_request sw 5.0 10l match_http_request;
    periodic_stats_request sw 5.0 20l match_http_response;
    send_flow_mod sw 0l (add_flow 200 match_icmp []);
    send_flow_mod sw 0l (add_flow 199 match_http_request [Output AllPorts]);
    send_flow_mod sw 0l (add_flow 198 match_http_response [Output AllPorts]);
    send_flow_mod sw 0l (add_flow 197 match_all [Output AllPorts])

  let is_http_request_packet (pk : Packet.packet) : bool = 
    Packet.dlTyp pk = 0x800 &&
    Packet.nwProto pk = 6 &&
    Packet.tpDst pk = 80

  let is_http_response_packet (pk : Packet.packet) : bool = 
    Packet.dlTyp pk = 0x800 &&
    Packet.nwProto pk = 6 &&
    Packet.tpSrc pk = 80

  let is_icmp_packet (pk : Packet.packet) =
    Packet.dlTyp pk = 0x800 && Packet.nwProto pk = 1

  let is_http_packet (pk : Packet.packet) =
    is_http_request_packet pk || is_http_response_packet pk

  let firewall_packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
    let pk = parse_payload pktIn.input_payload in
    send_packet_out sw 0l {
      output_payload = pktIn.input_payload;
      port_id = None;
      apply_actions = if is_icmp_packet pk then [] else [Output AllPorts]
    }

  let num_http_packets = ref 0
    
  let packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
    firewall_packet_in sw xid pktIn;
    if is_http_packet (parse_payload pktIn.input_payload) then
      begin
        num_http_packets := !num_http_packets + 1;
        Printf.printf "Saw %d HTTP packets.\n%!" !num_http_packets
      end

  let num_http_request_packets = ref 0L

  let num_http_response_packets = ref 0L

  let stats_reply (sw : switchId) (xid : xid) (stats : reply) : unit =
    match stats with
      | AggregateFlowRep rep ->
        begin
          if xid = 10l then
            num_http_request_packets := rep.total_packet_count
          else if xid = 20l then
            num_http_response_packets := rep.total_packet_count
        end;
        Printf.printf "Saw %Ld HTTP packets.\n%!"
          (Int64.add !num_http_request_packets !num_http_response_packets)
      | _ -> ()

end

let _ =
  let module C = Make (MyApplication) in
  C.start ();



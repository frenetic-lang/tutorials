open Frenetic_Ox
open Frenetic_OpenFlow0x01

module MyApplication = struct
  include DefaultHandlers
  open Platform  

  (* [FILL] copy over the packet_in function from Firewall.ml
     verbatim, including any helper functions. *)
  let is_icmp_packet (pk : Frenetic_Packet.packet) =
    Frenetic_Packet.dlTyp pk = 0x800 && Frenetic_Packet.nwProto pk = 1

  let firewall_packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
    let pk = parse_payload pktIn.input_payload in
    send_packet_out sw 0l {
      output_payload = pktIn.input_payload;
      port_id = None;
      apply_actions = if is_icmp_packet pk then [] else [Output AllPorts]
    }

  (* [FILL]: Match HTTP packets *)
  let is_http_packet (pk : Frenetic_Packet.packet) =
    Frenetic_Packet.dlTyp pk = 0x800 &&
    Frenetic_Packet.nwProto pk = 6 &&
    (Frenetic_Packet.tpSrc pk = 80 || Frenetic_Packet.tpDst pk = 80)

  let num_http_packets = ref 0
   
  let packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
    firewall_packet_in sw xid pktIn;
    if is_http_packet (parse_payload pktIn.input_payload) then
      begin
        num_http_packets := !num_http_packets + 1;
        Printf.printf "Saw %d HTTP packets.\n%!" !num_http_packets
      end

end

let _ =
  let module C = Make (MyApplication) in
  C.start ();


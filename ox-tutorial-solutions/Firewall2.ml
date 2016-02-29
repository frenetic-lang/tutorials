open Frenetic_OpenFlow0x01
open Frenetic_Ox

module MyApplication = struct
  include DefaultHandlers
  open Platform

  let match_icmp = { match_all with
    dlTyp = Some 0x800;
    nwProto = Some 1
  }

  let switch_connected (sw : switchId) _ : unit =
    Printf.printf "Switch %Ld connected.\n%!" sw;
    send_flow_mod sw 0l (add_flow 200 match_icmp []);
    send_flow_mod sw 0l (add_flow 100 match_all [Output AllPorts])
      
  let is_icmp_packet (pk : Frenetic_Packet.packet) =
    Frenetic_Packet.dlTyp pk = 0x800 && Frenetic_Packet.nwProto pk = 1

  let packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
    let pk = parse_payload pktIn.input_payload in
    Printf.printf "%s\n%!" (packetIn_to_string pktIn);
    send_packet_out sw 0l {
      output_payload = pktIn.input_payload;
      port_id = None;
      apply_actions = if is_icmp_packet pk then [] else [Output AllPorts]
    }

end

let _ =
  let module C = Make (MyApplication) in
  C.start ();


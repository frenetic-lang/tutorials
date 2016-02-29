open Frenetic_Ox
open Frenetic_OpenFlow0x01

module MyApplication = struct
  include DefaultHandlers
  open Platform

  let switch_connected (sw : switchId) feats : unit =
    Printf.printf "Switch %Ld connected.\n%!" sw;
    send_flow_mod sw 1l (add_flow 1 match_all [Output AllPorts])

  (* [FILL] This packet_in function sends all packets out of port 1.
     Modify it to behave like a repeater: send the packet out of all
     ports, except its input port. *)
  let packet_in (sw : switchId) (xid : xid) (pk : packetIn) : unit =
    Printf.printf "%s\n%!" (packetIn_to_string pk);
    send_packet_out sw 0l
      { output_payload = pk.input_payload;
        port_id = None;
        apply_actions = [Output AllPorts] (* <---- this was the edit *)
      }

end

let _ = 
  let module C = Make (MyApplication) in
  C.start ();
  

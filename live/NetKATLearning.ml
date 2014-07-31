open Core.Std
open Async.Std
open Async_NetKAT
open NetKAT_Types
open NetKAT.Std

let known_hosts : (switchId * dlAddr, portId) Hashtbl.t = 
  Hashtbl.Poly.create ()

let learn (sw : switchId) (pt : portId) (pk : packet) : bool =
  match Hashtbl.find known_hosts (sw, pk.dlSrc) with
    | Some pt' when pt = pt' -> 
       false
    | _ -> 
       ignore (Hashtbl.add known_hosts (sw, pk.dlSrc) pt); 
       true

let packet_out (sw : switchId) (pk : packet) : action =
  match Hashtbl.find known_hosts (sw, pk.dlDst) with
    | Some pt -> Output (Physical pt)
    | None -> Output All

let default = 
  <:netkat<port := "learn">>

let learn_pol () = 
  List.fold_right
    (Hashtbl.to_alist known_hosts)
    ~init:default
    ~f:(fun ((sw,addr),pt) pol -> 
	<:netkat< 
          if switch = $sw && ethSrc = $addr then drop else $pol
	>>)

let route_pol () =
  List.fold_right
    (Hashtbl.to_alist known_hosts) 
    ~init:default
    ~f:(fun ((sw,addr),pt) pol -> 
      <:netkat<
        if switch = $sw && ethDst = $addr then port := $pt else $pol
      >>)

let policy () = 
  let l = learn_pol () in 
  let r = route_pol () in 
  <:netkat< $l + $r >>

let handler t w () e = match e with
  | PacketIn(_, switch_id, port_id, payload, _) ->
    let packet = Packet.parse (SDN_Types.payload_bytes payload) in
    let pol = 
      if learn switch_id port_id packet then		
	Some (policy ())
      else
	None in
    let action = packet_out switch_id packet in
    Pipe.write w (switch_id, (payload, Some(port_id), [action])) >>= fun _ ->
    return pol
  | _ -> return None

let firewall = 
  create_static
    <:netkat< if ethType = 0x800 && ipProto = 0x01 then drop else id>>

let learning = create ~pipes:(PipeSet.singleton "learn") (policy ()) handler

let app = seq firewall learning

let _ =
  Async_NetKAT_Controller.start app ();
  never_returns (Scheduler.go ())

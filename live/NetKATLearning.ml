open Core.Std
open Async.Std
open NetKAT_Types
open Async_NetKAT
open NetKAT.Std

let known_hosts : (switchId * dlAddr, portId) Hashtbl.t = Hashtbl.Poly.create ()

let learn (sw : switchId) (pt : portId) (pk : packet) : bool =
  match Hashtbl.find known_hosts (sw, pk.dlSrc) with
    | Some pt' when pt = pt' -> false
    | _ -> Hashtbl.add known_hosts (sw, pk.dlSrc) pt; true

let packet_out (sw : switchId) (pk : packet) : action =
  match Hashtbl.find known_hosts (sw, pk.dlDst) with
    | Some pt -> Output (Physical pt)
    | None -> Output All

let learning = Mod (Location (Pipe "learn"))

let routing () =
  let rec f lst = match lst with
    | [] -> learning
    | ((sw, addr), pt) :: rest ->
      let pol' = f rest in
      <:netkat<
        if switch = $sw && ethDst = $addr then port := $pt else $pol'
      >> in
  f (Hashtbl.to_alist known_hosts)

let handler t w () e = match e with
  | PacketIn(_, switch_id, port_id, payload, _) ->
    let packet = Packet.parse (SDN_Types.payload_bytes payload) in
    let pol = if learn switch_id port_id packet then
       Some (routing ())
    else
       None in
    let action = packet_out switch_id packet in
    Pipe.write w (switch_id, (payload, Some(port_id), [action])) >>= fun _ ->
    return pol
  | _ -> return None

let _ =
  Async_NetKAT_Controller.start (create ~pipes:(PipeSet.singleton "learn") learning handler) ();
  never_returns (Scheduler.go ())

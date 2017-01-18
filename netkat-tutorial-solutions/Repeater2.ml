open Frenetic_NetKAT
open Core.Std
open Async.Std

(* a simple repeater *)
let all_ports : int32 list = [1l; 2l; 3l; 4l]
let%nk drop = {| drop |}

let flood (n : int32) : policy =
  List.fold_left
    all_ports
    ~f: (fun pol m ->
        let%nk flood = {| $pol + port:= $m |} in
        if n = m then pol else flood)
    ~init:drop

let repeater : policy =
  List.fold_right
    all_ports
    ~f: (fun m pol ->
        let p = flood m in
        let%nk repeat = {| if port = $m then $p else $pol |} in
        repeat)
    ~init:drop

let _ =
  let module Controller = Frenetic_NetKAT_Controller.Make (Frenetic_OpenFlow0x01_Plugin) in
  Controller.start 6633;
  Deferred.don't_wait_for (Controller.update repeater);
  never_returns (Scheduler.go ());

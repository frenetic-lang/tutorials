open Frenetic_NetKAT
open Core.Std
open Async.Std

(* a simple repeater *)
let all_ports : int32 list = [1l; 2l; 3l; 4l]

let flood (n : int32) : policy =
  List.fold_left
    all_ports
    ~f: (fun pol m -> if n = m then pol else <:netkat<$pol + port := $m>>)
    ~init: <:netkat<drop>>

let repeater : policy =
  List.fold_right
    all_ports
    ~f: (fun m pol -> let p = flood m in <:netkat<if port = $m then $p else $pol>>)
    ~init: <:netkat<drop>>

let _ =
  let module Controller = Frenetic_NetKAT_Controller.Make in
  Controller.start 6633;
  Controller.update_policy repeater;
  never_returns (Scheduler.go ());

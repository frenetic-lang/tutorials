open Core.Std
open Async.Std

(* a simple repeater *)
let%nk repeater =
  {| if port = 1 then port := 2 + port := 3 + port := 4
     else if port = 2 then port := 1 + port := 3 + port := 4
     else if port = 3 then port := 1 + port := 2 + port := 4
     else if port = 4 then port := 1 + port := 2 + port := 3
     else drop |}

(* let _ = *)
(*   let module Controller = Frenetic_NetKAT_Controller.Make (Frenetic_OpenFlow0x01_Plugin) in *)
(*   Controller.start 6633; *)
(*   Deferred.don't_wait_for (Controller.update repeater); *)
(*   never_returns (Scheduler.go ()); *)


open Core.Std
open Async.Std
open Frenetic_NetKAT
open Repeater

let%nk firewall =
  {| if (ipProto=0x1 and ethTyp=0x800) then drop else $repeater |}

let _ =
  let module Controller = Frenetic_NetKAT_Controller.Make (Frenetic_OpenFlow0x01_Plugin) in
  Controller.start 6633;
  Deferred.don't_wait_for (Controller.update firewall);
  never_returns (Scheduler.go ());


open Core.Std
open Async.Std
open Frenetic_NetKAT
open Repeater 

let firewall : policy =
  <:netkat< if (ipProto=0x1 and ethTyp=0x800) then drop else $repeater>>

let _ =
  let module Controller = Frenetic_NetKAT_Controller.Make in
  Controller.start 6633;
  Controller.update_policy firewall;
  never_returns (Scheduler.go ());


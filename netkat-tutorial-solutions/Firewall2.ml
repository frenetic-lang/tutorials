open Frenetic_NetKAT
open Core.Std
open Async.Std
open Forwarding

let firewall : policy =
  <:netkat<
    if ipProto = 0x01 and ethTyp = 0x800 then drop else (filter ethTyp = 0x800; $forwarding)
  >>

let _ =
  let module Controller = Frenetic_NetKAT_Controller.Make in
  Controller.start 6633;
  Controller.update_policy firewall;
  never_returns (Scheduler.go ());

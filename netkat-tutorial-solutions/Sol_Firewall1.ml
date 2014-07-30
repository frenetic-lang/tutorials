open NetKAT_Types
open Core.Std
open Async.Std
open Async_NetKAT

let firewall : NetKAT_Types.policy = 
  <:netkat<
    if ipProto = 0x01 then drop else $Sol_Repeater.repeater$
  >>

let _ = 
  Async_NetKAT_Controller.start (create_static pol) ();
  never_returns (Scheduler.go ())

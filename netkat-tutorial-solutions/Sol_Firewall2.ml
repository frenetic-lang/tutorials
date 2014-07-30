open NetKAT_Types
open Core.Std
open Async.Std
open Async_NetKAT

let forwarding : NetKAT_Types.policy = 
  <:netkat<
   if ipDst = 10.0.0.1 then port := 1
   else if ipDst = 10.0.0.2 then port := 2
   else if ipDst = 10.0.0.3 then port := 3
   else if ipDst = 10.0.0.4 then port := 4
   else drop
  >>

let firewall : NetKAT_Types.policy = 
  <:netkat<
    if ipProto = 0x01 then drop else $forwarding$
  >>

let _ = 
  Async_NetKAT_Controller.start (create_static pol) ();
  never_returns (Scheduler.go ())

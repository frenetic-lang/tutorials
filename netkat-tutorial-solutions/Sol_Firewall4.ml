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
    if (tcpSrc = 80 || tcpDst = 80) &&
         (ipSrc = 10.0.0.1 && ipDst = 10.0.0.2 ||
          ipSrc = 10.0.0.2 && ipDst = 10.0.0.1) ||
       ipProto = 0x01 &&
        (ipSrc = 10.0.0.3 && ipDst = 10.0.0.4 ||
         ipSrc = 10.0.0.4 && ipDst = 10.0.0.3) then 
      forwarding
    else 
      drop 
  >>

let _ = 
  Async_NetKAT_Controller.start (create_static pol) ();
  never_returns (Scheduler.go ())

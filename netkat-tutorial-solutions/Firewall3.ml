open Frenetic_NetKAT
open Core.Std
open Async.Std
open Forwarding

let%nk firewall =
  {| if ip4Src = 10.0.0.1 then
       (if ip4Dst = 10.0.0.2 and ipProto=0x6 and (tcpSrcPort = 80 or tcpDstPort = 80) then $forwarding
        else drop)
     else if ip4Src = 10.0.0.2 then
       (if ip4Dst = 10.0.0.1 and ipProto=0x6 and (tcpSrcPort = 80 or tcpDstPort = 80) then $forwarding
        else drop)
     else if ip4Src = 10.0.0.3 then
       (if ip4Dst = 10.0.0.4 and ipProto = 0x01 then $forwarding
        else drop)
     else if ip4Src = 10.0.0.4 then
       (if ip4Dst = 10.0.0.3 and ipProto = 0x01 then $forwarding
        else drop)
     else
       drop
  |}

let _ =
  let module Controller = Frenetic_NetKAT_Controller.Make (Frenetic_OpenFlow0x01_Plugin) in
  Controller.start 6633;
  let%nk pol = {| filter ethTyp = 0x800; $firewall |} in
  Deferred.don't_wait_for (Controller.update pol);
  never_returns (Scheduler.go ());

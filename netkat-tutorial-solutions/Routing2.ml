open Frenetic_NetKAT
open Core.Std
open Async.Std
open Firewall


let%nk forwarding =
  {| if switch = 1 then
       if port = 1 then port := 2
       else if port = 2 then port := 1
       else drop
     else if switch = 2 then
       if ethDst = 1 then port := 1
       else if ethDst = 2 then port := 2
       else port := 3
     else if switch = 3 then
       if ethDst = 3 then port := 1
       else if ethDst = 4 then port := 2
       else port := 3
     else
       drop
  |}
 
let _ =
  let module Controller = Frenetic_NetKAT_Controller.Make (Frenetic_OpenFlow0x01_Plugin) in
  Controller.start 6633;
  let%nk pol = {| $firewall; $forwarding |} in
  Deferred.don't_wait_for (Controller.update pol);
  never_returns (Scheduler.go ());

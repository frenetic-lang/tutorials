open NetKAT_Types
open Core.Std
open Async.Std
open Async_NetKAT

let connect m n = 
  <:netkat<
    filter (port = $m$); port := $n$ + 
    filter (port = $n$); port := $m$
  >>

let pol = connect 1l 2l

let _ = 
  Async_NetKAT_Controller.start (create_static pol) ();
  never_returns (Scheduler.go ())

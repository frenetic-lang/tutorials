open Core.Std
open Async.Std
open NetKAT_Types
open Async_NetKAT

let pol = Seq (Filter (Test (Location (Physical 1l))), Mod (Location (Physical 2l)))

let my_app = create_static pol

let _ = Async_NetKAT_Controller.start my_app ()
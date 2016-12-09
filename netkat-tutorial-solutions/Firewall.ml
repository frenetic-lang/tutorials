open Core.Std
open Async.Std
open Frenetic_NetKAT

let%nk firewall =
  {| if (ipProto=0x1 and ethTyp=0x800) then drop else id |}

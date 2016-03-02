open Core.Std
open Async.Std
open Frenetic_NetKAT

let firewall : policy =
  <:netkat< if (ipProto=0x1 and ethTyp=0x800) then drop else id>>


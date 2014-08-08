open NetKAT.Std
open Forwarding

let firewall : policy =
  <:netkat<
    if ipProto = 0x01 && ethType = 0x800 then drop else (filter ethType = 0x800; $forwarding)
  >>

let _ = run_static firewall

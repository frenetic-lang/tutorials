open NetKAT.Std
open RepeaterPolicy

let firewall : policy =
  <:netkat<
    if ipProto = 0x01 && ethType = 0x800 then drop else $pol
  >>

let _ = run_static firewall

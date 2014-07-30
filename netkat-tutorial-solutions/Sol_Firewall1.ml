open NetKAT.Std

let firewall : policy =
  <:netkat<
    if ipProto = 0x01 then drop else $Sol_Repeater.pol$
  >>

let _ = run_static firewall
open NetKAT.Std

let forwarding : policy =
  <:netkat<
   if ip4Dst = 10.0.0.1 then port := 1
   else if ip4Dst = 10.0.0.2 then port := 2
   else if ip4Dst = 10.0.0.3 then port := 3
   else if ip4Dst = 10.0.0.4 then port := 4
   else drop
  >>

let firewall : policy =
  <:netkat<
    if ipProto = 0x01 && ethType = 0x800 then drop else $forwarding
  >>

let _ = run_static firewall

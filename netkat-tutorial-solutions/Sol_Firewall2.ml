open NetKAT.Std

(*
let forwarding : policy =
  <:netkat<
   if ip4Dst = 10.0.0.1 then port := 1l
   else if ip4Dst = 10.0.0.2 then port := 2l
   else if ip4Dst = 10.0.0.3 then port := 3l
   else if ip4Dst = 10.0.0.4 then port := 4l
   else drop
  >>
*)
let firewall : policy =
  <:netkat<
    if ipProto = 0x01 then drop else $forwarding
  >>

let _ = run_static firewall
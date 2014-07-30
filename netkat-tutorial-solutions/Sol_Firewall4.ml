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
    if (tcpSrcPort = 80 || tcpDstPort = 80) &&
       (ip4Src = 10.0.0.1 && ip4Dst = 10.0.0.2 ||
        ip4Src = 10.0.0.2 && ip4Dst = 10.0.0.1) ||
       ipProto = 0x01 &&
        (ip4Src = 10.0.0.3 && ip4Dst = 10.0.0.4 ||
         ip4Src = 10.0.0.4 && ip4Dst = 10.0.0.3) then
      $forwarding
    else
      drop
  >>

let _ = run_static firewall
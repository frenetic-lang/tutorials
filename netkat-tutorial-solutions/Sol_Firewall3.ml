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
    if ip4Src = 10.0.0.1 then
      (if ip4Dst = 10.0.0.2 && (tcpSrcPort = 80 || tcpDstPort = 80) then $forwarding
       else drop)
    else if ip4Src = 10.0.0.2 then
      (if ip4Dst = 10.0.0.1 && (tcpSrcPort = 80 || tcpDstPort = 80) then $forwarding
       else drop)
    else if ip4Src = 10.0.0.3 then
      (if ip4Dst = 10.0.0.4 && ipProto = 0x01 then $forwarding
       else drop)
    else if ip4Src = 10.0.0.4 then
      (if ip4Dst = 10.0.0.3 && ipProto = 0x01 then $forwarding
       else drop)
    else
      drop
  >>

let _ = run_static firewall
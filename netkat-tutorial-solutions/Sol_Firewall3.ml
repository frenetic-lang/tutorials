open NetKAT.Std
open Forwarding

let firewall : policy =
  <:netkat<
    if ip4Src = 10.0.0.1 then
      (if ip4Dst = 10.0.0.2 && (tcpSrcPort = 80 || tcpDstPort = 80) then $forwarding
       else drop)
    else if ip4Src = 10.0.0.2 then
      (if ip4Dst = 10.0.0.1 && (tcpSrcPort = 80 || tcpDstPort = 80) then $forwarding
       else drop)
    else if ip4Src = 10.0.0.3 then
      (if ip4Dst = 10.0.0.4 && ipProto = 0x01 && ethType = 0x800 then $forwarding
       else drop)
    else if ip4Src = 10.0.0.4 then
      (if ip4Dst = 10.0.0.3 && ipProto = 0x01 && ethType = 0x800 then $forwarding
       else drop)
    else
      drop
  >>

let _ = run_static <:netkat< filter ethType = 0x800; $firewall >>

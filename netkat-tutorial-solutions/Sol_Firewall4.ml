open NetKAT.Std
open Forwarding

let firewall : policy =
  <:netkat<
    if ((tcpSrcPort = 80 || tcpDstPort = 80) &&
       (ip4Src = 10.0.0.1 && ip4Dst = 10.0.0.2 || 
        ip4Src = 10.0.0.2 && ip4Dst = 10.0.0.1)) || 
       ((ipProto = 0x01 && ethType = 0x800) && 
       (ip4Src = 10.0.0.3 && ip4Dst = 10.0.0.4 ||
        ip4Src = 10.0.0.4 && ip4Dst = 10.0.0.3)) then
        (filter ethType = 0x800; $forwarding)
    else
      drop
  >>

let _ = run_static firewall

open Frenetic_NetKAT

let forwarding : policy =
  <:netkat<
   if ip4Dst = 10.0.0.1 then port := 1
   else if ip4Dst = 10.0.0.2 then port := 2
   else if ip4Dst = 10.0.0.3 then port := 3
   else if ip4Dst = 10.0.0.4 then port := 4
   else drop
  >>

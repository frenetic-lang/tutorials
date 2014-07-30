open NetKAT.Std

(* From NetKATRepeater.ml *)
let connect (m : Int32.t) (n : Int32.t) =
  <:netkat<
    filter (port = $m); port := $n +
    filter (port = $n); port := $m
  >>

let forwarding = connect 1l 2l

let firewall : policy =
  <:netkat<
    if ipProto = 0x01 then drop else $forwarding
  >>

let _ = run_static firewall
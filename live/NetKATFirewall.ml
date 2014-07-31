open NetKAT.Std

let repeater : policy =
  <:netkat<
    if port = 1 then port := 2 + port := 3 + port := 4
    else if port = 2 then port := 1 + port := 3 + port := 4
    else if port = 3 then port := 1 + port := 2 + port := 4
    else if port = 4 then port := 1 + port := 2 + port := 3
    else drop
  >>

let firewall : policy =
  <:netkat<
    if ethType = 0x800 && ipProto = 0x01 then drop else $repeater
  >>

let _ = run_static firewall

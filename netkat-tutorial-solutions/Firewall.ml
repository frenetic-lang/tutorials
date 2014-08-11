open NetKAT.Std

let firewall : policy =
  <:netkat<
    if ipProto = 0x01 && ethType = 0x800 then drop else id
  >>

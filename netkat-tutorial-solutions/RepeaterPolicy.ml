open NetKAT.Std

let connect m n =
  <:netkat<
    filter (port = $m); port := $n +
    filter (port = $n); port := $m
  >>

let pol = connect 1l 2l

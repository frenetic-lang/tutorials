open NetKAT.Std

let connect (m : Int32.t) (n : Int32.t) =
  <:netkat<
    filter (port = $m); port := $n +
    filter (port = $n); port := $m
  >>

let pol = connect 1l 2l

let _ = run_static pol
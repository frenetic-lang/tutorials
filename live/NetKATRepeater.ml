open NetKAT.Std

let repeater : policy =
  <:netkat<
    if port = 1 then port := 2 + port := 3 + port := 4
    else if port = 2 then port := 1 + port := 3 + port := 4
    else if port = 3 then port := 1 + port := 2 + port := 4
    else if port = 4 then port := 1 + port := 2 + port := 3
    else drop
  >>

let _ = run_static repeater

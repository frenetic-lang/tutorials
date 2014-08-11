open NetKAT.Std

let forwarding : policy =
  <:netkat<
    if switch = 1 then
      if port = 1 then port := 2
      else if port = 2 then port := 1
      else drop
    else if switch = 2 then
      if ethDst = 1 then port := 1
      else if ethDst = 2 then port := 2
  	  else port := 3
    else if switch = 3 then
      if ethDst = 3 then port := 1
      else if ethDst = 4 then port := 2
      else port := 3
    else
      drop
   >>
    
let _ = run_static forwarding

---
layout: main
title: Conclusion
---

In this tutorial, you learned to program software-defined networks
using Ox and NetKAT:

  - *Ox* is our low-level platform for implementing OpenFlow controllers,
developed in OCaml.  You saw how to use it to analyze packets on
an SDN controller, install rules in the data plane and monitor traffic
statistics.

  - *NetKAT* is a high-level domain-specific language for specifying SDN
policies.  In just a few, simple lines of code, you could specify forwarding
policy and queries for multi-switch networks in a modular, compositional
fashion.  The Frenetic compiler (built using Ox, of course) compiled your
high-level programs in to flow tables that are installed automatically in
the data plane.

Still, there's a lot more to the Frenetic environment than what you
have seen in this tutorial.  One way to get started finding out more is
to dig further in to the code.  For instance, you might look at
[Frenetic_NetKAT](http://frenetic-lang.github.io/frenetic/Frenetic_NetKAT.html), 
which is the primary library that implements NetKAT.  Take a look at the internal syntax of Frenetic in the 
[Compiler Module](http://frenetic-lang.github.io/frenetic/Frenetic_NetKAT_Compiler.html) 
and then move on to other libraries, including those that implement 
[Mac Learning](https://github.com/frenetic-lang/frenetic/blob/master/examples/Learning_Switch.ml).  The 
latter components will introduce you to the basics of
how to construct your own dynamic policies in the Frenetic programming
environment using NetCoreLib combined with OCaml's 
[Async library](https://realworldocaml.org/v1/en/html/concurrent-programming-with-async.html).

Have fun!

--------------------

![Frenetic.][frenetic_logo]

[frenetic_logo]: ../images/frenetic-logo.png "Frenetic"

---
layout: main
title: NetKAT Repeater
---

So far, we've seen how to implement OpenFlow controllers using the Ox
platform. Most of the controllers we've built follow a simple,
two-step recipe:

* Write a `packet_in` handler that implements the desired
  packet-processing policy.

* Use `flow__mod` and `stats_request` messages to use the hardware
  flow tables and counters available on switches to implement the same
  policy efficiently.

In the next few chapters, we will explore a different approach:
express policies using a high-level, domain-specific programming
language, and let a compiler and run-time system handle the details
related to configuring hardware flow tables on switches (as well as
sending requests for statistics, accumulating replies, etc.)

The templates for this part of the tutorial are in the
`netkat-tutorial-workspace` directory, and the solutions are in
`netkat-tutorial-solutions`.

~~~
$ cd tutorials/netkat-tutorial-solutions
~~~

### Example 1: A Repeater (Redux)

In the [OxRepeater](OxRepeater) chapter, we wrote an efficient
repeater that installs forwarding rules in the switch flow table.
Recall that a repeater simply forwards incoming packets out all other
ports. To simplify the example, suppose that the topology consists of
a single switch with four ports, numbered 1 through 4:

![Repeater](../images/repeater.png)

The following program implements a repeater in NetKAT:

~~~ ocaml
open Core.Std
open Async.Std

(* a simple repeater *)
let repeater : NetKAT_Types.policy =
  <:netkat<
    if port = 1l then port := 2l + port := 3l + port := 4l
    else if port = 2l then port := 1l + port := 3l + port := 4l
    else if port = 3l then port := 1l + port := 2l + port := 4l
    else if port = 4l then port := 1l + port := 2l + port := 3l
    else drop
  >>

let _ =
  Async_NetKAT_Controller.start (create_static repeater) ();
  never_returns (Scheduler.go ())
~~~

This main part of this code uses a Camlp4 quotation,
<code><:netkat<... >></code> to switch into NetKAT syntax. The
embedded NetKAT program uses a cascade of nested conditionals
(<code>if ... then ... else ...</code>) to match packets on each port
(<code>port = 1l</code>) and forward them out on all other ports
(<code>port := 2l + port := 3l + port := 4l</code>) except the one the
packet came in on. The last two lines of code are boilerplate. They
start a controller that configures the switch with a static NetKAT
policy, and also start the scheduler for the Async concurrency
library.

#### Run the Example

To run the repeater, type the code above into a file
<code>Repeater.ml</code> within the
<code>netkat-tutorial-workspace</code> directory. Then compile and
start the repeater controller using the following commands.
~~~
$ ../freneticbuild Repeater.native
$ ./Repeater.native
~~~
Next, in a separate terminal, start up mininet.
~~~
$ sudo mn --controller=remote --topology=single,4 --mac --arp
~~~

#### Test the Example

At the mininet prompt, test your repeater program by pinging <code>h2</code> from <code>h1</code>:
~~~
mininet> h1 ping -c 1 h2
~~~
You should see a trace like this one:
~~~
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
64 bytes from 10.0.0.2: icmp_req=1 ttl=64 time=0.216 ms

--- 10.0.0.2 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.216/0.216/0.216/0.000 ms
~~~
Try pinging <code>h1</code> from <code>h2</code> as well.

### Example 2: Using Anti-Quotation

In many programs it is useful to escape from a quotation back into
OCaml. We can do this using Camlp4 anti-quotations,
<code>$...$</code>. As an example, here is an equivalent version of
the repeater written using anti-quotation:

~~~
(* a simple repeater *)
let all_ports : int32 list = [1l; 2l; 3l; 4l]

let flood (n:int32) : NetKAT_Types.policy =
  List.fold_left
    (fun pol m -> if n = m then pol else <:netkat<$pol$ + port := $m$>>)
    <:netkat<drop>> all_ports

let repeater : NetKAT_Types.policy =
  List.fold_right
    (fun m pol -> <:netkat<if port = $m$ then $flood m$ else $pol$>>)
    all_ports <:netkat<drop>>
>>
~~~

## Next chapter: [Firewall Redux][Ch7]

[Ch7]: 07-NCFirewall

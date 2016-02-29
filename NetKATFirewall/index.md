---
layout: main
title: Firewall with NetKAT
---

In an [earlier chapter](OxFirewall), we wrote a firewall that blocks
ICMP traffic using OpenFlow and Ox. Even though this policy is
extremely simple, the implementation was somewhat involved, as we had
to both write a `packet_in` handler and also use `flow_mod` messages
to configure the switch.

## Exercise 1: Naive Firewall

We can implement the same policy in NetKAT as follows:

~~~ ocaml
open Frenetic_NetKAT
open Core.Std
open Async.Std
open Repeater

let firewall : policy =
  <:netkat<
    if ipProto = 0x01 && ethType = 0x800 then drop else $pol
  >>

let _ =
  let module Controller = Frenetic_NetKAT_Controller.Make in
  Controller.start 6633;
  Controller.update_policy repeater;
  never_returns (Scheduler.go ());

~~~

There are two things to note about this program. First, rather than
having to write separate `packet_in` and `switch_connected` handlers,
the NetKAT program consists of a simple declarative specification of
the desired packet-processing functionality. The compiler and run-time
system take care of generating the handlers and low-level forwarding
rules needed to implement it. Second, the NetKAT program is modular:
we use a conditional to wrap the repeater policy from the last
chapter. The ability to combine policies in a compositional way is one
of the key benefits of NetKAT's language-based approach.

Type this policy into a file `Firewall.ml` in the
`netkat-tutorial-solutions` directory.

#### Testing

To test your code, compile the firewall and start the controller in
one terminal,

~~~
$ ./netkat-build Firewall
$ ./Firewall.d.byte
~~~

and Mininet in another:

~~~
$ sudo mn --controller=remote --topo=single,4 --mac --arp
~~~

Using Mininet, check that pinging fails between all hosts:

~~~
mininet> h1 ping h2

--- 10.0.0.2 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1008ms
~~~

~~~
mininet> h2 ping h1

--- 10.0.0.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 999ms
~~~

## Exercise 2: Basic Firewall

To gain further experience with NetKAT, let's implement a more
sophisticated firewall policy that uses point-to-forwarding rather
than naive flooding. As we saw in the last chapter, NetKAT supports
conditional expressions, so we can implement the forwarding policy by
simply matching on destination IP addresses and then forwarding out
the corresponding port. Recall that the topology has a single switch
with four hosts.

![Repeater](../images/repeater.png)

The hosts have IP addresses 10.0.0.1 through 10.0.0.4 and are
connected to ports 1 through 4 respetively.

~~~
open Frenetic_NetKAT
open Core.Std
open Async.Std

let forwarding : policy =
  <:netkat<
    if ip4Dst = 10.0.0.1 then port := 1
    else if (* destination is 10.0.0.2, forward out port 2, etc. *)
      ...
    else drop
  >>
~~~

Type this policy into a file `Forwarding.ml` in the
`netkat-tutorial-solutions` directory.

We want our firewall policy to wrap this forwarding policy:

~~~
open Frenetic_NetKAT
open Core.Std
open Async.Std
open Forwarding

let firewall : policy =
  <:netkat<
    if (* FILL condition for ICMP packets *) then drop else (filter ethType = 0x800; $forwarding)
  >>

let _ =
  let module Controller = Frenetic_NetKAT_Controller.Make in
  Controller.start 6633;
  Controller.update_policy repeater;
  never_returns (Scheduler.go ());

~~~

Save this policy into a file `Firewall2.ml` in the
`netkat-tutorial-solutions` directory.

### Testing

- Build and launch the controller:

~~~ shell
$ ./netkat-build Firewall2
$ ./Firewall2.d.byte
~~~

- Start Mininet using the same parameters you've used before:

~~~
$ sudo mn --controller=remote --topo=single,4 --mac --arp
~~~

- Test that pings fail within Mininet:

~~~
mininet> h1 ping -c 1 h2
mininet> h2 ping -c 1 h1
~~~  
These commands should fail, printing `100.0% packet loss`.

- Although ICMP is blocked, other traffic, such as Web traffic should
  be unaffected. To ensure that this is the case, try to run a Web server
  on one host and a client on another.

  * In Mininet, start new terminals for `h1` and `h2`:

~~~
mininet> xterm h1 h2
~~~

  * In the terminal for `h1` start a local "fortune server" (a server
    that returns insightful fortunes to those who query it):

~~~
# while true; do fortune | nc -l 80; done
~~~

  * In the terminal for `h2` fetch a fortune from `h1`:

~~~
# curl 10.0.0.1:80
~~~

   This command should succeed.

## Exercise 3: Advanced Firewall

Now that basic connectivity works, let's extend the example further to
enforce a more interesting access control policy:

|--------------+----------+-----------+----------+----------|
|              | 10.0.0.1 | 10.0.0.2  | 10.0.0.3 | 10.0.0.4 |
|:------------:|:--------:|:---------:|:--------:|:--------:|
| **10.0.0.1** | DENY     | HTTP      | DENY     | DENY     | 
| **10.0.0.2** | HTTP     | DENY      | DENY     | DENY     | 
| **10.0.0.3** | DENY     | DENY      | DENY     | ICMP     | 
| **10.0.0.4** | DENY     | DENY      | ICMP     | DENY     | 
|--------------+----------+-----------+----------+----------|

Each cell in this table has a list of allowed protocols for
communication between the source host in each row and destination host
in each column. For example, the cell indexed by row 10.0.0.1 and
column 10.0.0.2 contains HTTP, indicating that (only) HTTP (port 80)
traffic is allowed from host `10.0.0.1` to `10.0.0.2`. To realize this
policy in NetKAT, you need to allow packets from the first host to
port 80 on second *and* from port 80 on the second back to the first:

~~~ ocaml
open Frenetic_NetKAT
open Core.Std
open Async.Std
open Forwarding

let firewall : policy =
  <:netkat<
   if (ip4Src = 10.0.0.1 && ip4Dst = 10.0.0.2 && tcpSrcPort = 80 ||
       ip4Src = 10.0.0.2 && ip4Dst = 10.0.0.1 && tcpDstPort = 80)
   then $forwarding
   else drop
~~~

Then you should modify the firewall to only allow ICMP traffic between
hosts `10.0.0.3` and `10.0.0.4`.

Type this policy into a file `Firewall3.ml` in the
`netkat-tutorial-solutions` directory and test it in Mininet. Note
that due to the access control policy, it probably makes sense to test
a few points of the access control policy. For example, if you run
_fortune_ on port 80 on `h1`,

~~~
## Run on h1's terminal
$ while true; do fortune | nc -l 80; done
~~~

the command `curl 10.0.0.1:80` should succeed from `h2`, but fail from
`h3`. Similarly, pinging `h3` should succeed from `h4`, but fail from
`h1`.

## Exercise 4: Compact Firewall

Above, we expressed the firewall policy is to enumerate each allowed
flow using conditionals. However, using NetKAT's predicates (`p1 &&
p2`, `p1 || p2`, and `!p`) is is often possible to write a more
compact and legible policy. Revise your advanced firewall this policy,
putting the result in a file `Firewall4.ml` in the
`netkat-tutorial-solutions` directory and test it in Mininet.

{% include api.md %}

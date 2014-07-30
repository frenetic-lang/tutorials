---
layout: main
title: Firewall with NetKAT
---

In an [earlier chapter](OxFirewall), we wrote a firewall that blocks ICMP
traffic using OpenFlow and Ox. Even though this policy is extremely
simple, the implementation was somewhat involved, as we had to both
write a `packet_in` handler and also use `flow_mod` messages to
configure the switch.

#Exercise 1: Naive Firewall

We can implement the same policy in NetKAT as follows:

~~~ ocaml
open NetKAT.Std

let firewall : policy =
  <:netkat<
    if ipProto = 0x01 then drop else $Repeater.repeater
  >>

let _ = run_static firewall
~~~

There are two things to note about this program. First, rather than
having to write separate `packet_in` and `switch_connected` handlers,
the NetKAT program consists of a simple declarative specification of
the desired packet-processing functionality. The compiler and run-time
system take care of generating the handlers and low-level forwarding
rules needed to implement it. Second, the NetKAT program is modular:
we use a conditional to wrap the `repeater` policy from the last
chapter. The ability to combine policies in a compositional way is one
of the key benefits of NetKAT's language-based approach to network
programming.

Type this policy into a file `Firewall.ml` in the
`netkat-tutorial-workspace` directory.

#### Testing

To test your code, compile the firewall and start the controller in
one terminal,
~~~
$ netkat-build Firewall.native
$ ./Firewall.native
~~~
and Mininet in another:
~~~
$ sudo mn --controller=remote --topo=single,4 --mac --arp
~~~
Using Mininet, check that you can ping between all hosts:
~~~
mininet> pingall
~~~

### Exercise 1: Basic Firewall

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
let forwarding : policy =
  <:netkat<
    if ip4Dst = 10.0.0.1 then port := 1
    else if (* destination is 10.0.0.2, forward out port 2, etc. *)
      ...
    else drop
  >>
~~~

Type this policy into a file `Firewall2.ml` in the
`netkat-tutorial-workspace` directory.

### Testing

- Build and launch the controller:

  ~~~ shell
  $ netkat-build Firewall2.native
  $ ./Firewall2.native
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

<table>
<tr>
  <th style="visibility: hidden"></th>
  <th style="visibility: hidden"></th>
  <th colspan="4">Dst IP Address</th>
</tr>
<tr>
  <th style="visibility: hidden"></th>
  <th style="visibility: hidden"></th>
  <th>10.0.0.1</th>
  <th>10.0.0.2</th>
  <th>10.0.0.3</th>
  <th>10.0.0.4</th>
</tr>
<tr>
  <th rowspan="5" style="-webkit-transform:rotate(270deg)" >
    Src IP Address<br>address
  </th>
  <th>10.0.0.1</th>
  <td>Deny All</td>
  <td>HTTP</td>
  <td>Deny All</td>
  <td>Deny All</td>
</tr>
<tr>
  <th>10.0.0.2</th>
  <td>HTTP</td>
  <td>Deny All</td>
  <td>Deny All</td>
  <td>Deny All</td>
</tr>
<tr>
  <th>10.0.0.3</th>
  <td>Deny All</td>
  <td>Deny All</td>
  <td>Deny All</td>
  <td>ICMP</td>
</tr>
<tr>
  <th>10.0.0.4</th>
  <td>Deny All</td>
  <td>Deny All</td>
  <td>ICMP</td>
  <td>Deny All</td><br>
</tr>
</table>

Each cell in this table has a list of allowed protocols for
connections between the hosts in rows and columns. For example, the
cell

<table>
<tr>
  <th></th>
  <th>10.0.0.1</th>
</tr>
<tr>
  <th>10.0.0.2</th>
  <td>HTTP</td>
</tr>
</table>

indicates that (only) HTTP connections (port 80) are allowed between
hotss `10.0.0.2` and `10.0.0.1`. To realize this policy in NetKAT, you
need to allow packets from the first host to port 80 on second  *and*
from port 80 on the second back to the first:

~~~
let firewall : policy =
  <:netkat<
   if (ip4Src = 10.0.0.2 && ip4Dst = 10.0.0.1 && tcpDstPort = 80) ||
      (ip4Src = 10.0.0.1 && ip4Dst = 10.0.0.2 && tcpSrcPort = 80)
   then
     $forwarding
   else
     drop
~~~

Type this policy into a file `Firewall3.ml` in the
`netkat-tutorial-workspace` directory and test it in Mininet. Note
that due to the access control policy, it probably makes sense to test
a few points of the access control policy. For example, if you run
_fortune_ on port 80 on `h1`,

~~~
## Run on h1's terminal
$ while true; do fortune | nc -l 80; done
~~~

running `curl 10.0.0.1:80` should succeed from `h2`, but fail from `h3`.

Similarly, pinging `h3` should succeed from `h4`, but fail from `h1`.

#### Exercise 4: Compact Firewall

One way to express a firewall policy is to enumerate each allowed flow
using conditionals. However, using NetKAT's predicates (`p1 && p2`,
`p1 || p2`, and `!p`) is is often possible to write a more compact and
legible policy. Revise your advanced firewall this policy, putting the
result in a file `Firewall4.ml` in the `netkat-tutorial-workspace`
directory and test it in Mininet.

{% include api.md %}

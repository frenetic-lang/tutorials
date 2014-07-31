---
layout: main
title: Repeater with Ox
---

### OpenFlow Introduction

In software-defined network, all switches connect to a logically
centralized controller. The controller maintains a global view of the
network and programs the switches to implement a unified, network-wide
policy. The controller and switches communicate using a standard
protocol such as OpenFlow.

A switch processes packets using a _flow table_, which is a list of
prioritized rules. Each rule has several components:

- A _pattern_ that matches packet header fields,

- A _list of actions_ that is applied to matching packets,

- A _priority_ that is used to disambiguate between rules with
  overlapping patterns, and

- A pair of _counters_ that record the number and total size of all
  matching packets.

For example, consider the following flow table:

|----------+---------+--------------------+---------+-------|
| Priority | Pattern | Actions            | Packets | Bytes |
|:--------:|:-------:|:-------------------|:-------:|:-----:|
| 50       | ICMP    |                    | 2       | 148   |
| 40       | TCP     | Output 2, Output 5 | 5       | 1230  |
| 30       | UDP     | Controller         | 3       | 284   |
| 20       | ICMP    | Output 2           | 0       | 0     |
|----------+---------+--------------------+---------+-------|

Read from top to bottom, these rules can be understood as follows:

* The first and highest priority rule drops all Internet Control
  Message Protocol (ICMP) packets (because it has an empty action
  list).

* The next rule outputs Transmission Control Protocol (TCP) packets
  out of ports 2 and 5 on the switch&mdash;i.e., it creates two copies
  of each matching packet and forward them out those ports.

* The next rule sends User Datagram Protocol (UDP) packets to the
  special controller port (see below). Because the controller runs an
  arbitrary program (an OCaml program, in Ox), we can implement
  essentially any packet-processing function we like.

* The final rule outputs ICMP packets on port 2. However, since this
  rule is fully shadowed by the first rule, it is never used.

Note that, in principle, we _could_ implement any function we like
using the controller&mdash;e.g., deep packet inspection. But
processing packets on the controller is typically orders of manitude
slower compared to processing packets on switches. Hence, programmers
typically install forwarding rules that handle the vast majority of
all traffic, and make limited use of the `Controller` action.

## Warmup: Programming a Repeater

![Repeater](../images/repeater.png)

As a first exercise, let us build a simple repeater. A repeater is a
network element that forwards all packets received as input on all of
its other ports. We will build our repeater in two steps:

- First, we will leave the flow table empty, so all packets are
  diverted to the controller for processing. At the controller, we
  will write a packet-processing function that implements the functionality we want.

- Then, after completing and testing the packet-processing function
  implemented using the controller, we will install rules to the flow
  table of the switch that implement the same function.

This two-step exercise may seem contrived for a simple repeater. But,
we will quickly escalate to programs where the interaction between
controller and switches gets tricky. For these programs, the first
naive implementation will serve as a reference implementation to help
determine if the more efficient implementation is correct. We will
also see that there are sometimes corner cases where it is necessary
to process packets on both the controller and switches. So, in
practice, one typically does need both implementations.

### Exercise 1: A Naive Repeater

**[Solution](https://github.com/frenetic-lang/tutorials/blob/master/ox-tutorial-solutions/Repeater1.ml)**

In this part, you will write a repeater that processes all packets at
the controller. By default, when an OpenFlow switch does not contain
any rules, it diverts all packets to the controller in a `packet_in`
message. Therefore, this repeater only needs to provide a `packet_in`
handler. We have provided some starter code in a template below.

Fill in the body of this function and save it in a file called
`Repeater.ml`.

~~~ ocaml
open OxPlatform
open OpenFlow0x01_Core

module MyApplication = struct
  include OxStart.DefaultTutorialHandlers

  let packet_in (sw : switchId) (xid : xid) (pk : packetIn) : unit =
     ...

end

module Controller = OxStart.Make (MyApplication)
~~~

You will need to use the `send_packet_out` command, which takes a list
of actions (`apply_actions`) to apply to the packet:

~~~ ocaml
let packet_in (sw : switchId) (xid : xid) (pk : packetIn) : unit =
  Printf.printf "%s\n%!" (packetIn_to_string pk);
  send_packet_out sw 0l {
    output_payload = pk.input_payload;
    port_id = None;
    apply_actions = ... (* [FILL] *)
  }
~~~

The list of actions we want is one that will send the packet out all
ports excluding the input port. This is easier than it may sound,
because OpenFlow includes a single primitive that provides exactly
this functionality. Find the right action in the Ox manual (it is in
the [OpenFlow_Core] module) and fill it in.

<h4 id="compiling">Compiling your Controller</h4>

To build your controller, run the following command:

~~~
$ ox-build Repeater.d.byte
~~~

Assuming compilation succeeds, you will see output like to this:

~~~
ocamlbuild -use-ocamlfind Repeater.d.byte
Finished, 4 targets (4 cached) in 00:00:00.
~~~

#### Testing your Controller

You can test your controller using Mininet, which is included in the
tutorial VM. Mininet runs a virtual network on your computer,
isolating each virtual host in a Linux container. To test the
repeater, use Mininet to create a network with one switch and three
hosts and have them ping each other:

- Start Mininet in a separate terminal window:

      $ sudo mn --controller=remote --topo=single,4 --mac --arp

  A brief explanation of the flags:

  * `topo=single,4` creates a network with one switch and four hosts.

  * `--mac` sets the hosts' mac addresses to 1, 2, 3, and 4 (instead
    of random numbers) which makes debugging much easier.

  * `--arp` statically configures the ARP tables on all hosts, so we
    don't have to deal with ARP broadcast traffic.

  * `--controller=remote` directs the switches to connect to our
    controller (instead of a default, built-in controller).

- After Mininet launches, it will print the network topology and then
  drop you into the Mininet command-line interface:

      mininet>

- Start your controller back in the original terminal:

~~~
$ ./Repeater.d.byte
~~~

  It should print `[Ox] Controller launching...` and then you should
  see switch 1 connecting to the controller: `[Ox] switch 1
  connected`.

- From the Mininet prompt, ping from one host to another:

~~~
mininet> h1 ping h2
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
64 bytes from 10.0.0.2: icmp_req=1 ttl=64 time=1.97 ms
64 bytes from 10.0.0.2: icmp_req=2 ttl=64 time=1.92 ms
64 bytes from 10.0.0.2: icmp_req=3 ttl=64 time=2.46 ms
64 bytes from 10.0.0.2: icmp_req=4 ttl=64 time=2.21 ms
^C
--- 10.0.0.2 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3006ms
rtt min/avg/max/mdev = 1.926/2.144/2.461/0.213 ms
~~~

~~~
mininet> h2 ping h1
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
64 bytes from 10.0.0.1: icmp_req=1 ttl=64 time=1.98 ms
64 bytes from 10.0.0.1: icmp_req=2 ttl=64 time=2.45 ms
64 bytes from 10.0.0.1: icmp_req=3 ttl=64 time=2.40 ms
^C
--- 10.0.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2005ms
rtt min/avg/max/mdev = 1.983/2.280/2.453/0.214 ms
~~~

  Pinging should always succeed ("0% packet loss"). In addition, if
  your controller calls `printf` in its packet-in function, you will
  see the controller receiving all ping packets.

Shut down the controller properly with `Ctrl+C` and Mininet with
`Ctrl+D`.

<blockquote>

<p><b>Aside:</b> For the most part, we will be using simple topologies
in this tutorial. However, if you ever want to know more information
about the topology mininet is currently running, you can type</p>

<pre>
mininet> net
</pre>

<p>
In this example, you should see the following.</p>

<pre>
c0
s1 lo:  s1-eth1:h1-eth0 s1-eth2:h2-eth0 s1-eth3:h3-eth0 s1-eth4:h4-eth0
h1 h1-eth0:s1-eth1
h2 h2-eth0:s1-eth2
h3 h3-eth0:s1-eth3
h4 h4-eth0:s1-eth4
</pre>

<p>The first line indicates there is a controller (<code>c0</code>)
running. The second line lists the ports on switch <code>s1</code>:
port 1 (<code>s1-eth1</code>) is connected to host <code>h1</code>,
port 2 (<code>s1-eth2</code>) is connected to host <code>h2</code>,and
so on. If there was more than one switch in the network, we would see
additional lines prefixed by the switch identifier, one line per
switch. The remaining lines describe the hosts <code>h1</code> through
<code>h4</code>.</p>
</blockquote>

### Exercise 2: An Efficient Repeater

**[Solution](https://github.com/frenetic-lang/tutorials/blob/master/ox-tutorial-solutions/Repeater2.ml)**

Processing all packets at the controller works, in a sense, but is
inefficient. Next let's install forwarding rules in the flow table on
the switch so that it processes packets itself.

For this part, we will continue building on the naive repeater from
above. We will add a `switch_connected` handler. This
function is invoked when the switch first connects to the
controller. Hence, we can use it to install forwarding rules in its
forwarding table. Use the following code as a template.

~~~ ocaml
let switch_connected (sw : switchId) feats : unit =
  Printf.printf "Switch %Ld connected.\n%!" sw;
  send_flow_mod sw 1l (add_flow priority pattern action_list)
~~~

The function `send_flow_mod` adds a new rule to the flow table of the
switch. Your task is to fill in `priority`, `pattern`, and
`action_list`.

- `pattern` is an OpenFlow pattern for matching packets.  Since your
   repeater matches all packets, you can simply use `match_all`.  (We
   will cover patterns in detail later in the tutorial.)

- `priority` is a 16-bit priority for the rule. Since you just have
  one rule, the priority you pick is not relevant.

- For `action_list`, you must apply the same actions you did in your
  `packet_in` function (otherwise the switch and controller will
  implement different functionality!)

#### Building and Testing Your Controller

We can build and test this extended repeater in exactly the same way
as before. But now, during testing, the controller should not receive
any packets.

- In a separate terminal, start Mininet:

~~~
$ sudo mn --controller=remote --topo=single,4 --mac
~~~

- Build and start the controller:

~~~ shell
$ ox-build Repeater.d.byte
$ ./Repeater.d.byte
~~~

- From the Mininet prompt, try a ping:

~~~
mininet> h1 ping h2
~~~

  The pings should succeed, but the controller won't receive any
  packets (keep a `printf` in the `packet_in` function to observe
  packets reaching the controller).

### Why Keep the Controller Function?

We now have two implementations of the repeater: the `packet_in`
function on the controller and the flow table on the switch.  Since
the switch is so much faster, it is natural to wonder why we would
want to keep the `packet_in` function at all!

It turns out that there are still situations where the `packet_in`
function is necessary. We'll try to create such a situation
artificially:

- Shutdown the repeater (`Ctrl+C`)

- In mininet, send a stream of high-frequency pings:

~~~
mininet> h1 ping -i 0.001 h2
~~~

- Launch the repeater again:

~~~
$ ./Repeater.d.byte
~~~

It is very likely that a few packets will get sent to the controller
because when we launch the controller and the switch re-connects, the
controller sends two messages:

- First, Ox automatically sends a message to _delete all flows_.
  In general, we don't know the state of the flow table when a switch
  connects, so we need to start with a clean slate.

- Next, Ox sends the _add flow_ message that you wrote.

In the intervening time between these two messages, the flow table is
empty, thus some packets may get diverted to the controller. More
generally, whenever the switch is configured for the first time, or
re-configured to implement a policy change, we may see packets at the
controller. Hence, the controller need both (redundant) definitions of
the intended packet-processing functions.

{% include api.md %}

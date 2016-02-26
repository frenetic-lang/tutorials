---
layout: main
title: Learning Switch with Ox
---

In this exercise, we will build an application that automatically
learns the locations of each host as they connect and begin sending
traffic onto the network.  As with previous exercises, you will begin
by writing and testing a learning function and then implement it
efficiently using flow tables.

### The Learning Switch Function

Thus far, you have provided connectivity simply by forwarding each
packet out every port, aside from the one on which it arrived. Simple
network elements (called 'hubs') use this strategy, but obviously
flooding each packet throughout the network does not scale as it
grows. As an alternative, we can begin by flooding packets through the
network but also learn the locations of hosts. After we learn the
location of a hosts, we can forward traffic to it directly.

Abstractly, a learning switch can be thought of in terms of two
logically distinct components:

- The *learning module* builds a table that maps hosts (MAC addresses)
  to the switch port on which they are connected. It does this by
  inspecting the source address and ingress port of packets received
  at the switch.

- The *routing module* uses the table to route traffic: if the switch
  receives a packet for destination _d_ and the learning module has
  learned that _d_ is accessible through port _n_, then the routing
  module forwards the packet directly out port _n_. If the table does
  not have an entry for _d_, it floods the packet.

Naturally, you will begin by writing a `packet_in` function that
learns host locations.

#### Programming Task

You should use the template below to get started.  Save it in a file
called `Learning.ml` and place it in the directory
`~/src/frenetic-tutorial-workspace/Learning.ml`.

~~~ ocaml
(* ~/src/frenetic-tutorial-workspace/Learning.ml *)

open Frenetic_Ox
open Frenetic_OpenFlow0x01
open Frenetic_Packet
open Core.Std
open Async.Std

module MyApplication = struct
  include DefaultHandlers
  open Platform

  let known_hosts : (dlAddr, portId) Hashtbl.t = Hashtbl.create 50

  (* [FILL] Store the location (port) of each host in the known_hosts hash
     table. *)
  let learning_packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
    ...

  let routing_packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
    let pk = parse_payload pktIn.input_payload in
    let pkt_dst = pk.dlDst in
    try
      let out_port = Hashtbl.find known_hosts pkt_dst in
      Printf.printf "Sending via port %d to %Ld.\n" out_port pkt_dst;
      send_packet_out sw 0l {
        output_payload = pktIn.input_payload;
        port_id = None;
        apply_actions = [Output (PhysicalPort out_port)]
      }
    with Not_found ->
      (Printf.printf "Flooding to %Ld.\n" pkt_dst;
       send_packet_out sw 0l {
         output_payload = pktIn.input_payload;
         port_id = None;
         apply_actions = [Output AllPorts]
       })

  let switch_connected (sw : switchId) feats : unit =
    Printf.printf "Switch %Ld connected.\n%!" sw

  (* [FILL] Modify this packet_in function to run both learning_packet_in and
     routing_packet_in. *)
  let packet_in (sw : switchId) (xid : xid) (pk : packetIn) : unit =
    Printf.printf "%s\n%!" (packetIn_to_string pk);
    ...

end

let _ =
  let module C = Make (MyApplication) in
  C.start ();
~~~

Note that it contains a hash table to map hosts to ports:

~~~ ocaml
let known_hosts : (dlAddr, portId) Hashtbl.t = Hashtbl.create 50
~~~

> `50` is the initial capacity of the hash table.

You can use `Hashtbl.add` to add a new host/port mapping:

~~~ ocaml
Hashtbl.add known_hosts <pkt_src> <pkt_in_port>
~~~

The `routing_packet_in` function first extracts the ethernet source
address from the packet, and then looks it up in the table of known
host locations. If found, the packet is forwarded directly out the
host's port; otherwise, the packet is flooded.

Your job is to populate the known hosts table.  Modify the
`learning_packet_in` function in your Learning.ml to extract the
ethernet source address and input port from incoming packets, storing
them in the hash table.  Then, update `packet_in` to invoke
`learning_packet_in` followed by `routing_packet_in`.

#### Compiling and Testing your Learning Switch

You should first test that your learning switch preserves connectivity
by sending ICMP messages between each host pair.  Then, use `tcpdump`
to ensure that your learning switch stops flooding once it learns the
locations of each pair of hosts.

- Build and launch the controller:

  ~~~ shell
  $ make Learning.native
  $ ./Learning.native
  ~~~

- In a separate terminal window, start Mininet:

  ~~~ shell
  $ sudo mn --controller=remote --topo=single,4 --mac
  ~~~

- Test all-pairs connectivity:

  ~~~
  mininet> pingall
  ~~~

- Run `pingall` again to ensure that connectivity remains after the
first round of learning:

  ~~~
  mininet> pingall
  ~~~

At this point, your learning switch should have learned the locations
of all three hosts.  To test that your controller no longer floods
traffic, we will invoke `tcpdump` to monitor packets arriving at `h1`
while sending traffic from `h2` to `h3`.  No traffic should reach
`h1`.

  * In Mininet, start new terminals for `h1`, `h2`, and `h3`:

    ~~~
    mininet> xterm h1 h2 h3
    ~~~

  * In the terminal for `h1`, start `tcpdump`:

    ~~~
    # tcpdump -c 1 port 80
    tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
    listening on h1-eth0, link-type EN10MB (Ethernet), capture size 65535 bytes
    ~~~

    A brief explanation of the flags:

    - `-c 1` closes `tcpdump` after receiving one packet.
    - `port 80` ignores packets that do not arrive on port 80.

    Together, these flags cause `tcpdump` to exit as soon as a packet arrives on port 80.

  * In the terminal for `h2`, start a local fortune server:

    ~~~
    # while true; do fortune | nc -l 80; done
    ~~~

  * In the terminal for `h3`, fetch a fortune from `h2`:

    ~~~
    # curl 10.0.0.2:80
    ~~~

  * Finally, check the status of `tcpdump` in the terminal for `h1`;
    it should still be hanging, listening for an incoming packet.  If
    it terminated with the message `1 packet captured`, then your
    controller sent a packet to `h1` as well as `h2` (flooded the
    network).

    > Note that this will fail if we have not already used `ping` to
    > learn the locations of `h2` and `h3` before starting `tcpdump`.

### An Efficient Learning Switch

Sending packets directly to their destinations is a clear improvement
over flooding, but we can do better. Just as in each previous chapter,
we would like to install rules to keep forwarding on the switch. But
this time, we cannot be entirely proactive.  Imagine, for a moment,
that we intend our controller to work seamlessly with any number of
hosts with arbitrary MAC addresses, rather than the prescribed
topology we have tested with so far.  In this case, we must ensure
that the first packet sent from each host is directed to the
controller, so that we might learn its location.

#### Programming Task

Augment the `try..with` block in the `routing_packet_in` function to
install two new flows when a packet arrives and `known_hosts` contains
the location of the destination host.  Together, these two flows
should enable direct, bidirectional communication between the source
and desination hosts.

> Hint: only install new flow rules when both the source and
> destination host locations are known.  Otherwise, the controller may
> not learn the location of every host. For example, the first packet
> `h1` sends to `h2` will be redirected to the controller, and the
> controller will learn the location of `h1`.  If the controller
> immediately installs a rule directing all traffic destined for `h1`
> out the correct port, then the switch will keep all future traffic
> from `h2` to `h1` in the dataplane, preventing the controller from
> learning the location of `h2` by observing its outgoing traffic in
> the form of `packet_in` messages.

After the controller learns the location of every host, no more
packets should arrive on the controller.

#### Compiling and Testing the Efficient Learning Switch

Build and test the learning switch as before.

[Action]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.Action.html

[PacketIn]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.PacketIn.html

[PacketOut]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.PacketOut.html

[OxPlatform]: http://frenetic-lang.github.io/frenetic/docs/Ox_Controller.OxPlatform.html

[Match]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.Match.html

[Packet]: http://frenetic-lang.github.io/frenetic/docs/Packet.html
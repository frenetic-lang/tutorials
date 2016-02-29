---
layout: main
title: Traffic Monitoring with Ox
---

In this exercise, we will write a controller that measures the volume
of Web traffic on a network. To implement monitoring efficiently, we
will need to read the traffic [statistics] counters that OpenFlow
switches maintain. You will compose your new traffic monitor with the
[Repeater with Ox](../OxRepeater) and [Firewall with Ox](../OxFirewall) you wrote in earlier
exercises.

As usual, we will proceed in two steps: first writing and tesing a
traffic monitoring function and then implementing it efficiently using
flow tables.

## Exercise 1: The Monitoring Function

The monitor should count the total number of packets sent to *and*
received from port 80. Since the `packet_in` function receives all
packets, all you need to do is increment a global counter each time
`packet_in` receives a new packet:

~~~ ocaml
let num_http_packets = ref 0

let packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
  if is_http_packet (parse_payload pktIn.payload) then
    begin
      num_http_packets := !num_http_packets + 1;
      Printf.printf "Saw %d HTTP packets.\n%!" !num_http_packets
    end
~~~

Use the following code as a template for this exercise.  Save it in a file
called `Monitor1.ml`.

~~~ ocaml
(* ~/ox-tutorial-solutions/Monitor1.ml *)

open Frenetic_Ox
open Frenetic_OpenFlow0x01

module MyApplication = struct
  include DefaultHandlers
  open Platform

  (* [FILL] copy over the packet_in function from Firewall2.ml
     verbatim, including any helper functions. *)
  let firewall_packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
    ()

  (* [FILL]: Match HTTP packets *)
  let is_http_packet (pk : Packet.packet) =
    false

  let num_http_packets = ref 0

  let packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
    Printf.printf "%s\n%!" (packetIn_to_string pktIn);
    firewall_packet_in sw xid pktIn;
    if is_http_packet (parse_payload pktIn.input_payload) then
      begin
        num_http_packets := !num_http_packets + 1;
        Printf.printf "Saw %d HTTP packets.\n%!" !num_http_packets
      end

end

let _ =
  let module C = Make (MyApplication) in
  C.start ();
~~~

Your task:

- Write the `is_http_packet` predicate, using the [header accessor
  functions] you used to build the firewall. For HTTP, the port is 80,
  and the `nwProto` is 6.

- Remember that we are not just monitoring Web traffic. We also need
  to firewall ICMP traffic and apply the repeater to non-ICMP traffic,
  as you did before. In fact, you should use the `packet_in` function
  from `Firewall2.ml` _verbatim_.

### Building and Testing Your Monitor

You should first test that your monitor preserves the features of the
firewall and repeater. To do so, you'll run the same tests you in the
previous chapter. You should next test the monitor by checking that
traffic to and from port 80 increments the counter (and that other
traffic does not).

- Build and launch the controller:

  ~~~ shell
  $ ./ox-build Monitor1.d.byte
  $ ./Monitor1.d.byte
  ~~~

- In a separate terminal window, start Mininet:

  ~~~
  $ sudo mn --controller=remote --topo=single,4 --mac
  ~~~

- Test that the firewall correctly drops pings, reporting "100% packet
  loss":

  ~~~
  mininet> h1 ping h2
  mininet> h2 ping h1
  ~~~

- Test that Web traffic is unaffected, but logged. To do so, run a
   fortune server on one host and a client on another:

  ~~~
  mininet> h1 python -m SimpleHTTPServer 80 &
  ~~~

- And run a HTTP request to h1 from h2

  ~~~
  mininet> h2 curl h1:80
  ~~~

  This command should succeed and you should find HTTP traffic
  logged in the controller's terminal:

  ~~~
    Saw 1 HTTP packets.
    Saw 2 HTTP packets.
    Saw 3 HTTP packets.
    Saw 4 HTTP packets.
    Saw 5 HTTP packets.
  ...
  ~~~

> If you are seeing <code>packetIn</code> messages in between the HTTP
> traffic logs, you could comment out the appropriate printf commands.


- Finally, you should test that other traffic is neither blocked by
  the firewall nor counted by your monitor. To do so, kill the fortune
  server running on `h1` and start a new fortune server on a
  non-standard port (e.g., 8080):

  ~~~
  mininet> h1 kill %python
  mininet> h1 python -m SimpleHTTPServer 8080 &
  ~~~

- On the terminal for `h2`, fetch the directory listing:

  ~~~
  mininet> h2 curl h1:8080
  ~~~

  The client should successfully download the directory listing. However, none of
  these packets should get logged by the controller.

## Exercise 2: Efficiently Monitoring Web Traffic

Switches themselves keeps track of the number of packets (and bytes)
they receive. To implement an efficient monitor, we can use OpenFlow's
[statistics] API to query these counters.

Recall from the [OxRepeater] chapter that each rule in a flow table is
associated with a packet-counter that counts the number of packets to
which the rule is applied. For example, consider the following flow
table:

|----------+---------+--------------------+---------+-------|
| Priority | Pattern | Actions            | Packets | Bytes | 
|:--------:|:-------:|:-------------------|:-------:|:-----:|
| 50       | ICMP    |                    | 2       | 148   |
| 20       | all     | Output AllPorts    | 300     | 34674 |
|----------+---------+--------------------+---------+-------|

The first counter states that 2 ICMP packets have been blocked and the
secord reports that 300 non-ICMP packets have been forwarded.

We can read these counters using the OpenFlow statistics API, but
these are not the counters we are looking for. The problem is that the
second rule counts HTTP packets as well as *all other* non-ICMP
traffic. Although this flow table implements the desired forwarding
policy, it is too coarse grained to implement the desired monitoring
policy.

Copy `Monitor1.ml` to a new file `Monitor2.ml` and 
build a flow table. The forwarding logic above
requires two rules&mdash;one for ICMP and the other for non-ICMP
traffic&mdash;but we will need additional rules to ensure that we have
sufficiently fine-grained counters. 
In particular, we cannot write a single OpenFlow
pattern that matches both HTTP requests and replies. You need to match
them separately, using two rules, which will give you two
counters. Therefore, you need to read each counter independently and
calculate their sum.

We can read counters by calling [send_stats_request] periodically. To
do this, use the following function:

~~~ ocaml
let rec periodic_stats_request sw interval xid pat =
  let callback () =
    Printf.printf "Sending stats request to %Ld\n%!" sw;
    send_stats_request sw xid
      (AggregateRequest (pat, 0xff, None));
    periodic_stats_request sw interval xid pat in
  timeout interval callback
~~~

Add this definition to your `Monitor2.ml`.

This function issues a request every `interval` seconds for counters
that match `pat`. Use `periodic_stats_request` in `switch_connected`.
For example, in the template below, the program periodically reads the
counter for HTTP requests and HTTP responses every five seconds:

~~~ ocaml
let switch_connected (sw : switchId) feats : unit =
  Printf.printf "Switch %Ld connected.\n%!" sw;
  periodic_stats_request sw 5.0 10l match_http_requests;
  periodic_stats_request sw 5.0 20l match_http_responses;
  ...
~~~

Fill in the patterns `match_http_requests` and `match_http_responses`,
which you have already calculated in order to install the rules using
`send_flow_mod`.

Finally, we need a `stats_reply` function that handles the stats
responses from the switch and calculates the sum of the two
counters. The following code implements such a handler:

~~~ ocaml
let num_http_request_packets = ref 0L
let num_http_response_packets = ref 0L

let stats_reply (sw : switchId) (xid : xid) (stats : reply) : unit =
  match stats with
  | AggregateFlowRep rep ->
    begin
      if xid = 10l then
        num_http_request_packets := rep.total_packet_count
      else if xid = 20l then
        num_http_response_packets := rep.total_packet_count
    end;
    Printf.printf "Saw %Ld HTTP packets.\n%!"
      (Int64.add !num_http_request_packets !num_http_response_packets)
  | _ -> ()

~~~

#### Building and Testing Your Monitor

Build and test the extended monitor as before.

#### Extra Credit

Consider what happens if the controller receives HTTP packets before
the switch is fully initialized and extend your monitoring program to
handle this situation.

[statistics]: https://github.com/frenetic-lang/frenetic/blob/master/lib/OpenFlow0x01.mli

[Action]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.Action.html

[PacketIn]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.PacketIn.html

[PacketOut]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.PacketOut.html

[Ox Platform]: http://frenetic-lang.github.io/frenetic/docs/Ox_Controller.OxPlatform.html

[Match]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.Match.html

[Packet]: http://frenetic-lang.github.io/frenetic/docs/Packet.html

{% include api.md %}

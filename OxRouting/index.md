---
layout: main
title: Shortest Path Forwarding with Ox
---

In this exercise, we will write an application that forwards packets
along the shortest paths in a static network topology. This is an
essential application that provides the foundation of most networks.

### The Shortest Path Forwarding Function

More specifically, this application will implement the following
functionality:

* It will calculate the shortest paths from each source host to every
  other host in the topology.

* For each path, it will install corresponding forwarding rules on the
switches. Recall from previous chapters that each rule contains a
pattern and an action (as well as a priority and counters). We will
use patterns that match on destination addresses and actions that
forward to the next hop in the path.

### Topology

We will represent network topologies using the data types defined in
the [Network module] and [Network_Common module] from [ocaml-topology
repository]. For simplicity, in this tutorial, we will test our code
on the tree topologies. The following figure depicts a tree with 5
hosts and 3 switches in a tree of depth 2:

![images](../images/Routing.jpg)

However, the application itself should work with any
`Network_Common.Topology.t`.

#### Programming Task

Fill in the missing code in the template below. Save it in a file
called `Routing.ml` and place it in the directory
`~/src/frenetic/ox-tutorial-workspace/Routing.ml`.

~~~ ocaml
 open OxPlatform
 open OpenFlow0x01
 open OpenFlow0x01_Core
 open Network_Common

 module Topology = Net.Topology
 
 module MyApplication = struct

   include OxStart.DefaultTutorialHandlers

   let topology = Net.Parse.from_dotfile "topology.dot"
   
   (* creates Mininet script to generate the topology *)
   let () = 
     let fd = open_out "topology.py" in 
     Printf.fprintf fd "%s" (Net.Pretty.to_mininet topology);
     close_out fd

   let is_host v = 
     match Node.device (Topology.vertex_to_label topology v) with 
     | Node.Host -> true 
     | _ -> false  
  
   (* Creates a list of hosts *)
   let hosts = 
     Topology.VertexSet.filter is_host (Topology.vertexes topology)

   (* [FILL] Install rules for each switch *)
   let switch_connected (sw: switchId) (feats : SwitchFeatures.t) : unit = 
     ()
    
   (* [FILL] drop all packets that reach the controller *)
   let packet_in (sw : switchId) (xid : xid) (pk : packetIn) : unit =
     ()

 end
  
 module Controller = OxStart.Make (MyApplication)
~~~

In more detail:

* To calculate the shortest paths, use the function
UnitPath.all_shortest_paths from Network.ml which will returns
hashtable mapping each node in the graph to its predecessor along the
path back to a given source.

* Calculate these paths for every host in the network and then convert
  them into forwarding rules. The function `Topology.vertex_to_label`
  obtains the information associated with each node such as switch
  identifiers and host addresses. The functions `Topology.find_edge`
  and `Topology.edge_src` return the edge between two nodes and the
  the source node at the end of the edge respectively.

* Install the rules calculated for each path on each switch as they
  connect.

* For simplicity, drop any packets that reach the controller.

#### Compiling and Testing

 * Build and launch the controller:
 
       $ oxbuild Routing.native
       $ ./Routing.native
 

Launching the controller generates a python script `topology.py` that
starts Mininet with the topology given above.

 * Start Mininet in a separate terminal window:

       $ sudo mn --custom topology.py
 
 * First, test all-pairs connectivity:

       mininet> pingall

 This should show that 0% of the packets have been dropped.

 * Dump flows on switch 1:

       mininet> sh ovs-ofctl dump-flows s1

 * You should receive an output similar to this:

       NXST_FLOW reply (xid=0x4):
        cookie=0x0, duration=90.133s, table=0, n_packets=6, n_bytes=588, idle_age=85, 
       priority=100,dl_dst=00:00:00:00:00:01 actions=output:2
        cookie=0x0, duration=90.133s, table=0, n_packets=8, n_bytes=784, idle_age=85, 
       priority=100,dl_dst=00:00:00:00:00:05 actions=output:1
        cookie=0x0, duration=90.133s, table=0, n_packets=6, n_bytes=588, idle_age=85, 
       priority=100,dl_dst=00:00:00:00:00:02 actions=output:2
        cookie=0x0, duration=90.133s, table=0, n_packets=6, n_bytes=588, idle_age=85, 
       priority=100,dl_dst=00:00:00:00:00:04 actions=output:3
        cookie=0x0, duration=90.133s, table=0, n_packets=6, n_bytes=588, idle_age=85, 
       priority=100,dl_dst=00:00:00:00:00:03 actions=output:3

 Verify that the packets are being forwarded out of the correct port
 based on their destination MAC address. Using `ovs-ofctl`, dump the
 flows on all switches to ensure that packets are being forwarded
 along the shortest paths.
 
{% include api.md %}
 

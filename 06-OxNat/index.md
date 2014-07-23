---
layout: main
title: Network Address Translation with Ox
---

Chapter 6: Network Address Translator
==========================

In this exercise, you will build a Network Address Translator (NAT) by first writing and
testing a translator function that first translates IP addresses and then extending
it so that it translates port numbers as well.

### The Network Address Translating Function

In the 1990s, the explosive growth of the internet created a demand for IP address space.
Before NAT was invented, all IP addresses were globally unique. NAT allows private IP addresses
to be reused in multiple local area networks (LAN) by translating all private IP addresses in
a LAN to one globally unique public IP address. NAT essentially does the following:

* For packets received on private (internal) ports, NAT rewrites the private IP address
to the public IP address and installs rules to forward the packet to the public port.
    * NAT will also store relevant information for each packet in a data structure,
      such as a hashtable.
* For packets received on the public (external) port, NAT checks to see if the TCP port
  destination of the packet matches the TCP port source of any of the packets stored in
  the data structure.
    * If so, the public IP address of the packet is rewritten to the corresponding private
      IP address and rules are installed to forward the packet to the correct private port.
    * If not, the packet is simply dropped.

### Topology

You will work with the following network topology:

![images](images/NatTopo.jpg)

The figure shows 2 private hosts and a public host all connected with a single switch. You can create this topology easily with Mininet:

```
$ sudo mn --controller=remote --topo=single,3 --mac --arp
```
#### Programming Task

You should use the template below to get started. Save it in a file called `Nat1.ml` and
place it in the directory `~/src/frenetic/ox-tutorial-workspace/Nat1.ml`.

```ocaml
(* ~/src/frenetic/ox-tutorial-workspace/Nat1.ml *)

open OxPlatform
open Packet
open OpenFlow0x01_Core

module MyApplication = struct

  include OxStart.DefaultTutorialHandlers

  let mappings = Hashtbl.create 50

  let publicIP = 167772259l
  let publicMAC = 153L

  let privateIP1 = 167772161l

  let privateIP2 = 167772162l

   let switch_connected (sw:switchId) feats : unit =
    Printf.printf "Switch Connected %Ld\n%!" sw

  let packet_in (sw: switchId) (xid : xid) (pktIn : packetIn) : unit =
    let pk = parse_payload pktIn.input_payload in
      (* If the packet is of type TCP and came in through port 1 or 2 *)
      if (pktIn.port = 1 || pktIn.port = 2)
        && Packet.dlTyp pk = 0x800
        && Packet.nwProto pk = 0x06
      then
	(* [FILL] Add packet info into hashtable and install rules to
           forward packet out of correct port *)
        ...
      else (* For packets arriving on port 3 *)
	try (* If a mapping is found in the hashtable *)
          Printf.printf "Non TCP or incoming flow %s \n" (packetIn_to_string pktIn);
          (* [FILL] Install reverse rules to forward packet back to correct host *)
          ...
        with Not_found ->
	  (* [FILL] If no mapping is found in hashtable then drop the packet *)
          ...
end

module Controller = OxStart.Make (MyApplication)

```

#### Compiling and Testing

These tests will ensure that TCP packets are being sent and received to the correct hosts
and addresses are translated correctly.

 * Start Mininet:

  ```shell
  $ sudo mn --controller=remote --topo=single,3 --mac --arp
  ```

 * In a separate terminal window, build and launch the controller:

  ```shell
  $ make Nat1.d.byte
  $ ./Nat1.d.byte
  ```

  We will be using a topology that consists of two internal hosts and one external host
  connected by a switch.

 * In Mininet, start new terminals for `h1`, `h2`, and `h3`:

  ```
  mininet> xterm h1 h2 h3
  ```

 * In the terminal for `h3`, add static entries into the arp table and start a fortune
   server.

  ```
  # arp -v -s [public IP address] [public MAC address]
  # while true; do fortune | nc -l 80; done
  ```
The first command adds a static entry into the arp table that binds your public MAC
address to your public IP address.

* In the terminal for `h1`, fetch a fortune from `h3`.

  ```
  # curl 10.0.0.3:80
   ```
You should’ve received a fortune. Now try to fetch a fortune on the `h2` terminal.

* In the terminal for the controller, check to see that your IP addresses are translating
correctly.

  ```
  Outgoing flow packetIn{
   total_len=74 port=1 reason=NoMatch
   payload=dlSrc=00:00:00:00:00:01,dlDst=00:00:00:00:00:03,
   nwSrc=10.0.0.1,nwDst=10.0.0.3,tpSrc=42635;tpDst=80 (buffered at 256)

  Translating Private IP:167772161 to Public IP:167772259.
   ```
* Incoming packets should look similar to this:

  ```
  Non TCP or incoming flow packetIn{
   total_len=74 port=3 reason=NoMatch
   payload=dlSrc=00:00:00:00:00:03,dlDst=00:00:00:00:00:099,
   nwSrc=10.0.0.3,nwDst=10.0.0.99,tpSrc=80;tpDst=42635 (buffered at 257)
   }
  Found a mapping in the hashtable!
  ```
Notice how this packet matches the outgoing flow packet above.

### PAT - The Port Address Translating Function

PAT is essentially an extension of NAT except in addition, PAT assigns each host
a port number from a list of available port numbers. This prevents confusion in
the extreme case where two hosts in a LAN share the same TCP port number. Although
all hosts in a LAN share the same public IP address, the router will know exactly
which host to forward packets to due to their different port numbers.

#### Programming Task

Modify Nat1.ml to translate port numbers as well.

Specifically,

* Assign each host a public port number.

* For packets received on internal ports, rewrite the original TCP source port
number with the assigned port number of the host.

* For packets received on the external port, rewrite the assigned TCP destination
  port number with the original TCP destination port number.

#### Compiling and Testing

Compile and test your controller the same way that you did before.

* In the terminal for the controller, check to see that your IP addresses and port
  numbers are translating correctly.

  ```
  Outgoing flow packetIn{
   total_len=74 port=1 reason=NoMatch
   payload=dlSrc=00:00:00:00:00:01,dlDst=00:00:00:00:00:03,
   nwSrc=10.0.0.1,nwDst=10.0.0.3,tpSrc=42635;tpDst=80 (buffered at 256)
   }
  Translating Private IP:167772161:42635 to Public IP:167772259:5000.
  ```

* Incoming packets should look similar to this:

  ```
  Non TCP or incoming flow packetIn{
   total_len=74 port=3 reason=NoMatch
   payload=dlSrc=00:00:00:00:00:03,dlDst=00:00:00:00:00:099,
   nwSrc=10.0.0.3,nwDst=10.0.0.99,tpSrc=80;tpDst=5000 (buffered at 257)
   }
  Found a mapping in the hashtable!
  ```

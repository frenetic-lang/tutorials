Getting Started
---------------

This is a hands-on tutorial with several programming exercises.
We strongly recomend using the tutorial VM we've prepared that has
all the software that you need pre-installed:

- Download and install the [VirtualBox](https://www.virtualbox.org)
  virtualization platform.
  
- Download the
  [Frenetic Tutorial VM](http://www.cs.brown.edu/~arjun/frenetic.ova).

- Launch the tutorial VM, which will launch a Linux desktop
  environment and automatically log you into the account
  "frenetic". The password for this account is also "frenetic".

- At a terminal, go to the tutorial directory, check for updates, and
  rebuild the tutorial software:

  ```
  $ cd src/frenetic
  $ git pull
  $ make reinstall
  ```

Introduction
------------

In this tutorial, you will learn to program software-defined networks (SDNs)
using OpenFlow and Frenetic. The tutorial is
divided into two sections:

* **Ox:** Chapters 2 &mdash; 5 introduce the nuts and bolts of
programming an OpenFlow-based SDN. In these chapters, we use *Ox*, a
simple platform for writing OpenFlow controllers in OCaml. Apart from
managing the socket connections and serialization, Ox gives you direct
access to the OpenFlow protocol.

Ox is loosely based on platforms such as 
[POX](https://openflow.stanford.edu/display/ONL/POX+Wiki) and
[NOX](http://www.noxrepo.org/nox/about-nox/). The concepts and techniques
you learn in this tutorial are applicable to those platforms too.

[[2 Ox Repeater][Ch2]] [[3 Ox Firewall][Ch3]] [[4 Ox Monitor][Ch4]]
[[5 Ox Learning][Ch5]]

* **Frenetic:** Chapters 6 &mdash; 8 teach you how to program SDNs
  using the _Frenetic_ domain-specific programming language
  (FreneticDSL). You will see that FreneticDSL provides high-level
  abstractions and rich, compositional features that make SDN
  programming much easier.

> TODO(arjun): I'd rather not introduce another name (NetCoreDSL).
> In fact, maybe we should jettison the name NetCore altogether (apart
> from the file extension .nc). Let's just call chapters 6 - 8 "Frenetic".
> Below, let's just state that you can write Frenetic programs embedded
> in OCaml too.

[[6 Frenetic Introduction][Ch6]] [[7 Frenetic Firewall][Ch7]] [[8
Multiple Switches][Ch8]] [[9 Frenetic Monitoring][Ch9]]

### Frenetic

This tutorial should also be viewed as a stepping stone toward learning how to
program in the more powerful *Frenetic* environment. *Frenetic* is a
general-purpose SDN programming language embedded as a set of libraries in
OCaml.  Frenetic applications react to network events, such as topology changes 
and statistics queries.  For example:

1. An event reaches the application.

1. The application generates a new static network configuration (using
   NetCore) and sends it to the Frenetic run time.

1. The Frenetic run time compiles it to OpenFlow and updates the
   running network.

Static network configurations are built using
[FreneticLib](http://frenetic-lang.github.io/frenetic/docs/NetCore_Types.html),
which has the same semantics as FreneticDSL, which is presented in this tutorial.
Hence, a Frenetic program is really just a general-purpose
OCaml program that reacts to network events and generates a stream of
FreneticDSL policies.

#### Why Frenetic?

As an aside, you may find it interesting to read about [why we created
Frenetic](http://frenetic-lang.org/publications/overview-ieeecoms13.pdf) in the
first place.

Background Material
-------------------

The chapters on OpenFlow programming with Ox involve a little bit of
OCaml programming. We only use a tiny fragment of the language and do
provide lots of example code. But, some familiarity with OCaml syntax
will be very helpful. We recommend reading these two brief tutorials:

1. [OCaml Basics](http://ocaml.org/tutorials/basics.html), and

2. [The Structure of OCaml Programs](http://ocaml.org/tutorials/structure_of_ocaml_programs.html).

Handy References
----------------

- [Ox Platform Reference](http://frenetic-lang.github.io/frenetic/docs/)
  
  In the first part of this tutorial, you will write controllers using
  the Ox Controller platform.

- [OpenFlow 1.0 Specification](http://www.openflow.org/documents/openflow-spec-v1.0.0.pdf)

  The OpenFlow specification describes OpenFlow-conformant switches
  and details the wire-format of the OpenFlow protocol. You'll find that
  most of the Ox Platform Reference simply reflects the OpenFlow messages
  and data types into OCaml.

  You don't need to read the OpenFlow specification to follow the
  guide. But, you will need to do so to understand OpenFlow in depth.

- [Mininet](http://mininet.org/walkthrough/)

  You will use the Mininet network simulator to run your
  controllers. We will tell you exactly what Mininet commands to use,
  so you don't really need to read this.

## Next chapter: [Ox Repeater][Ch2]

[Action]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.Action.html

[PacketIn]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.PacketIn.html

[PacketOut]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.PacketOut.html

[OxPlatform]: http://frenetic-lang.github.io/frenetic/docs/Ox_Controller.OxPlatform.html

[Match]: http://frenetic-lang.github.io/frenetic/docs/OpenFlow0x01.Match.html

[Packet]: http://frenetic-lang.github.io/frenetic/docs/Packet.html

[Ch2]: 02-OxRepeater
[Ch3]: 03-OxFirewall
[Ch4]: 04-OxMonitor
[Ch5]: 05-OxLearning
[Ch6]: 06-Frenetic-Introduction
[Ch7]: 07-NCFirewall
[Ch8]: 08-NCMultiSwitch
[Ch9]: 09-NCMonitoring

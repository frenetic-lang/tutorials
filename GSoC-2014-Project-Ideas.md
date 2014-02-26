Common background readings:
* [Software-Defined Networking: The New Norm for Networks.](https://www.opennetworking.org/sdn-resources/sdn-library/whitepapers)
* [Languages for software-defined networks.](http://frenetic-lang.org/publications/overview-ieeecoms13.pdf) IEEE Communications Magazine, 51(2):128-134, 2013

# OpenStack Integration

OpenStack is a cloud computing platform that orchestrates compute,
storage, and network resources in public/private cloud
environments. The OpenStack Networking API component exposes a
networking-as-a-service model via a REST API. As part of the GSoC, a
student could consider implementing the Networking REST API for
Frenetic to allow it to work as a backend for OpenStack.

* Mentor: Marco Canini
* Difficulty: medium/hard
* Programming languages: OCaml and Python
* Recommended reading:
  * [OpenStack](http://en.wikipedia.org/wiki/OpenStack)
  * [OpenStack Networking API](http://docs.openstack.org/api/openstack-network/2.0/content/)

# OpenFlow 1.3/1.4 Support

The current Frenetic implementation has partial support for OpenFlow
1.3 and has no support for OpenFlow 1.4. As part of the GSoC, a
student could consider implementing complete support for these two
versions of the protocol. This will require going through the protocol
specs, creating the corresponding OCaml types and implementing the
necessary message serializers and deserializers, as well as pretty printing
functions. Moreover, to simplify the interface
upstream, one might consider designing an abstraction layer that
hides the differences between these versions of OpenFlow and allows
switches speaking different versions to interoperate in the same
network.

* Mentor: Marco Canini or Arjun Guha
* Difficulty: medium
* Programming languages: OCaml and C
* Recommended reading:
* [OpenFlow specs](https://www.opennetworking.org/sdn-resources/onf-specifications/openflow)

# Network Virtualization

The current Frenetic implementation does not allow a developer to
write policies for a virtual network that are mapped down to
underlying topology. As part of the GSoC, a student could consider
porting the virtual network abstractions provided in other controller
platforms to Frenetic.

* Mentor: Marco Canini
* Difficulty: medium
* Programming languages: OCaml and Python
* Recommended reading:
  * [Composing Software Defined Networks.](http://frenetic-lang.org/publications/composing-nsdi13.pdf) In USENIX Symposium on Networked Systems Design and Implementation (NSDI), 2013

# Compiler Optimizations

Frenetic allows developers to describe the intended behavior of the
network in a high-level language. The Frenetic compiler and run-time
system generate the low-level code needed to execute programs
efficiently in hardware switches. The compiler performance of the
current implementation could be improved. As part of the GSoC, a
student could consider studying the existing compiler and implementing
performance optimizations to reduce the number of rules.

* Mentor: Spiros Eliopoulos
* Difficulty: hard
* Programming languages: OCaml and Python
* Recommended reading:
  * [NetKAT: Semantic Foundations for Networks.](http://www.cs.cornell.edu/~jnfoster/papers/frenetic-netkat.pdf) In Symposium on Principles of Programming Languages (POPL), 2014

# Language Bindings

To write network programs for Frenetic, developers must currently use
either the custom syntax exposed by the Frenetic binary, or an OCaml
API. As part of the GSoC, a student could consider implementing new
language bindings to integrate the power of Frenetic to other
languages. A special type of "language bindings" proposal could also
look into integrating Frenetic as the backend for a BGP implementation
(e.g., bird).

* Mentor: Spiros Eliopoulos
* Difficulty: easy
* Programming languages: OCaml and another language for the bindings (e.g., Python, Ruby, etc.)
* Recommended reading:
  * [NetKAT: Semantic Foundations for Networks.](http://www.cs.cornell.edu/~jnfoster/papers/frenetic-netkat.pdf) In Symposium on Principles of Programming Languages (POPL), 2014

# Frenetic Debugger

Frenetic allows developers to write network programs but does not allow them to debug these programs. As with any software development toolkit, having tools to aid in debugging is very important.
As part of the GSoC, a student could consider implementing a debugger for Frenetic. This should consist of (1) an introspection component within Frenetic to export the current state of the controller, (2) a component to read the state of the network by connecting to switches and querying the flow tables, and (3) a GUI that displays this information to the developer. Additionally, one could add a fourth component to implement the active debugging technique described in the references below.

* Mentor: Marco Canini or Spiros Eliopoulos
* Difficulty: medium/hard
* Programming languages: OCaml and Python/Javascript
* Recommended reading:
  * [Where is the Debugger for my Software-Deﬁned Network?](http://conferences.sigcomm.org/sigcomm/2012/paper/hotsdn/p55.pdf) In Workshop on Hot Topics in Software-Defined Networking (HotSDN), 2012
  * I Know What Your Packet Did Last Hop: Using Packet Histories to Troubleshoot Networks. In USENIX Symposium on Networked Systems Design and Implementation (NSDI), 2014, To appear.


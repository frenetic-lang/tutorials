Common background readings:
* [Software-Defined Networking: The New Norm for Networks.](https://www.opennetworking.org/sdn-resources/sdn-library/whitepapers)
* [Languages for software-defined networks.](http://frenetic-lang.org/publications/overview-ieeecoms13.pdf) IEEE Communications Magazine, 51(2):128-134, 2013

# Integration with OpenStack

OpenStack is a cloud computing platform that orchestrates various compute,
storage and network resources in public/private cloud environments. A component
of OpenStack called Networking API exposes a networking-as-a-service model via a REST
API. Currently Frenetic does not implement the REST API to work as a backend
for OpenStack. As part of the GSoC, a student could consider implementing the
Neworking REST API for Frenetic.

* Mentor: Marco Canini
* Difficulty: medium/hard
* Programming languages: OCaml and Python
* Recommended reading:
  * [OpenStack](http://en.wikipedia.org/wiki/OpenStack)
  * [OpenStack Networking API](http://docs.openstack.org/api/openstack-network/2.0/content/)

# Support for OF 1.3/1.4

The current Frenetic implementation has partial support for OpenFlow 1.3 and
no support for OpenFlow 1.4. As part of the GSoC, a student could consider
implementing complete support for these two versions of the protocol.

* Mentor: Marco Canini
* Difficulty: medium
* Programming languages: OCaml and C
* Recommended reading:
  * [OpenFlow specs](https://www.opennetworking.org/sdn-resources/onf-specifications/openflow)

# Adding network virtualization layer

The current Frenetic implementation lacks support for network virtualization
where a developer can write a policy for a virtual network and a mapping
between the virtual and underlying topology and Frenetic takes care of
generating the correct set of rules for the underlying network. As part of the
GSoC, a student could consider porting the network abstraction primitive
implemented in another network programming language to Frenetic.

* Mentor: Marco Canini
* Difficulty: medium
* Programming languages: OCaml and Python
* Recommended reading:
  * [Composing Software Defined Networks.](http://frenetic-lang.org/publications/composing-nsdi13.pdf) In USENIX Symposium on Networked Systems Design and Implementation (NSDI), 2013

# Compiler optimizations

With Frenetic, developers describe the intended behavior of the network in a
high-level language, and the Frenetic compiler and run-time system generate
the low-level code needed to execute programs efficiently in hardware
switches. The compiler performance of the current implementation could be
improved. As part of the GSoC, a student could consider profiling the existing
compiler and implementing performance optimizations.

* Mentor: Spiros Eliopoulos
* Difficulty: hard
* Programming languages: OCaml and Python
* Recommended reading:
  * [NetKAT: Semantic Foundations for Networks.](http://www.cs.cornell.edu/~jnfoster/papers/frenetic-netkat.pdf) In Symposium on Principles of Programming Languages (POPL), 2014

# Language bindings

To write network programs for Frenetic, currently the developer can only use
either the custom syntax exposed by Frenetic or the OCaml API. As part of the
GSoC, a student could consider implementing new language bindings to integrate
the power of Frenetic to other languages.

* Mentor: Spiros Eliopoulos
* Difficulty: easy
* Programming languages: OCaml and another language for the bindings (e.g., Python, Ruby, etc.)
* Recommended reading:
  * [NetKAT: Semantic Foundations for Networks.](http://www.cs.cornell.edu/~jnfoster/papers/frenetic-netkat.pdf) In Symposium on Principles of Programming Languages (POPL), 2014

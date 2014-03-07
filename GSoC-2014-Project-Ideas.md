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

## Goals

The current Frenetic implementation has partial support for OpenFlow
1.3 and has no support for OpenFlow 1.4. As part of the GSoC, a
student could consider implementing complete support for these two
versions of the protocol.

## Details

Ultimately this project boils down to designing and implementing: (1) a set of types in OCaml that reflect the full set of OpenFlow messages and types for versions 1.3 and 1.4 of the protocol specs, (2) support for serializing and deserializing the OCaml types into/from the corresponding OpenFlow format, and (3) functions for pretty printing the OCaml types.

One approach would be to write code entirely in OCaml. In this case, the OpenFlow types in OCaml should have a similar structure to those already defined to support OpenFlow 1.0 and partially OpenFlow 1.3. The serializers/deserializers would be written in OCaml itself, along with unit tests to validate the correctness of the implementation using round trip testing of the form: deserialize(serialize(X)) == X.

Another approach could be to adopt an existing C or C++ library that supports multiple versions of OpenFlow and integrate it into OCaml. One such library exists in OpenVSwitch. Another example might be [flowgrammable's OpenFlow library]( http://flowgrammable.org/sdn/openflow/message-layer/).
Still, if an external library is adopted, it should be exported to OCaml by designing an API that is convenient to work with (read, similar to the existing OpenFlow 1.0 design).

Moreover, to simplify the interface upstream, one might consider designing an abstraction layer that
hides the differences between different versions of OpenFlow and allows switches speaking different versions to interoperate in the same network.

## Other info

* Mentor: Marco Canini or Arjun Guha
* Difficulty: medium
* Programming languages: OCaml [and C(++)]
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

## Goals
To write network programs for Frenetic, developers must currently use
either the custom syntax exposed by the Frenetic binary, or an OCaml
API. As part of the GSoC, a student could consider implementing new
language bindings to integrate the power of Frenetic to other
languages. A special type of "language bindings" proposal could also
look into integrating Frenetic as the backend for a BGP implementation
(e.g., bird).

## Details

Ultimately this project boils down to designing and implementing a wrapper of the Frenetic application API that exposes this API in another programming language. There are many possible ways to export the Frenetic API. One approach might be to expose the Frenetic API as a RESTful interface by an embedded HTTP server. Another approach might be to embed a language interpreter (e.g., Python or Ruby) into Frenetic itself.
Another approach might be to use an RPC library such as Apache Thrift.

This project requires two main components to be developed, one in OCaml and one in the programming language for the bindings:

On the Frenetic side:
* Wrap the Frenetic API in component that can expose this API to an external language. Exposing the API can be done via one of several possible mechanisms as described above.

On the other language side:
* Determine a representation of the NetKAT abstract syntax tree that programmers can use to construct policies (as an example, consider how Pyretic embeds into Python a set of types that are closely related to the NetKAT types).
* Develop the component that interfaces with the Frenetic API

## Other info
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


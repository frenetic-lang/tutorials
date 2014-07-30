---
layout: main
title: Frenetic Tutorial
---

Getting Started
---------------

This is a hands-on tutorial with several programming exercises.
We strongly recomend using the tutorial VM we've prepared that has
all the software that you need pre-installed. You can get the tutorial
VM from the following link:

https://github.com/frenetic-lang/frenetic/releases/frenetic-1.0.1

TODO(arjun): Update this link.

Introduction
------------

In this tutorial, you will learn some of the basic ideas being
software-defined networking (SDN) programming with OpenFlow and
Frenetic. The tutorial is divided into two sections:

* **Ox:** The first few chapters introduce the nuts and bolts of
programming a SDN switches using *Ox*, a simple platform for writing
OpenFlow controllers in OCaml. Apart from a few constructs for
managing socket connections and message serialization, Ox gives the
programmer direct access to the OpenFlow protocol. Ox is inspired by
platforms such as
[POX](https://openflow.stanford.edu/display/ONL/POX+Wiki) and
[NOX](http://www.noxrepo.org/nox/about-nox/), so the techniques you
learn in this tutorial are applicable to those platforms too.

<ul>
{% for item in site.data.toc %}
{% if item.group == "ox" %}
{% assign ix = forloop.index|minus:1 %}
[<a href="{{ site.data.toc[ix].path }}">{{ site.data.toc[ix].name }}</a>]
{% endif %}
{% endfor %}
</ul>

* **Frenetic:** The following chapters teach you how to program SDNs
  using the _NetKAT_ domain-specific programming language. NetKAT
  provides high-level abstractions and rich, compositional features
  that greatly simplifies SDN programming.

<p>
{% for item in site.data.toc %}
{% if item.group == "frenetic" %}
{% assign ix = forloop.index|minus:1 %}
[<a href="{{ site.data.toc[ix].path }}">{{ site.data.toc[ix].name }}</a>]
{% endif %}
{% endfor %}
</p>

Background Material
-------------------

To write NetKAT and Ox programs, it will be useful to be familiar with
the OCaml language. [Real World OCaml] provides an excellent
introduction to OCaml and is available online. However, the tutorial
contains lots of examples, so we recommend just skimming Chapters 1--8
and 18 and referring back to them as needed.

Useful References
-----------------

- [OpenFlow 1.0 Specification](http://www.openflow.org/documents/openflow-spec-v1.0.0.pdf)

  This specification describes OpenFlow switches and configuration
  protocol in detail. You'll find that most of the Ox Platform
  Reference simply reflects the OpenFlow messages and data types into
  OCaml. 

- [Mininet](http://mininet.org/)

  This webpage describes Mininet, a system we will use to run
  controllers on a simulated network of switches.

- [OCaml APIs](http://frenetic-lang.github.io/api)

  This web page provides documentation for the
  [Ox](http://freneti-lang.github.io/api/ox) and
  [NetKAT](http://frenetic-lang.github.io/api/frenetic) libraries, as
  well as other supporting libraries used in this tutorial.

[Real World OCaml]: https://realworldocaml.org
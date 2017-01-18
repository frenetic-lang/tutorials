---
layout: main
title: Introduction
---

This tutorial presents some of the basic ideas being software-defined
networking (SDN) programming with OpenFlow and Frenetic. It is divided
into two sections:

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

<ul>
{% for item in site.data.toc %}
{% if item.group == "frenetic" %}
{% assign ix = forloop.index|minus:1 %}
[<a href="{{ site.data.toc[ix].path }}">{{ site.data.toc[ix].name }}</a>]
{% endif %}
{% endfor %}
</ul>

Software Environment
--------------------

This is a hands-on tutorial with several programming exercises.  We
recommend using the virtual machine we've prepared that has all the
necessary software that you need pre-installed. To run this, you need the
following open source software package applicable for your host computer:

- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

The Frenetic Tutorial VM runs Ubuntu 16.04 as the guest OS.  It has OCaml, OPAM, Mininet, 
Wireshark, and Frenetic itself pre-installed.  The standard VIM, Emacs, and Nano editor packages
are installed, but you can install your own through the normal Ubuntu package mechanisms.

The Frenetic tutorial VM is stored on Amazon Web Services S3 cloud storage, and
installing it requires very little effort. First, launch the VirtualBox GUI on
your Windows, Linux, or Mac OS host PC. Then:

 - Download the Frenetic tutorial VM OVA (Open Virtualization Appliance) located
   [here](https://s3.amazonaws.com/plasma-umass/frenetic-tutorial-vm.ova).
 - Navigate the menus to `File > Import Appliance...`. This will open a modal
   dialog instructing you to import the appliance.
 - Enter the path to the downloaded OVA file, or browse your file manager to
   locate it.
 - Select `Next`.
 - Select `Import`. This imports the OVA file into VirtualBox, and the Frenetic
   VM should now appear in your VirtualBox GUI.
 - Lastly, double click the VM in the VirtualBox GUI to launch the Frenetic
   tutorial VM.

References
----------

- [Real World OCaml](https://realworldocaml.org)

  To write Ox and NetKAT programs, it will be useful to be familiar
  with the OCaml language. Chapters 1--8 and 18 should cover the
  necessary background material.

- [OpenFlow 1.0 Specification](http://www.openflow.org/documents/openflow-spec-v1.0.0.pdf)

  This specification describes OpenFlow switches and configuration
  protocol in detail. You'll find that most of the Ox Platform
  Reference simply reflects the OpenFlow messages and data types into
  OCaml. 

- [Mininet](http://mininet.org/)

  This webpage describes Mininet, a system we will use to run
  controllers on a simulated network of switches.

- [Frenetic OCaml APIs](http://frenetic-lang.github.io/frenetic/index.html)

  This web page provides documentation for the
  [Ox](https://github.com/frenetic-lang/frenetic/blob/master/async/Frenetic_Ox.mli) and
  [NetKAT](http://frenetic-lang.github.io/frenetic/Frenetic_NetKAT.html) libraries, as
  well as other supporting libraries used in this tutorial.


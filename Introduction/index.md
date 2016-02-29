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
necessary software that you need pre-installed.   To run this, you need the
following open source software packages applicable for your host computer:

- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

- [Vagrant](http://www.vagrantup.com/downloads): automates the process of 
  creating, provisioning, starting and stopping VM's.

The Frenetic Tutorial VM runs Ubuntu 14.04 as the guest OS.  It has OCaml, OPAM, Mininet, 
Wireshark, and Frenetic itself pre-installed.  The standard VIM and Nano editor packages
are installed, but you can install your own through the normal Ubuntu package mechanisms.

The Frenetic tutorial VM is stored in the Vagrant cloud, and installing it requires
very little effort.   First start up a command prompt on your Windows, Linux, or Mac
OS host PC.  Then:

- Create a <code>frenetic-tutorial-vm</code> directory and change into it 
- Issue a <code>vagrant init cr396/frenetic-tutorial</code>.  This will create a 
  proper Vagrantfile in the directory.
- Type <code>vagrant up</code>.  This command does the heavy lifting: downloading the
  latest VM, installing it into Virtual Box, and creating the right credentials
- Lastly, type <code>vagrant ssh</code> to login to a command prompt on your VM.  

The output will look something like this:

~~~ bash
$ mkdir frenetic-tutorial-vm
$ cd frenetic-tutorial-vm
~/frenetic-tutorial-vm$ vagrant init cr396/frenetic-tutorial
A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment! Please read
the comments in the Vagrantfile as well as documentation on
`vagrantup.com` for more information on using Vagrant.
~/frenetic-tutorial-vm$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'cr396/frenetic-tutorial' could not be found. Attempting to find and install...

... lots of downloading and text

~/frenetic-tutorial-vm$ vagrant ssh
Welcome to Ubuntu 14.04.2 LTS (GNU/Linux 3.16.0-30-generic x86_64)

 * Documentation:  https://help.ubuntu.com/
Last login: Sun Feb 28 11:57:22 2016 from 10.0.2.2
vagrant@frenetic:~$ 
~~~

To use the VM:

- To start, change into the <code>frenetic-tutorial-vm</code> directory and type <code>vagrant up</code> followed
  by <code>vagrant ssh</code>.
- To stop, simply exit from the Frenetic VM command prompt.  Back at your host command prompt, type <code>vagrant
  halt</code>.  This step is optional - if you forget and shut down your host machine, the Frenetic VM will 
  itself shut down cleanly beforehand.  But halting it will save you some memory and CPU cycles on the host.

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

- [OCaml APIs](http://frenetic-lang.github.io/api)

  This web page provides documentation for the
  [Ox](http://freneti-lang.github.io/api/ox) and
  [NetKAT](http://frenetic-lang.github.io/api/frenetic) libraries, as
  well as other supporting libraries used in this tutorial.


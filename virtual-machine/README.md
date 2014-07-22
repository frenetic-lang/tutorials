About
=====

This script configures the Frenetic tutorial virtual machine. It is meant
to be run as roon on a clean installation of Ubuntu 14.04 **Minimal** for
AMD64 architecture.

Usage
=====

- Setup Ubuntu 14.04 (AMD64) Minimal on VirtualBox and login as root.
  The easiest way to do this is to import this .ova file:

    http://storage.googleapis.com/arjun-umass-disks/ubuntu-minimal.ova

- Run this script as root:

  ```
  wget https://raw.githubusercontent.com/frenetic-lang/tutorials/master/virtual-machine/provision.sh
  bash provision.sh
  ```

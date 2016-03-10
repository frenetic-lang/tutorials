---
layout: main
title: NetKAT Manual
---

The NetKAT Manual is intended as a lightweight reference to the syntax of the
NetKAT domain-specific language.  


NetKAT Syntax
--------------

Types:

```
(* Integers can be either decimal or hexadecimal (with leading 0x *)

<mac-address> ::= xx:xx:xx:xx:xx:xx
<ip-address> ::= xxx.xxx.xxx.xxx
<mask> = 1 ... 32
<masked-ip-address> ::= <ip-address> / <mask>
<switch-id> ::= 64-bit integer
<port-id> ::= 16-bit integer
<vport-id> ::= 64-bit integer
<vfrabric-id> ::= 64-bit integer
<vlan-id> ::= none | 12-bit integer
<tcp-port> ::= 16-bit integer
<vlan-pcp> ::= 16-bit integer
<frame-type> ::= arp (* shorthand for 0x806 *)
               | ip  (* shorthand for 0x800 *)
               | 8-bit integer
<ip-protocol> ::= icmp (* shorthand for 0x01 *)
                | tcp  (* shorthand for 0x06 *)
                | udp  (* shorthand for 0x11 *)
                | 8-bit integer
<location> ::= <switch-id> @ <port-id>
```

Predicates:

```
<pred-atom> ::= ( <pred> )
            | true
            | false
            | switch = <switch-id>
            | port = <port-id>
            | vswitch = <switch-id>
            | vport = <vport-id>
            | vfabric = <vfabric-id>
            | vlan = <vlan-id>
            | vlanPcp = <vlan-pcp>
            | ethTyp = <frame-type>
            | ipProto = <ip-protocol>
            | tcpSrcPort = <tcp-port>
            | tcpDstPort = <tcp-port>
            | ethSrc = <mac-address>
            | ethDst = <mac-address>
            | ip4Src = <masked-ip-address> | <ip-address>
            | ip4Dst = <masked-ip-address> | <ip-address>

<not-pred> ::= <pred-atom>
            | not <not-pred>

<and-pred> ::= <not-pred>
            | <and-pred> and <not-pred>

<or-pred> ::= <and-pred>
           | <or-pred> or <and-pred>

<pred> ::= <or-pred>

```

Policies:

```
<pol-atom> ::= ( <pol> )
           | id
           | drop
           | filter <pred>
           | switch := <switch-id>
           | port := <port-id>
           | vswitch := <switch-id>
           | vport := <vport-id>
           | vfabric := <vfabric-id>
           | vlan := <vlan-id>
           | vlanPcp := <vlan-pcp>
           | ethTyp := <frame-type>
           | ipProto := <ip-protocol>
           | tcpSrcPort := <tcp-port>
           | tcpDstPort := <tcp-port>
           | ethSrc := <mac-address>
           | ethDst := <mac-address>
           | ip4Src := <ip-address>
           | ip4Dst := <ip-address>
           | <location> => <location>
           | <location> =>> <location>

<star-pol> ::= <pol-atom> 
            | <star-pol> *

<seq-pol> ::= <star-pol>
            | <seq-pol> ; <star-pol>

<union-pol> ::= <seq-pol>
              | <union-pol> + <seq-pol>

<cond-pol> ::= <union-pol>
            | if <pred> then <cond-pol> else <cond-pol>

<pol> ::= <cond-pol>

<program> ::= <pol>
```
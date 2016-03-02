---
layout: main
title: Routing with NetKAT
---

In this chapter, we'll use NetKAT to route traffic in a three-switch network.
First, you'll write and test a forwarding policy. Then, you'll use the re-use
firewall you wrote in the last chapter and apply it to this network. In fact,
you'll learn how package your firewall into a reusable module that you can
compose with any other policy. You'll accomplish this using a key feature of
NetKAT: _sequential composition_.

## Topology

You will work with the following tree topology:

![image](../images/topo-tree-2-2.png)

The figure labels hosts, switches, and port numbers. You can create this topology easily with Mininet:

~~~
$ sudo mn --controller=remote --topo=tree,2,2 --mac --arp
~~~
> `tree,2,2` creates a topology of height 2 and fanout 2.
>
> `--arp` populates host arp table so we don't have to
> worry about broadcasting arp packets

### Exercise 1: Forwarding

**[Solution](https://github.com/frenetic-lang/tutorials/blob/master/netkat-tutorial-solutions/Routing1.ml)**

Using NetKAT, write a forwarding policy that connects all hosts to each other. You already know how to do this for a single switch. To write a multi-switch forwarding policy, you can use the `switch = n` predicate as follows:

~~~
<:netkat<
  if switch = 1 then
    (* Policy for Switch 1 *)
    ...
  else if switch = 2 then
    (* Policy for Switch 2 *)
    ...
  else if switch = 3 then
    (* Policy for Switch 3 *)
    ...
  else
    drop
>>
~~~

Save this in a file called `Routing1.ml` and save it in the `netkat-tutorial-solutions` folder.

#### Testing

Compile and start the controller:

~~~
$ ./netkat-build Routing1.d.byte
$ ./Routing1.d.byte
~~~

Then launch Mininet in another:

~~~
$ sudo mn --controller=remote --topo=tree,2,2 --mac --arp
~~~

Then, ensure that all hosts can reach each other:

~~~
mininet> pingall
~~~

## A Reusable Firewall Using Sequential Composition

Now that basic connectivity works, your goal is to apply exactly the same access control policy you built in the
last chapter to this new network. Unfortunately, you cannot simply reuse the firewall in its current form, since it has baked-in the forwarding policy for the one-switch network.

Your firewall policy from the previous chapter probably has the following form: 

~~~
open Frenetic_NetKAT
open Core.Std
open Async.Std
open Forwarding

let firewall =
  if (* traffic allowed *) then
    $forwarding
  else
    drop

~~~

To truly separate the forwarding policy from the firewall policy, you will use NetKAT's _sequential composition_  operator. Sequential composition lets you take any two policies, `P` and `Q`,
and run them in sequence:

~~~
P; Q
~~~

This form of composition is akin to pipes in Unix. You can think of `P; Q` as a way to pipe the packets produced by `P` into the policy `Q`. To achieve complex tasks, you can string a long chain of policies together, `P1; P2; P3; ...` just as you use pipes compose several different Unix programs together.

You've probably used _grep_ and pipes in Linux to filter lines of text. You can similarly use sequential composition to filter packets:

`$firewall; $forwarding`

For this to work, you do need to make one small change to your firewall policy:  replace all occurrences of `$forwarding` with  the special action `id`. The `id` action is the identity function on packets. When you use `id` in a policy, you don't forward it out of a port, but simply leave it unchanged to be processed by the next policy in a sequence.
Hopefully, it is evident that if your firewall only applies `id` and `drop`, then it becomes truly topology-independent.

### Exercise 2: Abstracting the Firewall

**[Solution](https://github.com/frenetic-lang/tutorials/blob/master/netkat-tutorial-solutions/Routing2.ml)**

In this exercise, you'll move the firewall you wrote in the last chapter to its own file, `Firewall.ml` and edit it to just `id` and `drop` packets. Also, you'll remove the main loop. Then you will build a multi-module policy that involves `Firewall.ml` and `Routing2.ml`.

> If you didn't finish the firewall policy, use 
> [this](https://github.com/frenetic-lang/tutorials/blob/master/netkat-tutorial-solutions/Firewall1.ml)
> and if you didn't finish the first routing policy above, use
> [this](https://github.com/frenetic-lang/tutorials/blob/master/netkat-tutorial-solutions/Routing1.ml).

Once you have a firewall policy and a routing policy to start from, continue as follows.

- In `Firewall.ml`, you have (possibly several) occurrences of `$repeater` (i.e., the repeater policy from the previous chapter).  Replace all occurrences of `$repeater` with `id`.

- Copy Routing1.ml to Routing2.ml, and edit `Routing2.ml` to include `Firewall.ml` and compose the firewall and
  the forwarding policy:

  ~~~ ocaml
  ..
  open Firewall

  let forwarding = ...

  let _ =
    let module Controller = Frenetic_NetKAT_Controller.Make in
    Controller.start 6633;
    Controller.update_policy <:netkat< $firewall; $forwarding >>;
    never_returns (Scheduler.go ());
  ~~~

  You should test this policy just as you tested the firewall in the previous chapter.
 

### Extra Credit 

Per the firewall, host `00:00:00:00:00:02` cannot send a packet to port `25` on host `00:00:00:00:00:04`. If host host `00:00:00:00:00:02` attempts to send such a packet, on which switch is that packet dropped? You should be able to answer the question just by reading your policy and inspecting the topology figure above.


{% include api.md %}

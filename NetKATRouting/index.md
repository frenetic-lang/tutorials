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

Using Frenetic, write a forwarding policy that connects all hosts to each other. You already know how to do this for a single switch. To write a multi-switch forwarding policy, you can use the `switch = n` predicate as follows:

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

Change in to the chapter8 directory:
~~~
$ cd Chapter8
~~~
Here, you'll find the template above in `frenetic-tutorial-code/Chapter8/Forwarding.nc`. Fill it in.

#### Testing

Launch Frenetic in a terminal by invoking `Forwarding.nc`:

~~~
$ frenetic Forwarding.nc
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

Your policy from [Chapter 7][Ch7] probably has this shape:

~~~
let forwarding = (* forwarding for 1 switch only *)

let firewall =
  if (* traffic allowed *) then
    forwarding
  else
    drop

firewall
~~~

To truly separate the forwarding policy from the firewall policy, you will use Frenetic's _sequential composition_  operator. Sequential composition lets you take any two policies, `P` and `Q`,
and run them in sequence:

~~~
P; Q
~~~

This form of composition is akin to pipes in Unix. You can think of `P; Q` as a way to pipe the packets produced by `P` into the policy `Q`. To achieve complex tasks, you can string a long chain of policies together, `P1; P2; P3; ...` just as you use pipes compose several different Unix programs together.

You've probably used _grep_ and pipes in Linux to filter lines of text. You can similarly use sequential composition to filter packets:

`firewall; forwarding`

For this to work, you do need to make one small change to `firewall`:  replace all occurrences of `forwarding` with  the special action `pass`. The `pass` action is the identity function on packets. When you use `pass` in a policy, you don't forward it out of a port, but simply leave it unchanged to be processed by the next policy in a sequence.
Hopefully, it is evident that if your firewall only applies `pass` and `drop`, then it becomes truly topology-independent.

### Exercise 2: Abstracting the Firewall

In this exercise, you'll move the firewall you wrote in the last chapter to its own file, `Firewall.nc` and edit it to just `pass` and `drop` packets.  Then you will build a multi-module policy that involves `Firewall.nc`, `Forwarding.nc` and `Main.nc`.

> If you didn't finish Chapter 8, use
> `frenetic-tutorial-code/Sol_Chapter7_Firewall.nc`.
> If you didn't finish the forwarding policy above, see
> `frenetic-tutorial-code/Chapter8/Sol_Forwarding.nc`.

Once you have a firewall policy and a forwarding policy to start from, continue as follows.

- Move the code for `firewall` function from `Chapter7.nc` in to `Chapter8/Firewall.nc`.

- In `firewall`, you have (possibly several) occurrences of `forwarding` (i.e., the forwarding policy from Chapter 7).  Replace all occurrences of `forwarding` with `pass`.

- Edit `Forwarding.nc` to include `Firewall.nc` and compose the firewall and
  the forwarding policy:

  ~~~
  include "Firewall.nc"

  let forwarding = ...

  firewall; forwarding
  ~~~

  You should test this policy just as you tested the firewall in
  [Chapter 7][Ch7].

### Extra Credit I

Per the firewall, host `00:00:00:00:00:02` cannot send a packet to port `25` on host `00:00:00:00:00:04`. If host host `00:00:00:00:00:02` attempts to send such a packet, on which switch is that packet dropped? You should be able to answer the question just by reading your policy and inspecting the topology figure above.

### Extra Credit II

Show that your firewall in `Firewall.nc` is truly reuseable.  Reimplement your solution in `Chapter7.nc` in a modular fashion using `Firewall.nc`. You may start with `Sol_Chapter7.nc` if you wish.

{% include api.md %}
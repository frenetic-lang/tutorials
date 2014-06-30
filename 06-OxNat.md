Chapter 6: Network Address Translator
==========================

In this exercise, you will build a Network Address Translator by first writing and testing a translator function that first translates IP addresses and then extending it so that it translates port numbers as well.

### The Network Address Translating Function

In the 1990s, the explosive growth of the internet created a demand for IP address space. Before NAT was invented, all IP addresses were globally unique. NAT allows private IP addresses to be reused in multiple local area networks (LAN) by translating all private IP addresses in a LAN to one globally unique public IP address. NAT essentially does the following:

* For packets received on private (internal) ports, NAT rewrites the private IP address to the public IP address and installs rules to forward the packet to the public port.
    * NAT will also store relevant information for each packet in a data structure, such as a hashtable. 
* For packets received on the public (external) port, NAT checks to see if the TCP port destination of     
  the packet matches the TCP port source of any of the packets stored in the data structure.
    * If so, the public IP address of the packet is rewritten to the corresponding private IP address and          
      rules are installed to forward the packet to the correct private port. 
    * If not, the packet is simply dropped.
 
#### Programming Task

You should use the template below to get started. Save it in a file called `Nat1.ml` and place it in the directory `~/src/frenetic/ox-tutorial-workspace/Nat1.ml`.

#### Compiling and Testing 

These tests will ensure that TCP packets are being sent and received to the correct hosts and addresses are translated correctly. 

 * Build and launch the controller:

  ```shell
  $ make Nat1.d.byte
  $ ./Nat1.d.byte
  ```

 * In a separate terminal window, start Mininet:

  ```shell
  $ sudo mn --controller=remote --topo=single,3 --mac
  ```

We will be using a topology that consists of two internal hosts and one external host connected by a switch.

 * In Mininet, start new terminals for h1, h2, and h3:

  ```
  mininet> xterm h1 h2 h3
  ```

 * In the terminal for h3, add static entries into the arp table and start a fortune server.

  ```shell
  # arp -v -s [public IP address] [public MAC address]
  # while true; do fortune | nc -l 80; done
  ```
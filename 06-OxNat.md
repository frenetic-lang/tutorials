## Chapter 6: Network Address Translator

In this exercise, you will build a Network Address Translator by first writing and testing a translator function that first translates IP addresses and then extending it so that it translates port numbers as well.

### **The Network Address Translating Function**

In the 1990s, the explosive growth of the internet created a demand for IP address space. Before NAT was invented, all IP addresses were globally unique. NAT allows private IP addresses to be reused in multiple local area networks (LAN) by translating all private IP addresses in a LAN to one globally unique public IP address. NAT essentially does the following:

* For packets received on private (internal) ports, NAT rewrites the private IP address to the public IP address and installs rules to forward the packet to the public port.
      * NAT will also store relevant information for each packet in a data structure, such as a hashtable. 
* For packets received on the public (external) port, NAT checks to see if the TCP port destination of     
  the packet matches the TCP port source of any of the packets stored in the data structure.
     

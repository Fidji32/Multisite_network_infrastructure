
# 🏢 Multisite network infrastructure

This project, carried out in a team of 4 during my graduate studies, includes the scripts for setting up the network infrastructure as well as the scripts for setting up services on the servers in the network.

Here is a diagram that summarises the entire infrastructure :
![topology](https://github.com/Fidji32/Multisite_network_infrastructure/blob/main/topologyDMZ.excalidraw.png)

## Routing

In terms of routing, we have implemented the OSPF protocol for sites that are geographically close and BGP to connect to the remote site. The WAN also uses MPLS so that we can share WAN routers with other companies without jeopardising our security. Finally, to distinguish between the company's different workstations, we have set up VLANs to secure communications and distinguish between each 'role'. 
Don't forget that the entire network is available in IPv4 and IPv6.

## Services

In terms of services, we have set up a DHCP server throughout the network that manages both IPv4 and IPv6. We also configured a DHCP server and a web server to allow the "company" to set up its private website.

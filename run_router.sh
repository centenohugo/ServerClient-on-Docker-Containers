#!/bin/bash

# Define network names and router container
SERVER_NETWORK="server_network"
CLIENT_NETWORK="client_network"
ROUTER_CONTAINER="router"

# Router IPs
ROUTER_IP_ETH0="192.168.16.100"
ROUTER_IP_ETH1="192.168.32.100"

# Create both client and server networks
docker network create --subnet=192.168.16.0/24 $SERVER_NETWORK
docker network create --subnet=192.168.32.0/24 $CLIENT_NETWORK

# Run the router container with both network connections, ubuntu image and with privileges
docker run -dit --name $ROUTER_CONTAINER \
  --net $SERVER_NETWORK --ip $ROUTER_IP_ETH0 \
  --privileged ubuntu

#Connect the router to CLIENT_NETWORK
docker network connect --ip $ROUTER_IP_ETH1 $CLIENT_NETWORK $ROUTER_CONTAINER

#small delay waiting for the iface to be available
sleep 2

#Install iproute2
docker exec -it $ROUTER_CONTAINER bash -c "
  apt update && apt install -y iproute2
"

# Enable IP forwarding inside the router container
docker exec -it $ROUTER_CONTAINER sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

#Indicate how to forward packages
ip route add 192.168.16.0/24 via 192.168.16.100 dev eth0
ip route add 192.168.32.0/24 via 192.168.32.100 dev eth1

echo "Router is running and forwarding packets between $SERVER_NETWORK and $CLIENT_NETWORK!"
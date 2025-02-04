#!/bin/bash

# Define network, volume, and container names
CLIENT_NETWORK="client_network"
CLIENT_VOLUME="client_persistent_storage"
CLIENT_CONTAINER="client_container"
IMAGE_NAME="client_image"

# Define server connection details
CLIENT_IP="192.168.32.2"
ROUTER_IP_ETH1="192.168.32.100"

# Create the persistent volume for the client
docker volume create $CLIENT_VOLUME

# Build the client image
docker build -t $IMAGE_NAME .

# Run the server container with privileges to allow routing
docker run -dit --name $CLIENT_CONTAINER \
  --net $CLIENT_NETWORK \
  --ip $CLIENT_IP \
  -v $CLIENT_VOLUME:/client_storage \
  --cap-add=NET_ADMIN \
  $IMAGE_NAME

# Add routing to server network (via router)
docker exec -it $CLIENT_CONTAINER ip route add 192.168.16.0/24 via $ROUTER_IP_ETH1
docker exec -it $CLIENT_CONTAINER python client.py

echo "Client has finished file transfer from the server!"
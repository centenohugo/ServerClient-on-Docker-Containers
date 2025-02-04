#!/bin/bash

# Define network, volume, and container names
SERVER_NETWORK="server_network"
SERVER_VOLUME="server_persistent_storage"
SERVER_CONTAINER="server_container"
IMAGE_NAME="server_image"

# Define server details
SERVER_IP="192.168.16.2"
SERVER_PORT=5000

# Create the persistent volume for the server
docker volume create $SERVER_VOLUME

# Build the server image
docker build -t $IMAGE_NAME .

# Run the server container with privileges to allow routing
docker run -dit --name $SERVER_CONTAINER \
  --net $SERVER_NETWORK \
  --ip $SERVER_IP \
  -p $SERVER_PORT:$SERVER_PORT \
  -v $SERVER_VOLUME:/server_storage \
  --cap-add=NET_ADMIN \
  $IMAGE_NAME

# Add routing to client network (via router)
docker exec -it $SERVER_CONTAINER ip route add 192.168.32.0/24 via 192.168.16.100

echo "Server is running on $SERVER_IP and port $SERVER_PORT"

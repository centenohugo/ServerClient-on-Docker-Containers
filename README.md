﻿### Document by Hugo Centeno Sanz
## Breakdown of the approach followed
The problem was resolved by using an architecture composed of two networks and three containers:

* ```client_network``` where ``client_container`` runs. 
* ```server_network``` where
```server_container``` runs.

As it happens with Docker networks, they are isolated. Therefore, communication
between these two networks was achieved by adding a third container: ```router```. This container
has two interfaces, one which belongs to ```server_network``` and the other one belonging to ```client_network```.

![NetworkDiagram](networkDiagram.drawio.png)


## Steps to follow

### 1- Setup the experiment on CloudLab
The experiment was initialized using one machine with Ubuntu 20.04 software.

In the VM Docker had to be installed.

Run the command Docker documentation provides for the installation.
https://docs.docker.com/engine/install/
```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
### 2- Create the Docker networks
```
docker network create --subnet=192.168.16.0/24 server_network
docker network create --subnet=192.168.32.0/24 client_network
```

### 3- Build the router container
The router will use the ubuntu image, available in DockerHub.

We'll first connect the router container to the ```server_network```and assign and IP address to its interface ``eth0``. Privileges will be assigned to latter allow iptables configuring.
```
docker run -dit --name router \
--net server_network --ip 192.168.16.100 \
--privileged ubuntu
```
We'll connect the router to ```client_network``` on eth1.
```
docker network connect --ip 192.168.32.100 client_network router
```
So far we have defined two networks and the router container which has 2 interfaces, one for each network. However, until we configure the routing, each interface is not aware of the existance of the other and does not know how to redirect the packets.
### 4- Create the routing tables
As we are using simple ubuntu images iproute 2 installations need to be done prior using ``ip`` command
```
docker exec -it $ROUTER_CONTAINER bash -c "
  apt update && apt install -y iproute2
"
```
Define the routing tables.
```
ip route add 192.168.16.0/24 via 192.168.16.100 dev eth0
ip route add 192.168.32.0/24 via 192.168.32.100 dev eth1
```
 ### 5- Build up the container for the server
 We'll first create the image. The Dockerfile defining the image is the following:
 ```
 #Base image to use. We'll use the version running on the Host VM
FROM python:3.8.10
#Define which will be the working directory in the docker
WORKDIR /server_storage/
#Copy the files on the host to the docker
ADD mydata.txt server.py /server_storage/
#Open the port where the server will listen
EXPOSE 5000
#execute the command to start the server
CMD [ "python3", "/server_storage/server.py" ]
 ```
 Build the image and run the server container in privileged mode.
 Important to note that when running the server container, we need to match the port 5000 of the container with the port 5000 of the server.
 ```
docker build -t server_image .

docker run -dit --name server_container \
  --net server_network \
  --ip 192.168.16.2 \
  -p 5000:5000 \
  -v server_persistent_storage:/server_storage \
  --cap-add=NET_ADMIN \
  server_image
 ```
 Define in the server that the gateway for addresses belonging to ```client_network``` is via eth0 of the router.
 ```
 docker exec -it server_container ip route add 192.168.32.0/24 via 192.168.16.100
 ```
 ### 6- Build up the container for the client
 The Dockerfile defining the image is the following. Note that we'll run bash when building the container, this is done this way to keep the container running until the routings are done. Once the routing is set, running ```client.py``` won't exit with error, as the server will be reachable.
 ```
 #Base image to use. We'll use the version running on the Host VM
FROM python:3.8.10
#Define which will be the working directory in the docker
WORKDIR /client_storage/
#Copy the files on the host to the docker
ADD client.py /client_storage/
#execute the command to start the server. Bash executed to avoid stopping the container when routing table is 
#still being set
CMD [ "bash" ]
 ```
 Build the image and run the client container in privileged mode.

 ```
docker build -t client_image .

docker run -dit --name client_container \
  --net client_network \
  --ip 192.168.32.2\
  -v client_persistent_storage:/client_storage \
  --cap-add=NET_ADMIN \
  client_image
 ```
Define in the server container taht the getaway for the addresses belonging to ```server_network``` is via eth1 of the router.
```
docker exec -it client_container ip route add 192.168.16.0/24 via 192.168.32.100
```
Run ```client.py```.
```
docker exec -it client_container python client.py
```
### 7- Checking integrity of the file sent
Execute in the server container:
```
md5sum mydata.txt

#Output
59ca0efa9f5633cb0371bbc0355478d8  mydata.txt
```
Execute in the client container:
```
md5sum mydata_client_copy.txt 

#Output
59ca0efa9f5633cb0371bbc0355478d8  mydata_client_copy.txt
```
## Files in the repo
The order for executing the .sh files is: ```run_router.sh```, ```
run_server.sh```, ```run_client.sh```.

Check for possible changes on local variables.

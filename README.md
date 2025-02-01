### Document by Hugo Centeno Sanz
## Steps followed to do Assignment 2

### 1- Setup the experiment on Cloud Lab and the environment:
The experiment was initialized using only one machine, running Ubuntu 20.04

I ssh into the machine and downloaded Docker

```
ssh -p 26010 hcent001@amd225.utah.cloudlab.us
```
Run the command the Docker documentation provides to install Docker
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
 ### 2- Create the server image
 We first create a volume inside the machine named server_persistent_storage. Inside this volume we create the mydata.txt file and copy the file server.py.
 
 ```
 mkdir server_persistent_storage
 echo "Hello world!" > server_persistent_storage/mydata.txt
 cp /path/to/server.py /path/to/server_persistent_storage

 ```
In ```/server_persistent_storage``` we create the image defining the server container. This file is a Dockerfile.
 ```
#Base image to use. We'll use the version running on the Host VM
FROM python:3.8.10
#Define which will be the working directory in the docker
WORKDIR /server_storage/
#Copy the files on the host to the docker
ADD server_persistent_storage/ /server_storage/
#execute the command to start the server
CMD [ "python3", "/server_storage/server.py" ]
#Open the port where the server will listen
EXPOSE 5000
```
### 3- Create the client image
 We first create a volume inside the machine named client_persistent_storage. Inside this volume we copy the file client.py.
 ```
 mkdir client_persisent_storage
cp /path/to/client.py /path/to/client_persistent_storage
 ```
 In ```/client_persistent_storage``` we create the image defining the client container. This file is a Dockerfile.
```
#Base image to use. We'll use the version running on the Host VM
FROM python:3.8.10
#Define which will be the working directory in the docker
WORKDIR /client_storage/
#Copy the files on the host to the docker
ADD client_persistent_storage/ /client_storage/
#execute the command to start the server
CMD [ "python3", "/client_storage/client.py" ]
#Open the port where the server is listening
EXPOSE 5000
```
### 4- Creating the networks
We want each container to run on a network so we'll create two user-defined bridge networks. Initially, these networks will be isolated
```
docker network create server_network
docker network create client_network
```
### 5- Connecting the networks
Right now the client can not reach the server as the networks are isolated. We will connect them via iptables.

We will first get the network subnets
```
docker network inspect server_network | grep Subnet
docker network inspect client_network | grep Subnet
```
We now allow TCP packages from ```client_network``` to ```server_network``` and viceversa on PORT 5000.
```
iptables -I DOCKER-USER -s clientsubnet -d serversubnet -p tcp --dport 5000 -j ACCEPT

iptables -I DOCKER-USER -s serversubnet -d clientsubnet -p tcp --dport 5000 -j ACCEPT
```
### 6- Launch the client/server container on its corresponding network
The server container will be launched in the ```server_network```, it will mount the folder ```server_persistent_storage``` and it will be named as ```server_image```.
```
docker run -d --name server_container \
    --network server_network \
    -v "$(pwd)/server_persistent_storage:/server_storage" \
    -e SERVER_PORT=5000 \
    server_image

```
and the client container in the ```client_network```
```
docker run -d --name client_container \
    --network client_network \
    -e SERVER_IP="serversubnet" \
    -e SERVER_PORT=5000 \
    -v "$(pwd)/client_persistent_storage:/client_storage" \
    client_image
```

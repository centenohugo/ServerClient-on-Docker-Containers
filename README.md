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
 We first create a volume inside the machine named server_persistent_storage. Inside this volume we create the mydata.txt file and copy the file server.py from our local machine.
 
 ```
 mkdir server_persistent_storage
 echo "Hello world!" > server_persistent_storage/mydata.txt
 ```
 We first create the image for the server docker in a Dockerfile:
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
now we run the container on port 5000.
```
docker run -d -p 5000:5000 --name server server
```
### 3- Create the client image
 We first create a volume inside the machine named client_persistent_storage. Inside this volume we copy the file client.py from our local machine.
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
run the image
``` 
docker build -t client .
```
now we run the container
```

```

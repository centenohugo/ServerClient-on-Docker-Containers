#Base image to use. We'll use the version running on the Host VM
FROM python:3.8.10
#Define which will be the working directory in the docker
WORKDIR /client_storage/
#Copy the files on the host to the docker
ADD client.py /client_storage/
#Bash executed to avoid stopping the container when routing table is 
#still being set
CMD [ "bash" ]


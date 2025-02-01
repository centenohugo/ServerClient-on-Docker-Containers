#Base image to use. We'll use the version running on the Host VM
FROM python:3.8.10
#Define which will be the working directory in the docker
WORKDIR /server_storage/
#Copy the files on the host to the docker
ADD mydata.txt server.py /server_storage/
#Opent the port where the server will listen
EXPOSE 5000
#execute the command to start the server
CMD [ "python3", "/server_storage/server.py" ]

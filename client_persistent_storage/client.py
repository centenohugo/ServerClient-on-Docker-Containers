import socket
import os

# Client configuration
SERVER_HOST = "192.168.16.2"
SERVER_PORT = 5000

# File to save the received data
SAVE_FILE_NAME = 'mydata_client_copy.txt'

# Set up the client socket
client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client_socket.connect((SERVER_HOST, SERVER_PORT))
print(f"Connected to server at {SERVER_HOST}:{SERVER_PORT}")

# Receive the file size from the server
file_size = int(client_socket.recv(1024).decode('utf-8'))
client_socket.sendall(b"ACK")  # Acknowledge the file size

# Receive the file content
received_data = b""
while len(received_data) < file_size:
    chunk = client_socket.recv(1024)
    if not chunk:
        break
    received_data += chunk

# Save the received data to a file
with open(SAVE_FILE_NAME, 'wb') as file:
    file.write(received_data)

print(f"File received and saved as '{SAVE_FILE_NAME}'")
client_socket.close()

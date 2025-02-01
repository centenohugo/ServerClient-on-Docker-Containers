import socket

# Server configuration
HOST = '0.0.0.0'  # Listen on all interfaces
PORT = 5000       # Port to bind to

# File to be shared
FILE_NAME = 'mydata.txt'

# Set up the server socket
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_socket.bind((HOST, PORT))
server_socket.listen(1)  # Listen for one connection
print(f"Server is listening on port {PORT}")

while True:
    # Accept client connection
    client_socket, client_address = server_socket.accept()
    print(f"Connection established with {client_address}")

    try:
        # Open and read the file
        with open(FILE_NAME, 'rb') as file:
            data = file.read()

        # Send the file size to the client
        client_socket.sendall(f"{len(data)}".encode('utf-8'))
        client_socket.recv(1024)  # Wait for the client's acknowledgment

        # Send the file content
        client_socket.sendall(data)
        print(f"File '{FILE_NAME}' sent to the client.")
    except FileNotFoundError:
        print(f"Error: File '{FILE_NAME}' not found.")
        client_socket.sendall(b"ERROR: File not found.")
    finally:
        client_socket.close()

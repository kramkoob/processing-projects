#!/usr/bin/python3

# Echo server program
import socket

HOST = '' # Symbolic name meaning all available interfaces
PORT = 12345  # Arbitrary non-privileged port
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
	s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
	s.bind((HOST, PORT))
	s.listen(1)
	conn, addr = s.accept()
	with conn:
		print('Connected by', addr)
		width, height = [int(v) for v in conn.recv(1024).decode("utf-8").split(' ')]
		print('They are', width, 'by', height)
		while True:
			data = conn.recv(1024)
			if not data: break
			datastr = data.decode("utf-8")
			pos = [int(v) for v in datastr[:(datastr.find('\n'))].split(" ")]
			pos[0] = width - pos[0]
			pos[2] = width - pos[2]
			pos[1] = height - pos[1]
			pos[3] = height - pos[3]
			sendbytes = bytes(' '.join([str(v) for v in pos]) + '\n', 'utf-8')
			conn.sendall(sendbytes)

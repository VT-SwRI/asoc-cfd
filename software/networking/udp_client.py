import os
import socket


class UDPClient:

    def __init__(self):
        ip = os.environ.get("FPGA_IP")
        port = os.environ.get("FPGA_PORT")

        if ip is None or port is None:
            raise RuntimeError(
                "FPGA_IP and FPGA_PORT must be set. "
                "Run: source scripts/env.sh"
            )

        self.server_addr = (ip, int(port))

        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.settimeout(1.0) #modify as needed

    def send(self, data: bytes):
        self.sock.sendto(data, self.server_addr)

    def receive(self):
        try:
            data, _ = self.sock.recvfrom(1024)
            return data
        except socket.timeout:
            return None

    def close(self):
        self.sock.close()
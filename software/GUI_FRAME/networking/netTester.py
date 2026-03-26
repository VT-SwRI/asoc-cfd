import numpy as np
from PyQt5.QtCore import QObject
from PyQt5 import QtNetwork
import struct
import time
import ipaddress

def generate_spiral_hits(
    center_x=0,
    center_y=0,
    max_radius=40,
    n_points=20000,
    det_min=-50,
    det_max=50,
):
    """Generate a spiral of (x, y) hit coordinates in detector space."""
    t = np.linspace(0, 8 * np.pi, n_points)
    r = np.linspace(0, max_radius, n_points)
    x = center_x + r * np.cos(t)
    y = center_y + r * np.sin(t)

    mask = (x >= det_min) & (x <= det_max) & (y >= det_min) & (y <= det_max)
    return x[mask], y[mask]


def main():
    t = np.dtype([
        ('xpos', 'f4'),
        ('ypos', 'f4'),
        ('time', 'f8'),
        ('magnitude', 'f4')
    ])
    # Create one structured record
    data = np.array([(1.5, 2.5, 12345.6789, 42.0)], dtype=t)

    # Convert to raw bytes
    payload = data.tobytes()

    socket = QtNetwork.QUdpSocket()
    # while True:
    refTime = time.time()
    x, y = generate_spiral_hits()
    # for i in range(len(x)):
    #     data = np.array([(2.5, 2.5, 12345.6789, 42.0)], dtype=t)
    #     payload = struct.pack("!HHfdff", 1, 1, data[0][3], data[0][2], x[i], y[i])  
    #     socket.writeDatagram(payload, QtNetwork.QHostAddress("127.0.0.1"), 562)
    # done = time.time()

    # eps = len(x) / (done - refTime)
    # print(eps)


    # for i in range(1):
    #     data = np.array([(2.5, 2.5, 12345.6789, 42.0)], dtype=t)
    #     payload = struct.pack("!HHfdff", 1, 1, data[0][3], data[0][2], -25, -25)  
    #     socket.writeDatagram(payload, QtNetwork.QHostAddress("127.0.0.1"), 562)
    # r = 1/30
    # t = time.time()
    # x = time.time()

    print(ipaddress.ip_address("999.999.999.999"))







if __name__ == "__main__":
    main()
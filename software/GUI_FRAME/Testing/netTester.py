import numpy as np
from PyQt5.QtCore import QObject
from PyQt5 import QtNetwork
import struct
import time
import ipaddress
import serial

def generate_spiral_hits(
    center_x=0,
    center_y=0,
    max_radius=40000,
    n_points=20000,
    det_min=-51000,
    det_max=51000,
):
    """Generate a spiral of (x, y) hit coordinates in detector space."""
    t = np.linspace(0, 8 * np.pi, n_points)
    r = np.linspace(0, max_radius, n_points)
    x = center_x + r * np.cos(t)
    y = center_y + r * np.sin(t)

    mask = (x >= det_min) & (x <= det_max) & (y >= det_min) & (y <= det_max)
    return x[mask], y[mask]


def ethernet():
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
    rng = np.random.default_rng()
    while True:
        for i in range(len(x)):
            data = np.array([(2.5, 2.5, 12345.6789, 42.0)], dtype=t)

            payload = struct.pack("!HHfdff", 1, 1,  np.random.normal(0, 5000), data[0][2], x[i], y[i])  
            socket.writeDatagram(payload, QtNetwork.QHostAddress("127.0.0.1"), 5611)
    done = time.time()

    # eps = len(x) / (done - refTime)
    # print(eps)


    # for i in range(100):
    #     data = np.array([(2.5, 2.5, 12345.6789, 42.0)], dtype=t)
    #     payload = struct.pack("!HHfdff", 1, 1, 00, data[0][2], -25000, -25000)  
    #     socket.writeDatagram(payload, QtNetwork.QHostAddress("127.0.0.1"), 562)
    # r = 1/30
    # t = time.time()
    # x = time.time()


def fixed_to_float(num, Qint, Qfrac, sgn):
    len = Qint + Qfrac + (1 if sgn else 0)

    num &= (1 << len) - 1

    if sgn:
        if num & (1 << (len - 1)):
            num -= (1 << len)

    Q = 1 << Qfrac
    return float(num) / float(Q)

def float_to_fixed(num, Qint, Qfrac, sgn):
    Q = 1 << Qfrac
    val = qRound(num * Q)
    len = Qint + Qfrac + (1 if sgn else 0)
    if sgn:
        min_val = -(1 << (len - 1))
        max_val = (1 << (len - 1)) - 1
    else:
        min_val = 0
        max_val = (1 << len) - 1
    
    val = max(min_val, min(max_val, val))
    return val

def qRound(num):
    return int(np.floor(num + 0.5)) if num >= 0 else int(np.ceil(num - 0.5))

def sendStart(frac, delay, thresh, zc, kx, ky, time, ser):
    fracQ = int(float_to_fixed(frac, 0, 13, True))
    delayQ = int(delay)
    threshQ = int(float_to_fixed(thresh, 12, 3, True))
    kxQ = int(float_to_fixed(kx, 1, 19, False))
    kyQ = int(float_to_fixed(ky, 1, 19, False))
    zcQ = int(zc)

    packet = 0

    packet |= (time & 0xFFFFFFFFFFFFFFFF) << 0
    packet |= (kyQ & 0xFFFFF) << 64
    packet |= (kxQ & 0xFFFFF) << 84
    packet |= (zcQ & 0xFF) << 104
    packet |= (threshQ & 0xFFFF) << 112
    packet |= (delayQ & 0x7F) << 128
    packet |= (fracQ & 0x3FFF) << 135

    packBytes = packet.to_bytes(19, byteorder = 'big')
    print(packBytes)
    ser.write(packBytes)

def main():
    zc = 100
    zc = np.uint8(zc)
    # print(time.time_ns() // 1000)
    ser = serial.Serial(port = 'COM3', baudrate=9600, timeout=1)
    # while True:
    sendStart(0, 3  , 0, 0, 0, 0, 0, ser)
        # data = ser.read(19)
        # if len(data) == 19:
        #     print(list(data))



if __name__ == "__main__":
    main()
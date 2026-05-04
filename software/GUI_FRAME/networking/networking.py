import numpy as np
from PyQt5.QtCore import QObject, pyqtSignal
from PyQt5 import QtNetwork
from PyQt5 import QtCore, QtNetwork
import struct
import socket
import threading
import queue
import serial
import time

DEBUG = 0
PORT = 'COM4'
BR = 115200

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


class RxWorker(QtCore.QObject):
    done = QtCore.pyqtSignal()
    
    def __init__(self, q, com, br=9600):
        super().__init__()
        self.com = com
        self.baudRate = br
        self.queue = q
        self.buff_size = 100000
        self.pack_len = 18
        
        self.socket = None
        self.ser = None
        self.mode = None
        self.running = False
        self.count = None
        self.thread = None

    @QtCore.pyqtSlot()
    def start(self, frac, delay, thresh, zc, kx, ky, mode):
        self.running = True

        self.refTime = time.time()
        self.count = 0
        self.ser = serial.Serial(port=self.com, baudrate=self.baudRate)
        self.mode = mode
        self.sendStartStop(frac, delay, thresh, zc, kx, ky, mode, 1)

        self.thread = threading.Thread(target = self.recvLoop, daemon=True)
        self.thread.start()

    def recvLoop(self):
        while self.running:
            try:
                data = self.ser.read(self.pack_len)
                if len(data) == self.pack_len:
                    try:
                        self.queue.put_nowait(data)
                    except queue.Full:
                        print("Dropped packets!!")
                        pass
            except self.ser.SerialException as e:
                print(f"UART Error: {e}")
                break
            except Exception as e:
                print(f"Error: {e}")
                break
    
    @QtCore.pyqtSlot()
    def stop(self):
        if not self.running:
            return
        
        self.running = False
        self.sendStartStop(0, 0, 0, 0, 0, 0, self.mode, 0)
        
        if self.ser:

            try:
                self.ser.flush()
            except Exception:
                pass
            try:

                self.ser.close()
            except Exception:
                pass
            self.ser = None
        if self.thread:
            self.thread.join()
        self.done.emit()
        if DEBUG:
            print("\nRx Disconnected successfully")
    
    @QtCore.pyqtSlot(int, int, int, int, int, float, float)
    def sendStartStop(self, frac, delay, thresh, zc, kx, ky, mode, s):
        t = time.time_ns() // 1000
        fracQ = int(float_to_fixed(frac, 0, 13, True))
        delayQ = int(delay)
        threshQ = int(float_to_fixed(thresh, 12, 3, True))
        kxQ = int(float_to_fixed(kx, 1, 19, False))
        kyQ = int(float_to_fixed(ky, 1, 19, False))
        zcQ = int(zc)
        timeQ = int(t)

        packet = 0

        packet |= (timeQ & 0xFFFFFFFFFFFFFFFF) << 0
        packet |= (kyQ & 0xFFFFF) << 64
        packet |= (kxQ & 0xFFFFF) << 84
        packet |= (zcQ & 0xFF) << 104
        packet |= (threshQ & 0xFFFF) << 112
        packet |= (delayQ & 0x7F) << 128
        packet |= (fracQ & 0x3FFF) << 135
        packet |= (mode & 0x1) << 149
        packet |= (s & 0x1) << 150

        packBytes = packet.to_bytes(19, byteorder = 'big')
        self.ser.write(packBytes)
        if s == 1 and DEBUG:
            print(f"Start packet: {packBytes.hex(' ')}")
        if s == 0 and DEBUG:
            print(f"Stop packet: {packBytes.hex(' ')}")
class DecWorker(QtCore.QObject):
    batch_ready = QtCore.pyqtSignal(object)
    pulse = QtCore.pyqtSignal(object)

    def __init__(self, q, type, mode):
        super().__init__()
        self.mode = mode
        self.queue = q
        self.batch_size = 20000
        self.refresh = 1 / 30
        self.running = False
        self.thread = None
        self.inType = type
        self.packetType = np.dtype([ ('type', '>u2'), ('valid', '>u2'), ('mag', '>f4'), ('t', '>f8'), ('x', '>f4'), ('y', '>f4')])
    
    def start(self):
        self.running = True
        self.thread = threading.Thread(target=self.decodeLoop, daemon=True)
        self.thread.start()

    def decodeLoop(self):
        lBuffer = []
        refTime = time.time()

        while self.running:
            try:
                data = self.queue.get(timeout = 0.01)
            except queue.Empty:
                data = None

            if data is not None and self.mode < 2:
                print(data.hex(' ').upper())

                t   = int.from_bytes(data[0:8],  byteorder='big', signed=False)
                x   = int.from_bytes(data[8:12],  byteorder='big', signed=True)
                y   = int.from_bytes(data[12:16], byteorder='big', signed=True)
                mag = int.from_bytes(data[16:18], byteorder='big', signed=True)


                lBuffer.append((x, y, t, mag))
                if DEBUG:
                    print(f"Raw Hex: {data.hex(' ').upper()}")
                    print(f"  tag : {t}")
                    print(f"  x   : {x}")
                    print(f"  y   : {y}")
                    print(f"  mag : {mag}")
            elif data is not None and self.mode == 2:
                arr = np.frombuffer(data[1:], dtype=np.float64)
                self.pulse.emit(arr)
        
            if (lBuffer and (time.time() - refTime) >= self.refresh) or len(lBuffer) >= self.batch_size:
                batch = np.array(lBuffer, dtype = self.inType)
                lBuffer.clear()
                self.batch_ready.emit(batch)
                refTime = time.time()
        if lBuffer:
            batch = np.array(lBuffer, dtype = self.inType)
            self.batch_ready.emit(batch)
    
    def stop(self):
        self.running = False

        if self.thread:
            self.thread.join()

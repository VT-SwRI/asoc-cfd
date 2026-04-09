import numpy as np
from PyQt5.QtCore import QObject, pyqtSignal
from PyQt5 import QtNetwork

from PyQt5 import QtCore, QtNetwork
import struct
import socket
import threading
import queue
import time

DEBUG = 0
def fixed_to_float(num, Q):
    return float(num) / float(Q)

def float_to_fixed(num, Q):
    return np.int64(round(num * Q))

class TxWorker(QtCore.QObject):
    
    done = QtCore.pyqtSignal()
    error = QtCore.pyqtSignal(str)

    def __init__(self, ip, port=5000):
        super().__init__()
        self.port = port
        self.ip = ip
        self.socket = None

    @QtCore.pyqtSlot()
    def start(self):
        self.running = True
        self.socket = QtNetwork.QUdpSocket()
        
    @QtCore.pyqtSlot()
    def stop(self):
        self.sendStop()
        self.running = False
        if self.socket:
            self.socket.close()
            self.socket.deleteLater()
            self.socket = None

        self.done.emit()
        if DEBUG:
            print("\nTx Disconnected successfully")
    
    @QtCore.pyqtSlot(int, int, int, int, int, float, float)
    def sendStart(self, sel, mode, time, thresh, delay, frac, fs):
        header = struct.pack("!HHH", 0, sel, mode)
  
        payload = struct.pack("!IIfIf", time, delay, frac, thresh, fs)

        payload = payload.ljust(32, b'\x00')
        pck = header + payload

        self.socket.writeDatagram(pck, QtNetwork.QHostAddress(self.ip), self.port)

        if DEBUG:
            print("\nStart packet sent")
    
    @QtCore.pyqtSlot()
    def sendStop(self):
        header = struct.pack("!HHH", 0, 0, 2)
        payload = struct.pack("!I", 0)
        payload = payload.ljust(32, b'\x00')
        pck = header + payload

        self.socket.writeDatagram(pck, QtNetwork.QHostAddress(self.ip), self.port)


class RxWorker(QtCore.QObject):
    done = QtCore.pyqtSignal()
    
    def __init__(self, q, ip, port=5000):
        super().__init__()
        self.ip = ip
        self.port = port
        self.queue = q
        self.buff_size = 100000

        self.socket = None
        self.running = False
        self.count = None
        self.thread = None

    @QtCore.pyqtSlot()
    def start(self):
        self.running = True

        self.refTime = time.time()
        
        self.count = 0

        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.socket.bind(("127.0.0.1", self.port + 1))
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 10 * 1024 * 1024)

        self.thread = threading.Thread(target = self.recvLoop, daemon=True)
        self.thread.start()


        if DEBUG:
            print(f"\nSocket connected to {self.socket.localAddress().toString()}, waiting for packets...")

    def recvLoop(self):
        while self.running:
            try:
                data, addr = self.socket.recvfrom(self.buff_size)
                if addr[0] != self.ip:
                    continue
                try:
                    self.queue.put_nowait(data)
                except queue.Full:
                    print("Dropped packets!!")
                    pass
            except OSError:
                break
    
    @QtCore.pyqtSlot()
    def stop(self):
        if not self.running:
            return
        
        self.running = False
        
        if self.socket:
            try:
                self.socket.close()
            except Exception:
                print("Error shutting down rx socket.")
                pass
        print("Shutting down rx thread")
        if self.thread:
            self.thread.join()
        print("Rx thread shut down.\n")
        self.done.emit()
        if DEBUG:
            print("\nRx Disconnected successfully")




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

            if data is not None and self.mode < 2 and (data[0] & 0x03) < 2:
                arr = np.frombuffer(data, dtype=self.packetType)

                valid = arr[arr['valid'] == 1 and arr['type'] == 1]

                if len(valid) > 0:
                    lBuffer.append((valid['x'], valid['y'], valid['t'], valid['mag']))
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
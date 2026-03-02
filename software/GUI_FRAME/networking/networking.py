import numpy as np
from PyQt5.QtCore import QObject, pyqtSignal
from PyQt5 import QtNetwork

from PyQt5 import QtCore, QtNetwork
import struct


class NetworkWorker(QtCore.QObject):

    batch_ready = QtCore.pyqtSignal(object)
    done = QtCore.pyqtSignal()
    error = QtCore.pyqtSignal(str)

    def __init__(self, type, port=5000):
        super().__init__()
        self.type = type
        self.port = port
        self.batch_size = 20000

        self.socket = None
        self.buffer = []
        self.running = False

    @QtCore.pyqtSlot()
    def start(self):
        self.running = True

        self.socket = QtNetwork.QUdpSocket()
        success = self.socket.bind(
            QtNetwork.QHostAddress.Any,
            self.port
        )

        if not success:
            print("error")
            self.error.emit("Failed to bind UDP socket")
            return

        self.socket.readyRead.connect(self.read_datagrams)
        print("Connected")

    @QtCore.pyqtSlot()
    def stop(self):
        self.running = False
        if self.socket:
            self.socket.readyRead.disconnect()
            self.socket.close()
            self.socket.deleteLater()
            self.socket = None
            print("Deleting Socket")

        if self.buffer:
            batch = np.array(self.buffer, dtype=self.type)
            self.batch_ready.emit(batch)
            self.buffer.clear()

        self.done.emit()
        print("Done")

    @QtCore.pyqtSlot()
    def read_datagrams(self):
        print("Writing data...")
        while self.running and self.socket.hasPendingDatagrams():
            size = self.socket.pendingDatagramSize()
            datagram, _, _ = self.socket.readDatagram(size)

            photons = self.decode_packet(datagram)

            self.buffer.extend(photons)

            if len(self.buffer) >= self.batch_size:
                batch = np.array(self.buffer, dtype=np.float32)
                self.buffer.clear()
                self.batch_ready.emit(batch)

    @QtCore.pyqtSlot()
    def decode_packet(self, datagram):
        photons = []

        packet_size = 20
        count = len(datagram) // packet_size

        for i in range(count):
            offset = i * packet_size

            mag, t, x, y = struct.unpack_from("!fdff", datagram, offset)

            photons.append((x, y, t, mag))

        return photons

def main():
    t = np.dtype([
        ('xpos', 'f4'),
        ('ypos', 'f4'),
        ('time', 'f8'),
        ('magnitude', 'f4')
    ])
    recv = NetworkWorker(t, 561)
    recv.stop()

if __name__ == "__main__":
    main()
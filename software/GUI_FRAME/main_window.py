import numpy as np
from PyQt5 import QtCore, QtWidgets
from PyQt5.QtCore import QThread, pyqtSlot
from PyQt5.QtWidgets import QApplication, QMainWindow, QPushButton, QWidget, QVBoxLayout, QLabel, QDialog, QTabWidget
import os
from datetime import datetime
import time
from plots import HeatmapWidget, PHDWidget, EventRateWidget
from output_gen.output_gen import ListWriter, ImageWriter
import queue
from networking.networking import RxWorker, TxWorker, DecWorker
from matplotlib.backends.backend_qt5agg import NavigationToolbar2QT as NavigationToolbar
import ipaddress
import pyqtgraph as pg


class EtherDAQMock(QtWidgets.QMainWindow):
    startPacket = QtCore.pyqtSignal(int, int, int, int, int, float, float)


    def __init__(self):
        super().__init__()
        self.setWindowTitle("EtherDaq")
        self.setGeometry(300, 300, 1300, 1000)

        # create the tabs
        self.tabs = QTabWidget()
        self.setCentralWidget(self.tabs)
        self.tab1 = QWidget()
        self.tab2 = QWidget()
        self.tabs.addTab(self.tab1, "Operate")
        self.tabs.addTab(self.tab2, "Parameters")
        self.initTab1()
        self.initTab2()

        # sets the top menu items
        menubar = self.menuBar()
        menubar.addMenu("&File").addAction("Exit", self.close)
        menubar.addMenu("&Settings")



        # ---- Status bar ----
        self.secondsStatusLbl = QtWidgets.QLabel(f"Seconds: {self.acqLen.value()}")
        self.detEventsLbl = QtWidgets.QLabel("Det Events: 0")
        self.missingLbl = QtWidgets.QLabel("Missing Packets: 0")

        for w in (self.secondsStatusLbl, self.detEventsLbl, self.missingLbl):
            w.setStyleSheet("color: #444;")

        sb = self.statusBar()
        sb.addPermanentWidget(self.secondsStatusLbl)
        sb.addPermanentWidget(self.detEventsLbl)
        sb.addPermanentWidget(self.missingLbl)

        self.acquireBtn.clicked.connect(self.start_acquire)
        self.stopBtn.clicked.connect(self.stop_acquire)

        self.fileBtn.clicked.connect(self.getFilePath)
        self.save_folder = os.getcwd()

        self.ParamsBtn.clicked.connect(self.get_settings)
        self.erChk.toggled.connect(self.erControl)


        self.writer_thread = None
        self.writer_worker = None
        self.image_worker = None
        self.tx_thread = None
        self.image_thread = None
        self.tx_worker = None
        self.recv_worker = None
        self.popup = None
        self.decode_worker = None
        self.paramWin = None


        self.mode = -1
        self.time = -1
        self.sel = -1
        self.frac = -1
        self.thresh = -1
        self.delay = -1
        self.fs = -1
        self.setup = 0
        self.ip = "127.0.0.1"
        self.port = 561
        self.kx = 1
        self.ky = 1
        self.x = 102
        self.y = 102
        self.ts = 1024
        self.nx = 4096
        self.ny = 4096

        self.inType = np.dtype([('xpos', 'f4'), ('ypos', 'f4'), ('time', 'f8'), ('mag', 'f4')])
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self._update_seconds_status)
     

    def initTab1(self):
        # creates the layout (left column and right column)
        root = QtWidgets.QHBoxLayout(self.tab1)
        root.setContentsMargins(12, 6, 12, 6)
        root.setSpacing(12)

        # ===== Left column: Controls & PHD =====
        leftCol = QtWidgets.QVBoxLayout()
        leftCol.setSpacing(12)

        dataBox = QtWidgets.QGroupBox(" ")
        dataBox.setFlat(True)
        dataLay = QtWidgets.QGridLayout(dataBox)
        dataLay.setContentsMargins(0, 0, 0, 0)
        dataLay.setHorizontalSpacing(10)
        dataLay.setVerticalSpacing(8)

        dataModeLbl = QtWidgets.QLabel("Mode:")
        self.dataMode = QtWidgets.QComboBox()
        self.dataMode.addItems(["Standard", "Test", "Estimate"])
        self.dataMode.setFixedWidth(120)

        typeLabel = QtWidgets.QLabel("Output Type:")
        self.outType = QtWidgets.QComboBox()
        self.outType.addItems(["None", "Gain", "Photon List"])
        self.outType.setFixedWidth(120)


        self.acqType = QtWidgets.QComboBox()
        self.acqType.addItems(["Seconds:", "Events:"])
        self.acqLen = QtWidgets.QSpinBox()
        self.acqLen.setRange(1, 2147483647)
        self.acqLen.setValue(100)
        self.acqLen.setFixedWidth(120)
        self.acqLen.valueChanged.connect(self._update_seconds_status)

        self.fileBtn = QtWidgets.QPushButton("Select Save Folder")
        self.acquireBtn = QtWidgets.QPushButton("Acquire")
        self.stopBtn = QtWidgets.QPushButton("Stop")
        self.stopBtn.setEnabled(False)
        for b in ( self.acquireBtn, self.stopBtn):
            b.setFixedWidth(100)



        self.fileBtn.setFixedWidth(200)
        dataLay.addWidget(typeLabel, 0, 0)
        dataLay.addWidget(self.outType, 0, 4)
        dataLay.addWidget(dataModeLbl, 1, 0)
        dataLay.addWidget(self.dataMode, 1, 4)
        dataLay.addWidget(self.acqType, 2, 0)
        dataLay.addWidget(self.acqLen, 2, 4)
        dataLay.addWidget(self.fileBtn,    3, 0, 1, 2)
        dataLay.addWidget(self.acquireBtn, 3, 2, 1, 2)
        dataLay.addWidget(self.stopBtn,    3, 3, 1, 2)

        leftCol.addWidget(dataBox)

        self.phdChk = QtWidgets.QCheckBox("Real Time PHD")
        self.phdChk.setChecked(True)
        leftCol.addWidget(self.phdChk)

        self.phdPlot = PHDWidget(bins = 256)
        self.phdPlot.setMinimumSize(300, 200)
        leftCol.addWidget(self.phdPlot)

        self.erChk = QtWidgets.QCheckBox("Running Event Rate")
        self.erChk.setChecked(True)
        leftCol.addWidget(self.erChk)

        self.erPlot = EventRateWidget()
        self.erPlot.setMinimumSize(300, 200)
        leftCol.addWidget(self.erPlot)

        leftCol.addStretch(1)

        # ===== Right column: Main Image & controls =====
        rightCol = QtWidgets.QVBoxLayout()
        rightCol.setSpacing(8)

        topRow = QtWidgets.QHBoxLayout()
        topRow.addStretch(1)
        self.rtImageChk = QtWidgets.QCheckBox("Real Time Image")
        self.rtImageChk.setChecked(True)
        topRow.addWidget(self.rtImageChk)
        rightCol.addLayout(topRow)

        self.hitmap = HeatmapWidget()
        rightCol.addWidget(self.hitmap)



        root.addLayout(leftCol, 0)
        root.addLayout(rightCol, 1)

    def initTab2(self):
        root = QtWidgets.QHBoxLayout(self.tab2)
        root.setContentsMargins(12, 6, 12, 6)
        root.setSpacing(12)

        leftCol = QtWidgets.QVBoxLayout()
        leftCol.setSpacing(12)
        
        # Create the box for networking parameters
        netBox = QtWidgets.QGroupBox("Connectivity Parameters")
        netLay = QtWidgets.QGridLayout(netBox)
        netLay.setContentsMargins(10, 8, 10, 8)
        netLay.setHorizontalSpacing(10)
        netLay.setVerticalSpacing(8)
        self.boardIP = QtWidgets.QLineEdit("127.0.0.1")
        self.boardIP.setFixedWidth(100)
        self.boardPort = QtWidgets.QLineEdit("561")
        self.boardPort.setFixedWidth(100)
        netLay.addWidget(QtWidgets.QLabel("FPGA Board IP Address:"), 0, 0)
        netLay.addWidget(self.boardIP, 0, 1)
        netLay.addWidget(QtWidgets.QLabel("FPGA Board Port:"), 1, 0)
        netLay.addWidget(self.boardPort, 1, 1)
        netBox.setSizePolicy(QtWidgets.QSizePolicy.Preferred, QtWidgets.QSizePolicy.Fixed)
        leftCol.addWidget(netBox)
        
        # create the box for cfd and operation parameters
        paramBox = QtWidgets.QGroupBox("Operation Parameters")
        paramLay = QtWidgets.QGridLayout(paramBox)
        paramLay.setContentsMargins(10, 8, 10, 8)
        paramLay.setHorizontalSpacing(10)
        paramLay.setVerticalSpacing(8)
        self.delayTime = QtWidgets.QLineEdit("123")
        self.delayTime.setFixedWidth(100)
        self.fractionParam = QtWidgets.QLineEdit("0.5")
        self.fractionParam.setFixedWidth(100)
        self.threshold = QtWidgets.QLineEdit("50")
        self.threshold.setFixedWidth(100)
        self.sampleRate = QtWidgets.QLineEdit("3.0")
        self.sampleRate.setFixedWidth(100)
        self.zc = QtWidgets.QLineEdit("8")
        self.zc.setFixedWidth(100)
        paramLay.addWidget(QtWidgets.QLabel("Delay Time (ns):"), 0, 0)
        paramLay.addWidget(self.delayTime, 0, 1)
        paramLay.addWidget(QtWidgets.QLabel("Fraction Parameter:"), 1, 0)
        paramLay.addWidget(self.fractionParam, 1, 1)
        paramLay.addWidget(QtWidgets.QLabel("Threshold:"), 2, 0)
        paramLay.addWidget(self.threshold, 2, 1)
        paramLay.addWidget(QtWidgets.QLabel("Sample Rate (GHz):"), 3, 0)
        paramLay.addWidget(self.sampleRate, 3, 1)
        paramLay.addWidget(QtWidgets.QLabel("Zero Crossing Samples:"), 4, 0)
        paramLay.addWidget(self.zc, 4, 1)
        paramBox.setSizePolicy(QtWidgets.QSizePolicy.Preferred, QtWidgets.QSizePolicy.Fixed)
        leftCol.addWidget(paramBox)

        # create the box for detector area parameters
        detBox = QtWidgets.QGroupBox("Detector Parameters")
        detLay = QtWidgets.QGridLayout(detBox)
        detLay.setContentsMargins(10, 8, 10, 8)
        detLay.setHorizontalSpacing(10)
        detLay.setVerticalSpacing(8)

        self.detX = QtWidgets.QLineEdit("102")
        self.detX.setFixedWidth(100)
        self.detY = QtWidgets.QLineEdit("102")
        self.detY.setFixedWidth(100)
        self.kxVal = QtWidgets.QLineEdit("1")
        self.kxVal.setFixedWidth(100)
        self.kyVal = QtWidgets.QLineEdit("1")
        self.kyVal.setFixedWidth(100)
        self.tsDetails = QtWidgets.QLineEdit("1024")
        self.tsDetails.setFixedWidth(100)
        detLay.addWidget(QtWidgets.QLabel("Detector X (mm):"), 0, 0)
        detLay.addWidget(self.detX, 0, 1)
        detLay.addWidget(QtWidgets.QLabel("Detector Y (mm):"), 1, 0)
        detLay.addWidget(self.detY, 1, 1)
        detLay.addWidget(QtWidgets.QLabel("X-axis Propagation Constant (um/ts):"), 2, 0)
        detLay.addWidget(self.kxVal, 2, 1)
        detLay.addWidget(QtWidgets.QLabel("Y-axis Propagation Constant (um/ts):"), 3, 0)
        detLay.addWidget(self.kyVal, 3, 1)
        detLay.addWidget(QtWidgets.QLabel("Timestamp Details:"), 4, 0)
        detLay.addWidget(self.tsDetails, 4, 1)
        detBox.setSizePolicy(QtWidgets.QSizePolicy.Preferred, QtWidgets.QSizePolicy.Fixed)
        leftCol.addWidget(detBox)

        
        sizeBox = QtWidgets.QGroupBox("Image Size")
        sizeLay = QtWidgets.QGridLayout(sizeBox)
        sizeLay.setContentsMargins(10, 8, 10, 8)
        sizeLay.setHorizontalSpacing(10)
        self.xSize = QtWidgets.QComboBox()
        self.ySize = QtWidgets.QComboBox()
        for cb in (self.xSize, self.ySize):
            cb.addItems(["512", "1024", "2048", "4096"])
            cb.setCurrentText("4096")
            cb.setFixedWidth(100)
        sizeLay.addWidget(QtWidgets.QLabel("X Size:"), 0, 0)
        sizeLay.addWidget(self.xSize, 0, 1)
        sizeLay.addWidget(QtWidgets.QLabel("Y Size:"), 1, 0)
        sizeLay.addWidget(self.ySize, 1, 1)
        leftCol.addWidget(sizeBox)

        self.ParamsBtn = QtWidgets.QPushButton("Set Parameters")
        self.ParamsBtn.setFixedWidth(200)
        leftCol.addWidget(self.ParamsBtn)
        root.addLayout(leftCol, 0)
        leftCol.addStretch()

    # this function gets called whenever the user clicks the set params button, it saves the parameters entered by the user
    def get_settings(self):
        def _safe_float(text, default=0.0):
            try:
                return float(text)
            except ValueError:
                return default
        
        self.sel = 0
        self.mode = self.dataMode.currentIndex()
        self.time = time.time()
        self.thresh = 50
        self.delay = int(self.delayTime.text())
        self.frac = _safe_float(self.fractionParam.text(), 0.0)
        self.fs = _safe_float(self.sampleRate.text(), 1.0)
        self.ip = self.boardIP.text()
        self.port = int(self.boardPort.text())
        self.kx = _safe_float(self.kxVal.text())
        self.ky = _safe_float(self.kyVal.text())
        self.ts = _safe_float(self.tsDetails.text())
        self.x = _safe_float(self.detX.text()) * 1000
        self.y = _safe_float(self.detY.text()) * 1000
        self.nx = int(self.xSize.currentText())
        self.ny = int(self.ySize.currentText())
        if self.delay < 0:
            self.setup = 0
            self.popup = PopupWindow("Error", "Invalid delay value.")
            self.popup.exec()
            return
        if self.frac >= 1 or self.frac <= 0:
            self.setup = 0
            self.popup = PopupWindow("Error", "Invalid fraction value.")
            self.popup.exec()
            return
        if self.fs > 3.6 or self.fs < 2.4:
            self.setup = 0
            self.popup = PopupWindow("Error", "Invalid sampling rate.")
            self.popup.exec()
            return
        if not isValidIP(self.ip):
            self.setup = 0
            self.popup = PopupWindow("Error", "Invalid IP address.")
            self.popup.exec()
            return
        if self.port <= 0:
            self.setup = 0
            self.popup = PopupWindow("Error", "Invalid port value.")
            self.popup.exec()
            return
        if self.x <= 0:
            self.setup = 0
            self.popup = PopupWindow("Error", "Invalid detector x value.")
            self.popup.exec()
            return
        if self.y <= 0:
            self.setup = 0
            self.popup = PopupWindow("Error", "Invalid detector y value.")
            self.popup.exec()
            return
        if self.kx < 0:
            self.setup = 0
            self.popup = PopupWindow("Error", "Invalid kx value.")
            self.popup.exec()
            return
        if self.ky < 0:
            self.setup = 0
            self.popup = PopupWindow("Error", "Invalid ky value.")
            self.popup.exec()
            return
        
        self.setup = 1
        self.open_popup()
 
    def getFilePath(self):
        folder = QtWidgets.QFileDialog.getExistingDirectory(self, "Select Save Folder")

        if folder:
            self.save_folder = folder

    def _update_seconds_status(self):
        time = self.erPlot.times[-1] if self.erPlot.times and self.erPlot.running else 0
        time = int(time)
        if self.acqType.currentIndex() == 0:
            time = self.acqLen.value() - time
            if time <= 0:
                self.secondsStatusLbl.setText(f"Seconds: {time}")
                self.stop_acquire()
                return
        self.secondsStatusLbl.setText(f"Seconds: {time}")

    def eventsStatus(self):
        count = np.sum(self.erPlot.rates) if self.erPlot.rates and self.erPlot.running else 0
        self.detEventsLbl.setText(f"Det Events: {count}")
        if self.acqType.currentIndex() == 1 and count > self.acqLen.value():
            self.stop_acquire()    

    def updatePlots(self, img, x, y, hist, count):
        if self.rtImageChk.isChecked():
            self.hitmap.set_image(img, x, y)
        if self.phdChk.isChecked():
            self.phdPlot.updatePlot(hist)
        self.erPlot.addEvents(count)
        self.eventsStatus()

    def erControl(self, check):
        self.erPlot.running = check
        if not check:
            self.erPlot.stop(False)

    def start_acquire(self):
        if self.setup:
            self.mode = self.dataMode.currentIndex()
            # sets up the threads and workers for networking and output file generation
            self.setupThreads()
            self.phdPlot.clear()
            self.hitmap.clear()

            self.fileBtn.setEnabled(False)
            self.ParamsBtn.setEnabled(False)
            self.acquireBtn.setEnabled(False)
            self.stopBtn.setEnabled(True)
            self.dataMode.setEnabled(False)
            self.outType.setEnabled(False)
            self.acqLen.setEnabled(False)
            self.acqType.setEnabled(False)
            self.statusBar().showMessage("Acquiring...", 2000)

            self.startPacket.emit(self.sel, self.mode, self.time, self.thresh, self.delay, self.frac, self.fs)
            if self.mode < 2:
                self.phdPlot.start()
                self.erPlot.start()
            self.timer.start(1000)
        else:
            self.paramError()
    
    @pyqtSlot(object)
    def Estimate(self, pulse):
        start = False
        prev = pulse[0]
        best = 0
        sample = pulse[0]
        idx1 = 0
        idx2 = 0
        for i in range(len(pulse)):
            x = pulse[i]
            if x < 0.0025 and not start:
                start = True
                idx1 = i
            slope = x - prev
            prev = x
            if slope < best:
                best = slope
                sample = x
                idx2 = i
        frac = sample / min(pulse)
        delay = idx2 - idx1
        self.popup = PopupWindow("Estimated Paramters", f"Delay = {delay}\nFraction = {frac}")
        self.popup.exec()
        self.stop_acquire()

    def setupThreads(self):

        # create the writer and tx individual threads
        if self.outType.currentIndex() != 0:
            self.writer_thread = QThread()
        self.tx_thread = QThread()
        self.image_thread = QThread()

        # create the workers that are going to be living in the thread
        if self.outType.currentIndex() == 2:
            self.writer_worker = ListWriter(self.save_folder, self.inType)
        
        if self.outType.currentIndex() == 1:
            self.image_worker = ImageWriter(self.save_folder, self.inType, x = self.x, y = self.y, save = True, nx = self.nx, ny = self.ny)
        else:
            self.image_worker = ImageWriter(self.save_folder, self.inType, x = self.x, y = self.y, save = False, nx = self.nx, ny = self.ny)
        self.tx_worker = TxWorker(self.ip, self.port)
        
        q = queue.Queue(maxsize=1000000)
        self.recv_worker = RxWorker(q, self.ip, self.port)
        self.decode_worker = DecWorker(q, self.inType, self.mode)

        # move the workers into their respective threads
        if self.writer_worker is not None:
            self.writer_worker.moveToThread(self.writer_thread)
        self.tx_worker.moveToThread(self.tx_thread)
        self.image_worker.moveToThread(self.image_thread)

        # connect the worker's start function so that it is called when the thread is deployed
        if self.writer_worker is not None:
            self.writer_thread.started.connect(self.writer_worker.start)
        self.tx_thread.started.connect(self.tx_worker.start)
        self.image_thread.started.connect(self.image_worker.start)


        # connect the batch ready signal from the depacketizer to the writer.
        # This allows the depacketizer to send batched to the writeBatch function in the writer worker
        if self.writer_worker is not None:
            self.decode_worker.batch_ready.connect(self.writer_worker.writeBatch)
        self.decode_worker.batch_ready.connect(self.image_worker.writeBatch)
        self.image_worker.image_ready.connect(self.updatePlots)
        self.decode_worker.pulse.connect(self.Estimate)
        self.startPacket.connect(self.tx_worker.sendStart)

        # Each worker has a finished signal it emits when they are destroyed, this connects that signal to the thread's quit function
        if self.writer_worker is not None:
            self.writer_worker.finished.connect(self.writer_thread.quit)
        self.tx_worker.done.connect(self.tx_thread.quit)
        self.image_worker.finished.connect(self.image_thread.quit)

        # delete later ensures proper cleanup of threads
        if self.writer_worker is not None:
            self.writer_thread.finished.connect(self.writer_thread.deleteLater)
        self.tx_thread.finished.connect(self.tx_thread.deleteLater)
        self.image_thread.finished.connect(self.image_thread.deleteLater)
        
        # deploy each thread, remember this also starts each worker
        if self.writer_worker is not None:
            self.writer_thread.start()
        self.recv_worker.start()
        self.tx_thread.start()
        self.decode_worker.start()
        self.image_thread.start()

        # connect the done signal from the receiver to the function that stops all workers and threads to ensure the socket is closed properly
        self.tx_worker.done.connect(self.txCleanUp)
        self.recv_worker.done.connect(self.cleanUp)
       # this function gets the user selected file path and is called whenever the user clicks the "save folder" button

    def stop_acquire(self):
        self.timer.stop()
        self.erPlot.stop(True)
        self.phdPlot.stop()
        self.fileBtn.setEnabled(True)
        self.acquireBtn.setEnabled(True)
        self.stopBtn.setEnabled(False)
        self.ParamsBtn.setEnabled(True)
        self.outType.setEnabled(True)
        self.dataMode.setEnabled(True)
        self.acqLen.setEnabled(True)
        self.acqType.setEnabled(True)
        self.statusBar().showMessage("Acquisition stopped.", 2000)

        # invoke the stop function 
        self.recv_worker.stop()
        QtCore.QMetaObject.invokeMethod(self.tx_worker, "stop", QtCore.Qt.QueuedConnection)


    # This function shuts down the transmit thread
    def txCleanUp(self):
        self.tx_thread.wait()

        self.tx_thread = None
        self.tx_worker = None

    # This function cleans up the writer and receive threads
    def cleanUp(self):
        # call the stop function on the writer worker which will emit a signal causing the thread to quit
        if self.writer_worker is not None:
            self.writer_worker.stop()
            self.writer_thread.wait()

        self.image_worker.stop()
        self.image_thread.wait()

        self.decode_worker.stop()

        # clean up the memory
        self.recv_worker = None
        self.decode_worker = None
        self.writer_thread = None
        self.writer_worker = None
        self.image_thread = None
        self.image_worker = None

    # this functions ensures the proper cleanup of threads when the user randomly exits the application
    def closeEvent(self, a0):
        if self.recv_worker is not None:
            self.recv_worker.stop()
        if self.tx_worker is not None:
            QtCore.QMetaObject.invokeMethod(self.tx_worker, "stop", QtCore.Qt.QueuedConnection)
        
        a0.accept()
        
    # function opens a second window, this is called when the user sets the parameters
    def open_popup(self):
        self.popup = PopupWindow("Param Confirm", "Parameters succesfully saved.")
        self.popup.exec()

    # function opens a second window, this is called when the user tries to acquire without setting up parameters
    def paramError(self):
        self.popup = PopupWindow("Error", "Set parameters first.")
        self.popup.exec()

class PopupWindow(QDialog):
    def __init__(self, title, msg):
        super().__init__()
        self.setWindowTitle(title)
        self.setGeometry(600, 400, 300, 100)

        layout = QVBoxLayout()
        layout.addWidget(QLabel(msg))
        self.setLayout(layout)

def isValidIP(ip):
    try:
        ipaddress.ip_address(ip)
        return True 
    except ValueError:
        return False

class CustomToolbar(NavigationToolbar):
    toolitems = [t for t in NavigationToolbar.toolitems if t[0] in ("Home", "Pan", "Zoom", "Back", "Forward")]
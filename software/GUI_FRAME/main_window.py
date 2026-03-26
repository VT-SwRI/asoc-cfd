import numpy as np
from PyQt5 import QtCore, QtWidgets
from PyQt5.QtCore import QThread
from PyQt5.QtWidgets import QApplication, QMainWindow, QPushButton, QWidget, QVBoxLayout, QLabel, QDialog
import os
from datetime import datetime
import time
from plots import MplCanvas
from mock_data import generate_spiral_hits, generate_phd_samples
from output_gen.output_gen import ListWriter, ImageWriter
import queue
from networking.networking import RxWorker, TxWorker, DecWorker



class EtherDAQMock(QtWidgets.QMainWindow):
    startPacket = QtCore.pyqtSignal(int, int, int, int, int, float, float)


    def __init__(self):
        super().__init__()
        self.setWindowTitle("EtherDaq")
        self.setGeometry(300, 300, 1300, 1000)

        # sets the top menu items
        menubar = self.menuBar()
        menubar.addMenu("&File").addAction("Exit", self.close)
        menubar.addMenu("&Settings")

        # creates the layout (left column and right column)
        central = QtWidgets.QWidget()
        root = QtWidgets.QHBoxLayout(central)
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
        self.dataMode.addItems(["Standard", "Test"])
        self.dataMode.setFixedWidth(120)

        typeLabel = QtWidgets.QLabel("Output Type:")
        self.outType = QtWidgets.QComboBox()
        self.outType.addItems(["None", "Gain", "Photon List"])
        self.outType.setFixedWidth(120)

        secondsLbl = QtWidgets.QLabel("Seconds:")
        self.seconds = QtWidgets.QSpinBox()
        self.seconds.setRange(1, 3600)
        self.seconds.setValue(100)
        self.seconds.setFixedWidth(120)
        self.seconds.valueChanged.connect(self._update_seconds_status)

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
        dataLay.addWidget(secondsLbl, 2, 0)
        dataLay.addWidget(self.seconds, 2, 4)
        dataLay.addWidget(self.fileBtn,    3, 0, 1, 2)
        dataLay.addWidget(self.acquireBtn, 3, 2, 1, 2)
        dataLay.addWidget(self.stopBtn,    3, 3, 1, 2)

        leftCol.addWidget(dataBox)

        # sizeBox = QtWidgets.QGroupBox("Image Size")
        # sizeLay = QtWidgets.QGridLayout(sizeBox)
        # sizeLay.setContentsMargins(10, 8, 10, 8)
        # sizeLay.setHorizontalSpacing(10)
        # self.xSize = QtWidgets.QComboBox()
        # self.ySize = QtWidgets.QComboBox()
        # for cb in (self.xSize, self.ySize):
        #     cb.addItems(["512", "1024", "2048", "4096"])
        #     cb.setCurrentText("1024")
        #     cb.setFixedWidth(100)
        # sizeLay.addWidget(QtWidgets.QLabel("X Size:"), 0, 0)
        # sizeLay.addWidget(self.xSize, 0, 1)
        # sizeLay.addWidget(QtWidgets.QLabel("Y Size:"), 1, 0)
        # sizeLay.addWidget(self.ySize, 1, 1)

        # leftCol.addWidget(sizeBox)

        paramBox = QtWidgets.QGroupBox("User Parameters")
        paramLay = QtWidgets.QGridLayout(paramBox)
        paramLay.setContentsMargins(10, 8, 10, 8)
        paramLay.setHorizontalSpacing(10)
        paramLay.setVerticalSpacing(8)

        self.ParamsBtn = QtWidgets.QPushButton("Set Parameters")
        self.ParamsBtn.setFixedWidth(200)
        

        self.delayTime = QtWidgets.QLineEdit("123")
        self.delayTime.setFixedWidth(100)
        self.fractionParam = QtWidgets.QLineEdit("0.5")
        self.fractionParam.setFixedWidth(100)
        self.threshold = QtWidgets.QLineEdit("50")
        self.threshold.setFixedWidth(100)
        self.sampleRate = QtWidgets.QLineEdit("3.0")
        self.sampleRate.setFixedWidth(100)
        self.boardIP = QtWidgets.QLineEdit("127.0.0.1")
        self.boardIP.setFixedWidth(100)
        self.boardPort = QtWidgets.QLineEdit("561")
        self.boardPort.setFixedWidth(100)

        paramLay.addWidget(QtWidgets.QLabel("Delay Time (ns):"), 0, 0)
        paramLay.addWidget(self.delayTime, 0, 1)
        paramLay.addWidget(QtWidgets.QLabel("Fraction Parameter:"), 1, 0)
        paramLay.addWidget(self.fractionParam, 1, 1)
        paramLay.addWidget(QtWidgets.QLabel("Threshold:"), 2, 0)
        paramLay.addWidget(self.threshold, 2, 1)
        paramLay.addWidget(QtWidgets.QLabel("Sample Rate (GHz):"), 3, 0)
        paramLay.addWidget(self.sampleRate, 3, 1)
        paramLay.addWidget(QtWidgets.QLabel("FPGA Board IP Address:"), 4, 0)
        paramLay.addWidget(self.boardIP, 4, 1)
        paramLay.addWidget(QtWidgets.QLabel("FPGA Board Port:"), 5, 0)
        paramLay.addWidget(self.boardPort, 5, 1)

        paramLay.addWidget(self.ParamsBtn, 6, 0, 1, 2)

        leftCol.addWidget(paramBox)

        self.phdChk = QtWidgets.QCheckBox("Real Time PHD")
        self.phdChk.setChecked(True)
        leftCol.addWidget(self.phdChk)

        self.phdPlot = MplCanvas(ticks=(0, 128, 256), xLabel = "Pulse Height (mV)", yLabel= "Number of Detections", title="Pulse Height Distribution")
        self.phdPlot.setMinimumSize(300, 200)
        leftCol.addWidget(self.phdPlot)

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

        canvasRow = QtWidgets.QHBoxLayout()
        canvasRow.setSpacing(10)

        yBox = QtWidgets.QVBoxLayout()
        yBox.setSpacing(6)
        yBox.addWidget(QtWidgets.QLabel("Y Range:"))
        self.yRange = QtWidgets.QComboBox()
        self.yRange.addItems(["256", "512", "1024", "2048", "4096"])
        #TODO - reset yrange
        self.yRange.setCurrentText("4096")
        yBox.addWidget(self.yRange)
        yBox.addStretch(1)
        canvasRow.addLayout(yBox)

        self.bigPlot = MplCanvas(xLabel= "X-Position (mm)", yLabel= "Y-Position (mm)", title = "Position Hit Map")
        canvasRow.addWidget(self.bigPlot, 1)
        rightCol.addLayout(canvasRow, 1)

        bottomGrid = QtWidgets.QGridLayout()
        bottomGrid.setHorizontalSpacing(12)
        bottomGrid.setVerticalSpacing(6)

        yOffLbl = QtWidgets.QLabel("Y Offset:")
        xOffLbl = QtWidgets.QLabel("X Offset:")
        self.yOffset = QtWidgets.QLineEdit("0")
        self.xOffset = QtWidgets.QLineEdit("0")
        self.yOffset.setFixedWidth(90)
        self.xOffset.setFixedWidth(90)

        xRangeLbl = QtWidgets.QLabel("X Range:")
        self.xRange = QtWidgets.QComboBox()
        self.xRange.addItems(["256", "512", "1024", "2048", "4096"])
        
        #TODO - reset the current text
        self.xRange.setCurrentText("4096")
        self.xRange.setFixedWidth(100)

        bottomGrid.addWidget(yOffLbl, 0, 0)
        bottomGrid.addWidget(self.yOffset, 0, 1)
        bottomGrid.addItem(
            QtWidgets.QSpacerItem(
                40,
                10,
                QtWidgets.QSizePolicy.Expanding,
                QtWidgets.QSizePolicy.Minimum,
            ),
            0,
            2,
        )
        bottomGrid.addWidget(xRangeLbl, 0, 3, QtCore.Qt.AlignRight)
        bottomGrid.addWidget(self.xRange, 0, 4)

        bottomGrid.addWidget(xOffLbl, 1, 0)
        bottomGrid.addWidget(self.xOffset, 1, 1)

        rightCol.addLayout(bottomGrid, 0)

        root.addLayout(leftCol, 0)
        root.addLayout(rightCol, 1)

        self.setCentralWidget(central)

        # ---- Status bar ----
        self.secondsStatusLbl = QtWidgets.QLabel(f"Seconds: {self.seconds.value()}")
        self.detEventsLbl = QtWidgets.QLabel("Det Events: 0")
        self.countsLbl = QtWidgets.QLabel("Counts: 0")
        self.missingLbl = QtWidgets.QLabel("Missing Packets: 0")

        for w in (self.secondsStatusLbl, self.detEventsLbl, self.countsLbl, self.missingLbl):
            w.setStyleSheet("color: #444;")

        sb = self.statusBar()
        sb.addPermanentWidget(self.secondsStatusLbl)
        sb.addPermanentWidget(self.detEventsLbl)
        sb.addPermanentWidget(self.countsLbl)
        sb.addPermanentWidget(self.missingLbl)

        self.acquireBtn.clicked.connect(self.start_acquire)
        self.stopBtn.clicked.connect(self.stop_acquire)

        self.fileBtn.clicked.connect(self.getFilePath)
        self.save_folder = os.getcwd()

        self.xRange.currentIndexChanged.connect(self._update_viewport)
        self.yRange.currentIndexChanged.connect(self._update_viewport)
        self.xOffset.editingFinished.connect(self._update_viewport)
        self.yOffset.editingFinished.connect(self._update_viewport)

        self.ParamsBtn.clicked.connect(self.get_settings)


        self.writer_thread = None
        self.writer_worker = None
        self.tx_thread = None
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

        self.inType = np.dtype([('xpos', 'f4'), ('ypos', 'f4'), ('time', 'f8'), ('magnitude', 'f4')])
     


    # this function gets called whenever the user clicks the set params button, it saves the parameters entered by the user
    def get_settings(self):
        def _safe_float(text, default=0.0):
            try:
                return float(text)
            except ValueError:
                return default
        
        self.sel = 0
        self.mode = self.dataMode.currentIndex()
        self.time = self.seconds.value()
        self.thresh = 50
        self.delay = int(self.delayTime.text())
        self.frac = _safe_float(self.fractionParam.text(), 0.0)
        self.fs = _safe_float(self.sampleRate.text(), 1.0)
        self.ip = self.boardIP.text()
        self.port = int(self.boardPort.text())
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
        if self.port <= 0:
            self.setup = 0
            self.popup = PopupWindow("Error", "Invalid port value.")
            self.popup.exec()
            return
        self.setup = 1
        self.open_popup()


    # this function gets the user selected file path and is called whenever the user clicks the "save folder" button
    def getFilePath(self):
        folder = QtWidgets.QFileDialog.getExistingDirectory(self, "Select Save Folder")

        if folder:
            self.save_folder = folder

    # --- Seconds status helper ---
    def _update_seconds_status(self, val: int):
        if hasattr(self, "secondsStatusLbl"):
            self.secondsStatusLbl.setText(f"Seconds: {val}")

    # --- Helpers for axis parameters ---
    def _get_axis_params(self):
        max_val = 4096

        def _safe_int(text, default=0):
            try:
                return int(text)
            except ValueError:
                return default

        x_range = int(self.xRange.currentText())+50
        y_range = int(self.yRange.currentText())+50
        x_off = _safe_int(self.xOffset.text(), 0)
        y_off = _safe_int(self.yOffset.text(), 0)

        x_off = max(-50, min(x_off, max_val - x_range))
        y_off = max(-50, min(y_off, max_val - y_range))

        self.xOffset.setText(str(x_off))
        self.yOffset.setText(str(y_off))

        return x_range, y_range, x_off, y_off

    # --- Viewport update when controls change ---
    def _update_viewport(self):
        if not hasattr(self, "_hits_x"):
            return

        x_range, y_range, x_off, y_off = self._get_axis_params()

        ax = self.bigPlot.ax
        ax.set_xlim(x_off, x_off + x_range)
        ax.set_ylim(y_off, y_off + y_range)

        xticks = np.linspace(x_off, x_off + x_range, len(self.bigPlot.ticks))
        yticks = np.linspace(y_off, y_off + y_range, len(self.bigPlot.ticks))
        ax.set_xticks(xticks)
        ax.set_yticks(yticks)

        self.bigPlot.draw_idle()

    @QtCore.pyqtSlot(object)
    def updatePlot(self, batch):
        """Generate spiral + PHD and update both graphs."""

        
        x = batch["xpos"]
        y = batch["ypos"]
        xp = ((x +51) * ((4096) / (102))).astype(np.int32)
        yp = ((y +51) * ((4096) / (102))).astype(np.int32)

        mask = ((xp >= 0) & (xp < 4096) & (yp >= 0) & (yp < 4096))

        xp = xp[mask]
        yp = yp[mask]

        self.bigPlot.show_hits(xp, yp)
        # self._update_viewport()

        # PHD histogram on the left (only if checkbox is enabled)
        if self.phdChk.isChecked():
            samples = generate_phd_samples()  # now 0–256 by default
            self.phdPlot.show_hist(
                samples,
                bins=256,
                range_=(0, 256),
                label="PHD",
            )
        else:
            self.phdPlot.clear_axes()

    def setupThreads(self):

        # create the writer and tx individual threads
        self.writer_thread = QThread()
        self.tx_thread = QThread()

        # create the workers that are going to be living in the thread
        if self.outType.currentIndex() == 2:
            self.writer_worker = ListWriter(self.save_folder, self.inType)
        elif self.outType.currentIndex() == 1:
            self.writer_worker = ImageWriter(self.save_folder, self.inType)
        self.tx_worker = TxWorker(self.ip, self.port)

        q = queue.Queue(maxsize=1000000)
        self.recv_worker = RxWorker(q, self.ip, self.port)
        self.decode_worker = DecWorker(q, self.inType)

        # move the workers into their respective threads
        self.writer_worker.moveToThread(self.writer_thread)
        self.tx_worker.moveToThread(self.tx_thread)

        # connect the worker's start function so that it is called when the thread is deployed
        self.writer_thread.started.connect(self.writer_worker.start)
        self.tx_thread.started.connect(self.tx_worker.start)


        # connect the batch ready signal from the depacketizer to the writer.
        # This allows the depacketizer to send batched to the writeBatch function in the writer worker
        self.decode_worker.batch_ready.connect(self.writer_worker.writeBatch)
        # self.decode_worker.batch_ready.connect(self.updatePlot)
        self.startPacket.connect(self.tx_worker.sendStart)

        # Each worker has a finished signal it emits when they are destroyed, this connects that signal to the thread's quit function
        self.writer_worker.finished.connect(self.writer_thread.quit)
        self.tx_worker.done.connect(self.tx_thread.quit)

        # delete later ensures proper cleanup of threads
        self.writer_thread.finished.connect(self.writer_thread.deleteLater)
        self.tx_thread.finished.connect(self.tx_thread.deleteLater)
        
        # deploy each thread, remember this also starts each worker
        self.writer_thread.start()
        self.recv_worker.start()
        self.tx_thread.start()
        self.decode_worker.start()

        # connect the done signal from the receiver to the function that stops all workers and threads to ensure the socket is closed properly
        self.tx_worker.done.connect(self.txCleanUp)
        self.recv_worker.done.connect(self.cleanUp)
    

    def start_acquire(self):
        if self.setup:
            # sets up the threads and workers for networking and output file generation
            self.setupThreads()
            

            self.fileBtn.setEnabled(False)
            self.ParamsBtn.setEnabled(False)
            self.acquireBtn.setEnabled(False)
            self.stopBtn.setEnabled(True)
            self.statusBar().showMessage("Acquiring...", 2000)

            self.startPacket.emit(self.sel, self.mode, self.time, self.thresh, self.delay, self.frac, self.fs)
        else:
            self.paramError()
        

    def stop_acquire(self):
        self.fileBtn.setEnabled(True)
        self.acquireBtn.setEnabled(True)
        self.stopBtn.setEnabled(False)
        self.ParamsBtn.setEnabled(True)
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
        self.writer_worker.stop()
        self.writer_thread.wait()

        self.decode_worker.stop()

        # clean up the memory
        self.recv_worker = None
        self.decode_worker = None
        self.writer_thread = None
        self.writer_worker = None

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
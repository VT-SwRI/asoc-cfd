# main_window.py
# -*- coding: utf-8 -*-

import numpy as np
from PyQt5 import QtCore, QtWidgets

from plots import MplCanvas
from mock_data import generate_spiral_hits, generate_phd_samples


class EtherDAQMock(QtWidgets.QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("EtherDaq [Mock UI]")
        self.resize(1120, 700)

        menubar = self.menuBar()
        menubar.addMenu("&File").addAction("Exit", self.close)
        menubar.addMenu("&Edit")
        menubar.addMenu("&Settings")
        menubar.addMenu("&Help")

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

        dataModeLbl = QtWidgets.QLabel("Data Mode:")
        self.dataMode = QtWidgets.QComboBox()
        self.dataMode.addItems(["Gain"])
        self.dataMode.setFixedWidth(120)

        secondsLbl = QtWidgets.QLabel("Seconds:")
        self.seconds = QtWidgets.QSpinBox()
        self.seconds.setRange(1, 3600)
        self.seconds.setValue(100)
        self.seconds.setFixedWidth(100)
        self.seconds.valueChanged.connect(self._update_seconds_status)

        self.acquireBtn = QtWidgets.QPushButton("Acquire")
        self.stopBtn = QtWidgets.QPushButton("Stop")
        self.stopBtn.setEnabled(False)
        for b in (self.acquireBtn, self.stopBtn):
            b.setFixedWidth(100)

        dataLay.addWidget(dataModeLbl, 0, 0)
        dataLay.addWidget(self.dataMode, 0, 1)
        dataLay.addWidget(secondsLbl, 1, 0)
        dataLay.addWidget(self.seconds, 1, 1)
        dataLay.addWidget(self.acquireBtn, 2, 0, 1, 2)
        dataLay.addWidget(self.stopBtn, 3, 0, 1, 2)

        leftCol.addWidget(dataBox)

        sizeBox = QtWidgets.QGroupBox("Image Size")
        sizeLay = QtWidgets.QGridLayout(sizeBox)
        sizeLay.setContentsMargins(10, 8, 10, 8)
        sizeLay.setHorizontalSpacing(10)
        self.xSize = QtWidgets.QComboBox()
        self.ySize = QtWidgets.QComboBox()
        for cb in (self.xSize, self.ySize):
            cb.addItems(["512", "1024", "2048", "4096"])
            cb.setCurrentText("1024")
            cb.setFixedWidth(100)
        sizeLay.addWidget(QtWidgets.QLabel("X Size:"), 0, 0)
        sizeLay.addWidget(self.xSize, 0, 1)
        sizeLay.addWidget(QtWidgets.QLabel("Y Size:"), 1, 0)
        sizeLay.addWidget(self.ySize, 1, 1)

        leftCol.addWidget(sizeBox)

        self.phdChk = QtWidgets.QCheckBox("Real Time PHD")
        self.phdChk.setChecked(True)
        leftCol.addWidget(self.phdChk)

        self.phdPlot = MplCanvas(ticks=(0, 128, 256))
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
        self.yRange.setCurrentText("4096")
        yBox.addWidget(self.yRange)
        yBox.addStretch(1)
        canvasRow.addLayout(yBox)

        self.bigPlot = MplCanvas()
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

        self.xRange.currentIndexChanged.connect(self._update_viewport)
        self.yRange.currentIndexChanged.connect(self._update_viewport)
        self.xOffset.editingFinished.connect(self._update_viewport)
        self.yOffset.editingFinished.connect(self._update_viewport)

        # initial mock data
        self._mock_refresh()

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

        x_range = int(self.xRange.currentText())
        y_range = int(self.yRange.currentText())
        x_off = _safe_int(self.xOffset.text(), 0)
        y_off = _safe_int(self.yOffset.text(), 0)

        x_off = max(0, min(x_off, max_val - x_range))
        y_off = max(0, min(y_off, max_val - y_range))

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

    # --- Mock handlers ---
    def _mock_refresh(self):
        """Generate spiral + PHD and update both graphs."""

        # Spiral hits on the main image
        x, y = generate_spiral_hits()
        self._hits_x, self._hits_y = x, y
        self.bigPlot.show_hits(x, y, label="Test Spiral Pattern")
        self._update_viewport()

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


    def start_acquire(self):
        self.acquireBtn.setEnabled(False)
        self.stopBtn.setEnabled(True)
        self.statusBar().showMessage("Acquiring...", 2000)
        self._mock_refresh()

    def stop_acquire(self):
        self.acquireBtn.setEnabled(True)
        self.stopBtn.setEnabled(False)
        self.statusBar().showMessage("Acquisition stopped.", 2000)

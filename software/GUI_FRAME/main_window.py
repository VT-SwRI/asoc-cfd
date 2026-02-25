# main_window.py
# -*- coding: utf-8 -*-

import time
import numpy as np
from PyQt5 import QtCore, QtWidgets

from plots import MplCanvas


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

        paramBox = QtWidgets.QGroupBox("User Parameters")
        paramLay = QtWidgets.QGridLayout(paramBox)
        paramLay.setContentsMargins(10, 8, 10, 8)
        paramLay.setHorizontalSpacing(10)
        paramLay.setVerticalSpacing(8)

        self.delayTime = QtWidgets.QLineEdit("0")
        self.delayTime.setFixedWidth(100)
        self.fractionParam = QtWidgets.QLineEdit("0.0")
        self.fractionParam.setFixedWidth(100)
        self.sampleRate = QtWidgets.QLineEdit("1.0")
        self.sampleRate.setFixedWidth(100)

        paramLay.addWidget(QtWidgets.QLabel("Delay Time (ns):"), 0, 0)
        paramLay.addWidget(self.delayTime, 0, 1)
        paramLay.addWidget(QtWidgets.QLabel("Fraction Parameter:"), 1, 0)
        paramLay.addWidget(self.fractionParam, 1, 1)
        paramLay.addWidget(QtWidgets.QLabel("Sample Rate (GHz):"), 2, 0)
        paramLay.addWidget(self.sampleRate, 2, 1)

        leftCol.addWidget(paramBox)

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

        # initialise the acquisition timer (does NOT start it)
        self._init_acquire_timer()

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

    # ---- settings snapshot ----
    def get_settings(self) -> dict:
        """Return all user-chosen parameters as a plain dict."""
        def _safe_float(text, default=0.0):
            try:
                return float(text)
            except ValueError:
                return default

        return {
            "data_mode":        self.dataMode.currentText(),
            "seconds":          self.seconds.value(),
            "delay_time_ns":    _safe_float(self.delayTime.text(), 0.0),
            "fraction_param":   _safe_float(self.fractionParam.text(), 0.0),
            "sample_rate_ghz":  _safe_float(self.sampleRate.text(), 1.0),
            "x_range":          int(self.xRange.currentText()),
            "y_range":          int(self.yRange.currentText()),
            "x_offset":         int(self.xOffset.text() or "0"),
            "y_offset":         int(self.yOffset.text() or "0"),
            "rt_image":         self.rtImageChk.isChecked(),
            "rt_phd":           self.phdChk.isChecked(),
        }

    # --- Live acquisition timer ---
    def _init_acquire_timer(self):
        """Create a 50 ms timer for live random-hit updates."""
        self._acq_timer = QtCore.QTimer(self)
        self._acq_timer.setInterval(50)  # every 0.05 sec
        self._acq_timer.timeout.connect(self._on_tick)

        # accumulated hit buffers
        self._hits_x = np.array([])
        self._hits_y = np.array([])
        self._phd_samples = np.array([])
        self._det_events = 0
        self._acq_start_time = 0.0

        # redraw throttle — update plots every 10th tick (every 500 ms)
        # so the UI stays responsive at 50 ms tick rate
        self._tick_count = 0
        self._REDRAW_EVERY = 10  # 10 ticks × 50 ms = 500 ms

        self._MAX_DURATION = 120.0  # 2 minutes in seconds

    def _on_tick(self):
        """Called every 50 ms — add 3 random hits."""
        # Auto-stop after 2 minutes
        elapsed = time.time() - self._acq_start_time
        if elapsed >= self._MAX_DURATION:
            self.stop_acquire()
            return

        # 3 random hits per tick
        n_new = 3
        new_x = np.random.uniform(0, 4096, n_new)
        new_y = np.random.uniform(0, 4096, n_new)

        self._hits_x = np.concatenate([self._hits_x, new_x])
        self._hits_y = np.concatenate([self._hits_y, new_y])
        self._det_events += n_new

        # PHD energy samples
        new_phd = np.random.normal(128, 30, n_new)
        new_phd = np.clip(new_phd, 0, 256)
        self._phd_samples = np.concatenate([self._phd_samples, new_phd])

        # Only redraw plots every 500 ms to keep the UI smooth
        self._tick_count += 1
        if self._tick_count % self._REDRAW_EVERY == 0:
            if self.rtImageChk.isChecked():
                self.bigPlot.show_hits(
                    self._hits_x, self._hits_y,
                    label=f"Live Hits ({len(self._hits_x)})"
                )
                self._update_viewport()

            if self.phdChk.isChecked():
                self.phdPlot.show_hist(
                    self._phd_samples,
                    bins=256,
                    range_=(0, 256),
                    label="PHD",
                )

        # Status bar updates are cheap — do every tick
        self.detEventsLbl.setText(f"Det Events: {self._det_events}")
        self.countsLbl.setText(f"Counts: {len(self._hits_x)}")
        remaining = max(0, self._MAX_DURATION - elapsed)
        self.secondsStatusLbl.setText(f"Time left: {remaining:.1f}s")

    def start_acquire(self):
        settings = self.get_settings()
        settings["timestamp"] = int(time.time())
        print(settings)

        # Clear previous data
        self._hits_x = np.array([])
        self._hits_y = np.array([])
        self._phd_samples = np.array([])
        self._det_events = 0
        self._tick_count = 0
        self._acq_start_time = time.time()
        self.bigPlot.clear_axes()
        self.phdPlot.clear_axes()

        self.acquireBtn.setEnabled(False)
        self.stopBtn.setEnabled(True)
        self.statusBar().showMessage("Acquiring...", 2000)
        self._acq_timer.start()

    def stop_acquire(self):
        self._acq_timer.stop()
        self.acquireBtn.setEnabled(True)
        self.stopBtn.setEnabled(False)
        self.secondsStatusLbl.setText(f"Seconds: {self.seconds.value()}")

        # Final redraw with all data
        if len(self._hits_x) > 0:
            self.bigPlot.show_hits(
                self._hits_x, self._hits_y,
                label=f"Total Hits ({len(self._hits_x)})"
            )
            self._update_viewport()

        self.statusBar().showMessage(
            f"Stopped — {len(self._hits_x)} total hits collected.", 5000
        )
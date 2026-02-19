# plots.py
# -*- coding: utf-8 -*-

import numpy as np
from PyQt5 import QtCore, QtGui, QtWidgets
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure


class PlotPlaceholder(QtWidgets.QFrame):
    def __init__(self, ticks=(0, 2048, 4096), parent=None):
        super().__init__(parent)
        self.ticks = ticks
        self.setMinimumSize(320, 240)
        self.setFrameShape(QtWidgets.QFrame.NoFrame)
        self.setStyleSheet("background-color: #000;")

        self._left_margin = 44
        self._right_margin = 12
        self._top_margin = 12
        self._bottom_margin = 26

    def sizeHint(self):
        return QtCore.QSize(640, 480)

    def _plot_rect(self):
        r = self.rect()
        return QtCore.QRect(
            r.left() + self._left_margin,
            r.top() + self._top_margin,
            max(1, r.width() - (self._left_margin + self._right_margin)),
            max(1, r.height() - (self._top_margin + self._bottom_margin)),
        )

    def _map(self, val, v0, v1, p0, p1):
        if v1 == v0:
            return p0
        t = (val - v0) / (v1 - v0)
        return p0 + t * (p1 - p0)

    def paintEvent(self, event):
        super().paintEvent(event)
        p = QtGui.QPainter(self)
        p.setRenderHint(QtGui.QPainter.Antialiasing, False)

        plot = self._plot_rect()

        # border
        p.setPen(QtGui.QPen(QtGui.QColor("#bbbbbb"), 1))
        p.drawRect(plot)

        # grid
        p.setPen(QtGui.QPen(QtGui.QColor("#404040"), 1))
        for i in (1, 2):
            x = plot.left() + i * plot.width() // 3
            p.drawLine(x, plot.top(), x, plot.bottom())
            y = plot.top() + i * plot.height() // 3
            p.drawLine(plot.left(), y, plot.right(), y)

        p.setPen(QtGui.QColor("#bbbbbb"))
        font = p.font()
        font.setPointSize(9)
        p.setFont(font)

        vmin, vmax = self.ticks[0], self.ticks[-1]

        # Y labels
        for t in self.ticks:
            y = int(self._map(t, vmin, vmax, plot.bottom(), plot.top()))
            p.drawLine(plot.left() - 5, y, plot.left(), y)
            p.drawText(
                plot.left() - self._left_margin + 2,
                y - 8,
                self._left_margin - 8,
                16,
                QtCore.Qt.AlignRight | QtCore.Qt.AlignVCenter,
                str(t),
            )

        # X labels
        for t in self.ticks:
            x = int(self._map(t, vmin, vmax, plot.left(), plot.right()))
            p.drawLine(x, plot.bottom(), x, plot.bottom() + 5)
            p.drawText(
                x - 20,
                plot.bottom() + 6,
                40,
                self._bottom_margin - 6,
                QtCore.Qt.AlignHCenter | QtCore.Qt.AlignTop,
                str(t),
            )


class MplCanvas(FigureCanvas):
    def __init__(self, ticks=(0, 2048, 4096), parent=None):
        self.fig = Figure(figsize=(6, 4), tight_layout=True)
        super().__init__(self.fig)
        self.setParent(parent)

        self.setSizePolicy(
            QtWidgets.QSizePolicy.Expanding,
            QtWidgets.QSizePolicy.Expanding
        )
        self.updateGeometry()

        self.ax = self.fig.add_subplot(111)
        self.ticks = ticks
        self._init_axes()
        self._img = None
        self._line, = self.ax.plot([], [])
        self._hist_patches = None

    def _init_axes(self):
        self.ax.set_facecolor("#000000")
        self.ax.grid(True, linewidth=1, color="#404040")
        self.ax.tick_params(colors="#bbbbbb")
        for spine in self.ax.spines.values():
            spine.set_color("#bbbbbb")
        self.ax.set_xticks(self.ticks)
        self.ax.set_yticks(self.ticks)
        self.ax.set_xlim(self.ticks[0], self.ticks[-1])
        self.ax.set_ylim(self.ticks[0], self.ticks[-1])

    def clear_axes(self):
        self.ax.cla()
        self._init_axes()
        self._img = None
        self._line, = self.ax.plot([], [])
        self._hist_patches = None
        self.draw_idle()

    def show_line(self, x, y, label=None):
        self.clear_axes()
        self._line.set_data(x, y)
        self.ax.add_line(self._line)
        if label:
            self.ax.legend([label])
        self.ax.relim()
        self.ax.autoscale_view()
        self.draw_idle()

    def show_hist(self, data, bins=256, range_=None, label=None, step=True):
        """Histogram (used for the PHD plot)."""
        self.clear_axes()

        histtype = "step" if step else "bar"
        self._hist_patches = self.ax.hist(
            data,
            bins=bins,
            range=range_,
            histtype=histtype,
            linewidth=1.2,
        )

        # Make sure x-axis matches the specified range
        if range_ is not None:
            self.ax.set_xlim(range_[0], range_[1])

        # Start y at 0 and let matplotlib auto-pick the top
        self.ax.set_ylim(bottom=0)

        if label:
            self.ax.legend([label])

        self.draw_idle()


    def show_hits(self, x, y, label=None):
        """Scatter for detector hits (spiral)."""
        self.clear_axes()
        self.ax.scatter(x, y, s=5, c="yellow", marker=".", linewidths=0)
        if label:
            self.ax.set_title(label, color="#bbbbbb")
        self.ax.set_xlim(0, 4096)
        self.ax.set_ylim(0, 4096)
        self.draw_idle()

    def show_heatmap(self, img2d, vmin=None, vmax=None, extent=None):
        # kept as placeholder if you later want a real heatmap
        pass

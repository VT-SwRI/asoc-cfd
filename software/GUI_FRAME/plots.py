# plots.py
# -*- coding: utf-8 -*-

import numpy as np
from PyQt5 import QtCore, QtGui, QtWidgets
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
import pyqtgraph as pg
from PyQt5.QtGui import QTransform

class HeatmapWidget(QtWidgets.QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)

        layout = QtWidgets.QVBoxLayout(self)

        # Graphics view
        self.view = pg.GraphicsLayoutWidget()
        layout.addWidget(self.view)

        # Plot
        self.plot = self.view.addPlot()
        self.plot.setLabel('left', 'Y-Position')
        self.plot.setLabel('bottom', 'X-Position')
        # self.plot.setAspectLocked(True, ratio = 1)

        # Image item
        self.img = pg.ImageItem()
        self.plot.addItem(self.img)

        # Colormap
        self.cmap = pg.colormap.get("magma")
        self.img.setColorMap(self.cmap)

        # Colorbar
        self.cbar = pg.ColorBarItem(colorMap=self.cmap)
        self.cbar.setImageItem(self.img)
        self.view.addItem(self.cbar)

        # Track current downsample factor
        self.factor = 1

        # Optional: lock initial levels (prevents flicker)
        self.img.setLevels((0, 10))

    def set_image(self, image, x, y, factor=1):

        self.factor = factor
        sx = x / image.shape[1]
        sy = y / image.shape[0]
        
        # Update image
        self.img.setImage(image.T, autoLevels=True)

        t = QTransform()
        t.scale(sx, sy)
        t.translate(-image.shape[1] / 2, -image.shape[0] / 2)
        self.img.setTransform(t)

    def auto_levels(self):
        self.img.setImage(self.img.image, autoLevels=True)

    def set_levels(self, vmin, vmax):
        self.img.setLevels((vmin, vmax))

    def clear(self):
        if self.img.image is not None:
            self.img.setImage(np.zeros_like(self.img.image), autoLevels=False)


class MplCanvas(FigureCanvas):
    def __init__(self, ticks=(0, 2048, 4096), xLabel = "", yLabel = "", title = "", parent=None, ):
        self.fig = Figure(figsize=(6, 4), tight_layout=True)
        super().__init__(self.fig)
        self.setParent(parent)

        self.setSizePolicy(
            QtWidgets.QSizePolicy.Expanding,
            QtWidgets.QSizePolicy.Expanding
        )
        self.updateGeometry()
        self.xLabel = xLabel
        self.yLabel = yLabel
        self.ax = self.fig.add_subplot(111)
        self.x = []
        self.y = []
        self.ticks = ticks
        self._init_axes()
        self._img = None
        self._line, = self.ax.plot([], [])
        self._hist_patches = None
        self.title = title
        self.ax.set_title(title)

    def _init_axes(self):
        self.ax.set_facecolor("#000000")
        self.ax.grid(True, linewidth=1, color="#999999")
        self.ax.tick_params(colors="#555555")
        for spine in self.ax.spines.values():
            spine.set_color("#000000")
        self.ax.set_xticks(self.ticks)
        self.ax.set_yticks(self.ticks)
        self.ax.set_xlim(self.ticks[0], self.ticks[-1])
        self.ax.set_ylim(self.ticks[0], self.ticks[-1])
        self.ax.set_xlabel(self.xLabel)
        self.ax.set_ylabel(self.yLabel)

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
        # self.ax.autoscale_view()
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

        self.ax.set_title(self.title)
        self.draw_idle()


    def show_heatmap(self, img2d, vmin=None, vmax=None, extent=None):
        # kept as placeholder if you later want a real heatmap
        self.ax.imshow(img2d, origin = "lower", cmap="gray")
        self.draw_idle()

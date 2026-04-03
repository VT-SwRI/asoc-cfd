import numpy as np
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot
import h5py
import os
from astropy.io import fits
from datetime import datetime
import time
    
DEBUG = 1


class ImageWriter(QObject):
    finished = pyqtSignal()
    image_ready = pyqtSignal(object, object, object)
    def __init__(self, save_folder, listType, save = False, nx=4096, ny=4096, x = 102000, y = 102000):
        super().__init__()
        self.nx = nx
        self.ny = ny
        self.x = x
        self.y = y
        self.xmin = -x / 2
        self.xmax = x / 2
        self.ymin = -y / 2
        self.refresh = 1/30
        self.ymax = y / 2
        self.save = save
        self.scale = 1
        if np.max([nx, ny]) > 1024:
            self.scale = np.max([nx, ny]) / 1024

        self.dx = (nx) / (self.xmax - self.xmin)
        self.dy = (ny) / (self.ymax - self.ymin)
        self.running = False
        self.type = listType
        self.ref = time.time()
        tstamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.filename = os.path.join(save_folder, f"run_{tstamp}.fits")

    @pyqtSlot()
    def start(self):
        self.image = np.zeros((self.ny, self.nx), dtype = np.uint32)
        self.running = True
        if self.save:
            print(f"\nImage writer started, writing to {self.filename}")
        else:
            print("\nImage writer started")

    @pyqtSlot()
    def stop(self):
        self.running = False
        if self.save:
            self.save_file()
        self.finished.emit()
        print("\nImage writer stopped")

    @pyqtSlot()
    def save_file(self):
        hdu = fits.PrimaryHDU(self.image)
        hdu.header['XMIN'] = self.xmin
        hdu.header['YMIN'] = self.ymin
        hdu.header['XMAX'] = self.xmax
        hdu.header['YMAX'] = self.ymax
        hdu.writeto(self.filename, overwrite = True)
        

    @pyqtSlot(object)
    def writeBatch(self, batch):
        x = batch['xpos']
        y = batch['ypos']
        xp = ((x - self.xmin) * self.dx).astype(np.int32)
        yp = ((y - self.ymin) * self.dy).astype(np.int32)

        mask = ((xp >= 0) & (xp < self.nx) & (yp >= 0) & (yp < self.ny))

        xp = xp[mask]
        yp = yp[mask]
        np.add.at(self.image, (yp, xp), 1)
        if (time.time() - self.ref) >= self.refresh: 
            self.ref = time.time()
            img = self.downsample(self.scale)
            self.image_ready.emit(img.copy(), self.x, self.y)
    
    def downsample(self, scale):
        scale = int(scale)
        h, w = self.image.shape

        h2 = h - h % scale
        w2 = w - w % scale

        img = self.image[:h2, :w2]

        return img.reshape(
            h2 // scale, scale,
            w2 // scale, scale
        ).sum(axis=(1, 3)) 



class ListWriter(QObject):
    finished = pyqtSignal()

    def __init__(self, save_folder, listType):
        super().__init__()
        self.type = listType
        self.file = None
        self.data = None

        # create a timestamp for the file being created
        tstamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.filename = os.path.join(save_folder, f"run_{tstamp}.h5")

    @pyqtSlot()
    def start(self):
        self.file = h5py.File(self.filename, "w")
        self.data = self.file.create_dataset(
            "photons",
            shape=(0,),
            maxshape=(None,),
            dtype=self.type,
            chunks=(20000,),
            compression="lzf"
        )
        print(f"\nList writer started, writing to {self.filename}")

    @pyqtSlot(object)
    def writeBatch(self, batch):
        old = self.data.shape[0]
        new = old + len(batch)
        self.data.resize((new,))
        self.data[old:new] = batch

    @pyqtSlot()
    def stop(self):
        if self.file:
            self.file.flush()
            self.file.close()
        self.finished.emit()
        print("\nList writer stopped")


def main():
    file = os.getcwd()
    file = os.path.join(file, "run_20260326_171148.h5")
    print(file)

    with h5py.File(file, "r") as f:
        print("Keys in file:")
        print(list(f.keys()))

        dset = f["photons"]

        print("\nDataset shape:", dset.shape)
        print("Dataset dtype:", dset.dtype)

        print("\nFirst 5 photons:")
        print(dset[:5])

if __name__ == "__main__":
    main()
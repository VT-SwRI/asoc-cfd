import numpy as np
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot
import h5py
import os


# class ImageWriter(QObject):
    

class ListWriter(QObject):
    finished = pyqtSignal()

    def __init__(self, filename, listType):
        super().__init__()
        self.filename = filename
        self.type = listType
        self.file = None
        self.data = None

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

    @pyqtSlot()
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
        print("writer worker stopped")


def main():
    file = os.getcwd()
    file = os.path.join(file, "test.h5")
    print(file)
    t = np.dtype([
        ('xpos', 'f4'),
        ('ypos', 'f4'),
        ('time', 'f8'),
        ('magnitude', 'f4')
    ])
    w = ListWriter(file, t)
    batch = np.array([
    (12.3, 45.6, 1.234e-6, 98.2),
    (13.1, 44.9, 1.238e-6, 102.4),
    (11.8, 46.2, 1.240e-6, 87.5),
    (14.0, 45.1, 1.242e-6, 110.0),
    (12.7, 45.8, 1.245e-6, 95.3)
], dtype=t)
    
    w.start()
    
    w.writeBatch(batch)
    w.stop


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
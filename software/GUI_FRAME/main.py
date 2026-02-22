# main.py
# -*- coding: utf-8 -*-

import sys
from PyQt5 import QtWidgets
from main_window import EtherDAQMock


def main():
    app = QtWidgets.QApplication(sys.argv)
    app.setApplicationName("EtherDaq Mock")

    f = app.font()
    f.setPointSize(f.pointSize() + 1)
    app.setFont(f)

    win = EtherDAQMock()
    win.show()
    sys.exit(app.exec_())


if __name__ == "__main__":
    main()

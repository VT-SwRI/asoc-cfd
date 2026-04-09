import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import socket

def main():
    

    # mag = np.array([0, 10000])
    # mag = (mag.astype(np.int32) + 32768) >> 8
    # mag = np.bincount(mag, minlength = 256)
    # print(mag)
    pulse = pd.read_csv('pulse.csv', header = None).values
    pulse = pulse.flatten()

    plt.plot(pulse)
    plt.show()

    prev = pulse[0]
    best = 0
    sample = pulse[0]
    for x in pulse:
        slope = x - prev
        prev = x
        if slope < best:
            best = slope
            sample = x
    

    packet_type = 2  # must be 0–3
    arr = pulse

    # pack into 1 byte (only lower 2 bits used)
    header = np.uint8(packet_type & 0x03).tobytes()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    sock.sendto(header + arr.tobytes(), ("127.0.0.1", 562))


if __name__ == "__main__":
    main()


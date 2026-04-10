"""
uart_transfer.py — Send a 149-bit config value to the FPGA, built from
                   individual named fields.

Packed bit layout (bit 148 = MSB, sent first):
  [148:135]  14-bit  attenuation    (Q0.13 signed,   default 0)
  [134:128]   7-bit  delay          (unsigned 1-127,  default 0)
  [127:112]  16-bit  threshold      (SQ12.3 signed,   default 0)
  [111:104]   8-bit  zc_neg_samples (unsigned,        default 0)
  [103: 84]  20-bit  kx             (UQ1.19 unsigned, default 0)
  [ 83: 64]  20-bit  ky             (UQ1.19 unsigned, default 0)
  [  63:  0]  64-bit  timestamp      (unsigned,        default 0)

TX (PC → FPGA):  19 bytes  (149-bit payload left-shifted by 3, big-endian MSB first)
RX (FPGA → PC):  18 bytes  (144-bit result, big-endian MSB first) [optional]

Usage:
    python uart_transfer.py --list-ports
    python uart_transfer.py --port COM3 --zc 255
    python uart_transfer.py --port COM3 --zc 255 --delay 10 --threshold 512
    python uart_transfer.py --port COM3 --attenuation 1 --delay 5 --threshold 100 \
                                        --zc 200 --kx 1 --ky 1 --timestamp 12345

Requires: pyserial  →  pip install pyserial
"""

import serial
import serial.tools.list_ports
import argparse
import sys
import time
import numpy as np

# ── constants ──────────────────────────────────────────────────────────────────
DEFAULT_BAUD    = 115200
DEFAULT_TIMEOUT = 10
TX_BYTES        = 19       # 152 bits on the wire (149-bit payload + 3 padding LSBs)
RX_BYTES        = 18       # 144-bit result from bridge_fsm (optional read-back)

# Field widths and LSB positions within the 149-bit word
FIELDS = {
    #  name            (width,  lsb)
    "attenuation":     (14,     135),
    "delay":           ( 7,     128),
    "threshold":       (16,     112),
    "zc_neg_samples":  ( 8,     104),
    "kx":              (20,      84),
    "ky":              (20,      64),
    "timestamp":       (64,       0),
}
# ──────────────────────────────────────────────────────────────────────────────


def list_ports():
    ports = serial.tools.list_ports.comports()
    if not ports:
        print("No serial ports found.")
    else:
        print("Available serial ports:")
        for p in ports:
            print(f"  {p.device:20s}  {p.description}")


def build_149(attenuation, delay, threshold, zc_neg_samples, kx, ky, timestamp) -> int:
    """Pack individual fields into a 149-bit integer."""
    # Mask each value to its field width then place it at the correct bit position
    value = 0
    args = {
        "attenuation":    attenuation,
        "delay":          delay,
        "threshold":      threshold,
        "zc_neg_samples": zc_neg_samples,
        "kx":             kx,
        "ky":             ky,
        "timestamp":      timestamp,
    }
    for name, (width, lsb) in FIELDS.items():
        mask = (1 << width) - 1
        value |= (args[name] & mask) << lsb
    return value


def pack_for_uart(value_149: int) -> bytes:
    """
    The UART RX FSM collects 19 bytes then drops the bottom 3 bits of the
    last byte to produce a 149-bit word.  So we left-shift our 149-bit
    payload by 3 before packing into 19 bytes.
    """
    value_152 = value_149 << 3
    return value_152.to_bytes(TX_BYTES, byteorder='big')


def print_fields(attenuation, delay, threshold, zc_neg_samples, kx, ky, timestamp):
    print(f"  attenuation    : {attenuation}  (14-bit, Q0.13 signed)")
    print(f"  delay          : {delay}  (7-bit unsigned)")
    print(f"  threshold      : {threshold}  (16-bit, SQ12.3 signed)")
    print(f"  zc_neg_samples : {zc_neg_samples}  (8-bit unsigned)  ← LEDs")
    print(f"  kx             : {kx}  (20-bit, UQ1.19 unsigned)")
    print(f"  ky             : {ky}  (20-bit, UQ1.19 unsigned)")
    print(f"  timestamp      : {timestamp}  (64-bit unsigned)")


def unpack_response(data: bytes) -> dict:
    """Parse the 18-byte bridge_fsm echo into named fields."""
    tag = int.from_bytes(data[0:8],   byteorder='big', signed=False)
    x   = int.from_bytes(data[8:12],  byteorder='big', signed=True)
    y   = int.from_bytes(data[12:16], byteorder='big', signed=True)
    mag = int.from_bytes(data[16:18], byteorder='big', signed=True)
    return {"tag": tag, "x": x, "y": y, "mag": mag}


def send_config(port: str, baud: int, tx_bytes: bytes, value_149: int, timeout: float):
    print(f"\n{'─'*60}")
    print(f"Port          : {port}  @  {baud} baud")
    print(f"149-bit value : 0x{value_149:038X}")
    print(f"Bytes on wire : {tx_bytes.hex(' ').upper()}")
    print(f"{'─'*60}")

    with serial.Serial(port, baudrate=baud, timeout=timeout) as ser:
        ser.reset_input_buffer()
        ser.reset_output_buffer()
        time.sleep(0.1)

        written = ser.write(tx_bytes)
        ser.flush()
        print(f"Wrote {written} byte(s) successfully.")

        # Optional: try to read back an 18-byte response from bridge_fsm
        rx = ser.read(RX_BYTES)

    if len(rx) == RX_BYTES:
        fields = unpack_response(rx)
        print(f"\nFPGA response ({RX_BYTES} bytes):")
        print(f"  Bytes : {rx.hex(' ').upper()}")
        print(f"  tag   : 0x{fields['tag']:016X}")
        print(f"  x     : {fields['x']}")
        print(f"  y     : {fields['y']}")
        print(f"  mag   : {fields['mag']}")
    else:
        print(f"\n(No TX response from FPGA — {len(rx)}/{RX_BYTES} bytes received, this is expected if TX is disabled.)")

    print(f"{'─'*60}")



def sendStart(port, frac, delay, thresh, zc, kx, ky, t, timeout):
    ser = serial.Serial(port=port, baudrate=115200, timeout=timeout)
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    time.sleep(0.1)

    fracQ = int(float_to_fixed(frac, 0, 13, True))
    delayQ = int(delay)
    threshQ = int(float_to_fixed(thresh, 12, 3, True))
    kxQ = int(float_to_fixed(kx, 1, 19, False))
    kyQ = int(float_to_fixed(ky, 1, 19, False))
    zcQ = int(zc)
    timeQ = int(t)

    packet = 0

    packet |= (timeQ & 0xFFFFFFFFFFFFFFFF) << 0
    packet |= (kyQ & 0xFFFFF) << 64
    packet |= (kxQ & 0xFFFFF) << 84
    packet |= (zcQ & 0xFF) << 104
    packet |= (threshQ & 0xFFFF) << 111
    packet |= (delayQ & 0xFF) << 127
    packet |= (fracQ & 0x3FFF) << 135

    packBytes = packet.to_bytes(19, byteorder = 'big')

    written = ser.write(packBytes)
    print(packBytes.hex(' ').upper())
    print(f"Wrote {written} byte(s) successfully.")
    # Optional: try to read back an 18-byte response from bridge_fsm
    rx = ser.read(RX_BYTES)

    if len(rx) == RX_BYTES:
        fields = unpack_response(rx)
        print(f"\nFPGA response ({RX_BYTES} bytes):")
        print(f"  Bytes : {rx.hex(' ').upper()}")
        print(f"  tag   : 0x{fields['tag']:016X}")
        print(f"  x     : {fields['x']}")
        print(f"  y     : {fields['y']}")
        print(f"  mag   : {fields['mag']}")
    else:
        print(f"\n(No TX response from FPGA — {len(rx)}/{RX_BYTES} bytes received, this is expected if TX is disabled.)")

def fixed_to_float(num, Qint, Qfrac, sgn):
    len = Qint + Qfrac + (1 if sgn else 0)

    num &= (1 << len) - 1

    if sgn:
        if num & (1 << (len - 1)):
            num -= (1 << len)

    Q = 1 << Qfrac
    return float(num) / float(Q)

def float_to_fixed(num, Qint, Qfrac, sgn):
    Q = 1 << Qfrac
    val = qRound(num * Q)
    len = Qint + Qfrac + (1 if sgn else 0)
    if sgn:
        min_val = -(1 << (len - 1))
        max_val = (1 << (len - 1)) - 1
    else:
        min_val = 0
        max_val = (1 << len) - 1

    val = max(min_val, min(max_val, val))
    return val

def qRound(num):
    return int(np.floor(num + 0.5)) if num >= 0 else int(np.ceil(num - 0.5))


def main():
    parser = argparse.ArgumentParser(
        description="Send a 149-bit FPGA config built from individual named fields."
    )
    parser.add_argument("--port",  "-p", default=None,
                        help="Serial port (e.g. COM3 or /dev/ttyUSB0).")
    parser.add_argument("--baud",  "-b", type=int, default=DEFAULT_BAUD,
                        help=f"Baud rate (default: {DEFAULT_BAUD})")
    parser.add_argument("--timeout", "-t", type=float, default=DEFAULT_TIMEOUT,
                        help=f"Read timeout in seconds (default: {DEFAULT_TIMEOUT})")
    parser.add_argument("--list-ports", "-l", action="store_true",
                        help="Print available serial ports and exit.")

    # One argument per config field
    parser.add_argument("--attenuation",    type=float, default=0,
                        help="14-bit attenuation (Q0.13 signed, default 0)")
    parser.add_argument("--delay",          type=int, default=0,
                        help="7-bit delay (unsigned 0-127, default 0)")
    parser.add_argument("--threshold",      type=int, default=0,
                        help="16-bit threshold (SQ12.3 signed, default 0)")
    parser.add_argument("--zc",             type=int, default=0,
                        dest="zc_neg_samples",
                        help="8-bit zc_neg_samples (unsigned 0-255, default 0) — drives LEDs")
    parser.add_argument("--kx",             type=int, default=0,
                        help="20-bit kx (UQ1.19 unsigned, default 0)")
    parser.add_argument("--ky",             type=int, default=0,
                        help="20-bit ky (UQ1.19 unsigned, default 0)")
    parser.add_argument("--timestamp",      type=int, default=0,
                        help="64-bit timestamp (unsigned, default 0)")

    args = parser.parse_args()

    if args.list_ports or args.port is None:
        list_ports()
        if args.port is None:
            print("\nRe-run with --port <device> to send config.")
            sys.exit(0)

    print("\nConfig fields being sent:")
    print_fields(args.attenuation, args.delay, args.threshold, args.zc_neg_samples, args.kx, args.ky, args.timestamp)

    # value_149 = build_149(attenuation, delay, threshold, zc_neg_samples, kx, ky, timestamp)
    # tx_bytes  = pack_for_uart(value_149)

    # send_config(args.port, args.baud, tx_bytes, value_149, args.timeout)
    sendStart(args.port, float(args.attenuation), float(args.delay), float(args.threshold),
               float(args.zc_neg_samples), float(args.kx), float(args.ky), float(args.timestamp), args.timeout)


if __name__ == "__main__":
    main()
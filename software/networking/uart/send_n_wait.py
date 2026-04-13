"""
uart_transfer.py — Send a 149-bit config value to the FPGA, then open a
                   live serial terminal showing everything the FPGA sends back.

Packed bit layout (bit 148 = MSB, sent first):
  [148:135]  14-bit  attenuation    (Q0.13 signed,   default 0)
  [134:128]   7-bit  delay          (unsigned 1-127,  default 0)
  [127:112]  16-bit  threshold      (SQ12.3 signed,   default 0)
  [111:104]   8-bit  zc_neg_samples (unsigned,        default 0)
  [103: 84]  20-bit  kx             (UQ1.19 unsigned, default 0)
  [ 83: 64]  20-bit  ky             (UQ1.19 unsigned, default 0)
  [  63:  0]  64-bit  timestamp      (unsigned,        default 0)

TX (PC → FPGA):  19 bytes  (149-bit payload, big-endian MSB first)
RX (FPGA → PC):  live terminal — every 18-byte packet is decoded and printed.
                 Press Ctrl+C to exit.

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
import threading
import numpy as np

# ── constants ──────────────────────────────────────────────────────────────────
DEFAULT_BAUD    = 800000
DEFAULT_TIMEOUT = 1          # short timeout so the RX thread can loop/check exit
TX_BYTES        = 19
RX_BYTES        = 18         # one bridge_fsm packet = 18 bytes

# ──────────────────────────────────────────────────────────────────────────────


def list_ports():
    ports = serial.tools.list_ports.comports()
    if not ports:
        print("No serial ports found.")
    else:
        print("Available serial ports:")
        for p in ports:
            print(f"  {p.device:20s}  {p.description}")


# ── fixed-point helpers ───────────────────────────────────────────────────────

def qRound(num):
    return int(np.floor(num + 0.5)) if num >= 0 else int(np.ceil(num - 0.5))

def float_to_fixed(num, Qint, Qfrac, sgn):
    Q   = 1 << Qfrac
    val = qRound(num * Q)
    bits = Qint + Qfrac + (1 if sgn else 0)
    min_val = -(1 << (bits - 1)) if sgn else 0
    max_val = (1 << (bits - 1)) - 1 if sgn else (1 << bits) - 1
    return max(min_val, min(max_val, val))

def fixed_to_float(num, Qint, Qfrac, sgn):
    bits = Qint + Qfrac + (1 if sgn else 0)
    num &= (1 << bits) - 1
    if sgn and (num & (1 << (bits - 1))):
        num -= (1 << bits)
    return float(num) / float(1 << Qfrac)


# ── packet builder (unchanged from original sendStart logic) ──────────────────

def build_packet(frac, delay, thresh, zc, kx, ky, t) -> bytes:
    fracQ   = int(float_to_fixed(frac,   0, 13, True))
    delayQ  = int(delay)
    threshQ = int(float_to_fixed(thresh, 12, 3, True))
    kxQ     = int(float_to_fixed(kx,     1, 19, False))
    kyQ     = int(float_to_fixed(ky,     1, 19, False))
    zcQ     = int(zc)
    timeQ   = int(t)

    packet = 0
    packet |= (timeQ  & 0xFFFFFFFFFFFFFFFF) << 0
    packet |= (kyQ    & 0xFFFFF)            << 64
    packet |= (kxQ    & 0xFFFFF)            << 84
    packet |= (zcQ    & 0xFF)               << 104
    packet |= (threshQ & 0xFFFF)            << 111
    packet |= (delayQ & 0xFF)               << 127
    packet |= (fracQ  & 0x3FFF)             << 135

    return packet.to_bytes(TX_BYTES, byteorder='big')


# ── RX terminal ───────────────────────────────────────────────────────────────

def unpack_response(data: bytes) -> dict:
    """Parse one 18-byte bridge_fsm packet into named fields."""
    tag = int.from_bytes(data[0:8],  byteorder='big', signed=False)
    x   = int.from_bytes(data[8:12],  byteorder='big', signed=True)
    y   = int.from_bytes(data[12:16], byteorder='big', signed=True)
    mag = int.from_bytes(data[16:18], byteorder='big', signed=True)
    return {"tag": tag, "x": x, "y": y, "mag": mag}


def rx_terminal(ser: serial.Serial, stop_event: threading.Event):
    """
    Runs in a background thread.  Accumulates bytes from the FPGA and prints
    a decoded line every time a complete 18-byte packet arrives.
    Any leftover bytes that don't fill a packet are shown as a raw hex dump
    when you hit Ctrl+C so nothing is silently lost.
    """
    buf = bytearray()
    pkt_count = 0

    print("\n" + "═"*60)
    print("  FPGA serial terminal  —  Ctrl+C to exit")
    print("  Decoding 18-byte bridge_fsm packets")
    print("═"*60)

    while not stop_event.is_set():
        try:
            chunk = ser.read(ser.in_waiting or 1)
        except serial.SerialException as e:
            print(f"\n[serial error: {e}]")
            break

        if not chunk:
            continue

        buf.extend(chunk)

        # Decode every complete 18-byte packet in the buffer
        while len(buf) >= RX_BYTES:
            packet_bytes = bytes(buf[:RX_BYTES])
            buf = buf[RX_BYTES:]
            pkt_count += 1

            fields = unpack_response(packet_bytes)
            raw_hex = packet_bytes.hex(' ').upper()

            print(f"\n[pkt #{pkt_count}]  raw: {raw_hex}")
            print(f"  tag : 0x{fields['tag']:016X}  ({fields['tag']})")
            print(f"  x   : {fields['x']}")
            print(f"  y   : {fields['y']}")
            print(f"  mag : {fields['mag']}")

    # Flush any leftover bytes that didn't form a complete packet
    if buf:
        print(f"\n[leftover {len(buf)} byte(s)]: {buf.hex(' ').upper()}")


# ── main send + terminal ──────────────────────────────────────────────────────

def run(port, baud, timeout, frac, delay, thresh, zc, kx, ky, t):
    tx_bytes = build_packet(frac, delay, thresh, zc, kx, ky, t)

    print("\nConfig fields being sent:")
    print(f"  attenuation    : {frac}  → Q0.13  = {int(float_to_fixed(frac, 0, 13, True))}")
    print(f"  delay          : {delay}")
    print(f"  threshold      : {thresh}  → SQ12.3 = {int(float_to_fixed(thresh, 12, 3, True))}")
    print(f"  zc_neg_samples : {zc}")
    print(f"  kx             : {kx}  → UQ1.19 = {int(float_to_fixed(kx, 1, 19, False))}")
    print(f"  ky             : {ky}  → UQ1.19 = {int(float_to_fixed(ky, 1, 19, False))}")
    print(f"  timestamp      : {t}")
    print(f"\nBytes on wire ({TX_BYTES}): {tx_bytes.hex(' ').upper()}")

    ser = serial.Serial(port=port, baudrate=baud, timeout=timeout)
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    time.sleep(0.1)

    written = ser.write(tx_bytes)
    ser.flush()
    print(f"Wrote {written} byte(s) to {port} @ {baud} baud.")

    # Start RX terminal in background thread
    stop_event = threading.Event()
    rx_thread  = threading.Thread(target=rx_terminal, args=(ser, stop_event), daemon=True)
    rx_thread.start()

    try:
        while rx_thread.is_alive():
            rx_thread.join(timeout=0.5)
    except KeyboardInterrupt:
        print("\n\n[Ctrl+C — closing port...]")
        stop_event.set()
        rx_thread.join(timeout=2)

    ser.close()
    print("[Port closed. Goodbye.]")


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Send a 149-bit FPGA config then display a live RX terminal."
    )
    parser.add_argument("--port",    "-p", default=None)
    parser.add_argument("--baud",    "-b", type=int,   default=115200)
    parser.add_argument("--timeout", "-t", type=float, default=DEFAULT_TIMEOUT)
    parser.add_argument("--list-ports", "-l", action="store_true")

    parser.add_argument("--attenuation", type=float, default=0,
                        help="Q0.13 signed float  (e.g. 0.5)")
    parser.add_argument("--delay",       type=int,   default=0,
                        help="7-bit unsigned int   (0-127)")
    parser.add_argument("--threshold",   type=float, default=0,
                        help="SQ12.3 signed float  (e.g. 100.0)")
    parser.add_argument("--zc",          type=int,   default=0,
                        dest="zc_neg_samples",
                        help="8-bit unsigned int   (0-255)")
    parser.add_argument("--kx",          type=float, default=0,
                        help="UQ1.19 unsigned float (e.g. 1.0)")
    parser.add_argument("--ky",          type=float, default=0,
                        help="UQ1.19 unsigned float (e.g. 1.0)")
    parser.add_argument("--timestamp",   type=int,   default=0,
                        help="64-bit unsigned int")

    args = parser.parse_args()

    if args.list_ports or args.port is None:
        list_ports()
        if args.port is None:
            print("\nRe-run with --port <device> to send config.")
            sys.exit(0)

    run(
        port    = args.port,
        baud    = args.baud,
        timeout = args.timeout,
        frac    = args.attenuation,
        delay   = args.delay,
        thresh  = args.threshold,
        zc      = args.zc_neg_samples,
        kx      = args.kx,
        ky      = args.ky,
        t       = args.timestamp,
    )


if __name__ == "__main__":
    main()
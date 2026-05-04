#!/usr/bin/env python3

import struct
import csv
import argparse
import re
import sys
import time
from pathlib import Path


PORT = "COM3"          # change this to match your serial port
BAUD = 921600
TIMEOUT = 0.01
HEADER = 0xAA
FOOTER = 0x55
EXPECTED_REPLY_LEN = 0  # set to 18 to capture DSP replies (AA + tag(8) + x(4) + y(4) + mag(2) + 55-style frames)
INTER_PACKET_DELAY = 0.01

# Folder that holds named hex files like hexdata/bird.hex, hexdata/giraffe.hex, ...
SCRIPT_DIR   = Path(__file__).parent
HEXDATA_DIR  = SCRIPT_DIR / "hexdata"

# Flags that must NOT be rewritten as positional args by normalize_argv().
KNOWN_FLAGS = {"-h", "--help", "--dry-run", "--list"}


def list_available_names() -> list[str]:
    """Return sorted stems of every .hex file found in hexdata/."""
    if not HEXDATA_DIR.is_dir():
        return []
    return sorted(p.stem for p in HEXDATA_DIR.glob("*.hex"))


def resolve_hex_path(user_arg: str | None) -> Path:
    """
    Resolve which hex file to use.

    user_arg may be:
      - a bare name, e.g. 'bird'       -> hexdata/bird.hex
      - a filename, e.g. 'bird.hex'    -> hexdata/bird.hex
      - a real path (rel or abs) to any .hex file
      - None                            -> error (hex file is required)
    """
    if user_arg is None:
        available = list_available_names()
        hint = ", ".join(available) if available else "(none found in hexdata/)"
        raise FileNotFoundError(
            "no hex file specified.\n"
            f"Available names in {HEXDATA_DIR.name}/: {hint}\n"
            "Use e.g. `python uartsource.py bird` or `python uartsource.py --list`."
        )

    # 1. Explicit path that already exists (e.g. hexdata/bird.hex or ./foo.hex)
    path = Path(user_arg)
    if path.exists():
        return path

    # 2. Bare name -> look inside hexdata/
    candidate = HEXDATA_DIR / user_arg
    if candidate.suffix.lower() != ".hex":
        candidate = candidate.with_suffix(".hex")
    if candidate.exists():
        return candidate

    available = list_available_names()
    hint = ", ".join(available) if available else "(none found in hexdata/)"
    raise FileNotFoundError(
        f"could not resolve hex file from '{user_arg}'.\n"
        f"Available names in {HEXDATA_DIR.name}/: {hint}"
    )


def normalize_argv(argv: list[str]) -> list[str]:
    """
    Allow '-bird' or '--bird' style invocation in addition to plain 'bird'.
    Any dash-prefixed token that isn't a known flag, but whose stripped form
    matches a name in hexdata/ (or ends in .hex), is rewritten to the bare
    name so argparse treats it as the positional hex_file argument.
    """
    available = set(list_available_names())
    out: list[str] = []
    for tok in argv:
        if tok in KNOWN_FLAGS or not tok.startswith("-"):
            out.append(tok)
            continue
        stripped = tok.lstrip("-")
        if stripped in available or stripped.lower().endswith(".hex"):
            out.append(stripped)
        else:
            out.append(tok)
    return out


def parse_metadata(lines: list[str]) -> dict[str, int]:
    metadata: dict[str, int] = {}

    for raw in lines:
        line = raw.strip()
        if not line.startswith("//"):
            continue

        m = re.search(r"Events:\s*(\d+)\s*,\s*Samples/event:\s*(\d+)\s*,\s*Idle gap:\s*(\d+)", line)
        if m:
            metadata["events"] = int(m.group(1))
            metadata["samples_per_event"] = int(m.group(2))
            metadata["idle_gap"] = int(m.group(3))

    return metadata


def decode_sample_word(word: int) -> tuple[int, int, int, int, int]:
    valid = (word >> 48) & 0x1
    x1 = (word >> 36) & 0xFFF
    x2 = (word >> 24) & 0xFFF
    y1 = (word >> 12) & 0xFFF
    y2 = word & 0xFFF
    return valid, x1, x2, y1, y2


def load_events_from_hex(path: Path) -> tuple[list[list[tuple[int, int, int, int]]], dict[str, int]]:
    lines = path.read_text().splitlines()
    metadata = parse_metadata(lines)

    events: list[list[tuple[int, int, int, int]]] = []
    current_event: list[tuple[int, int, int, int]] = []

    for lineno, raw in enumerate(lines, start=1):
        line = raw.strip()
        if not line or line.startswith("//"):
            continue

        if not re.fullmatch(r"[0-9A-Fa-f]{13}", line):
            raise ValueError(f"line {lineno}: expected 13 hex digits, got {line!r}")

        word = int(line, 16)
        valid, x1, x2, y1, y2 = decode_sample_word(word)

        if valid:
            current_event.append((x1, x2, y1, y2))
        else:
            if current_event:
                events.append(current_event)
                current_event = []

    if current_event:
        events.append(current_event)

    if not events:
        raise ValueError("no valid events were found in the hex file")

    expected_events = metadata.get("events")
    if expected_events is not None and expected_events != len(events):
        raise ValueError(
            f"metadata says {expected_events} events, but parser found {len(events)}"
        )

    expected_samples = metadata.get("samples_per_event")
    if expected_samples is not None:
        for idx, event in enumerate(events, start=1):
            if len(event) != expected_samples:
                raise ValueError(
                    f"event {idx} has {len(event)} samples, expected {expected_samples}"
                )

    return events, metadata


def pack_u12_be(value: int) -> bytes:
    if not (0 <= value <= 0xFFF):
        raise ValueError(f"value out of range: {value}")
    return bytes([(value >> 8) & 0xFF, value & 0xFF])


def build_packet(samples: list[tuple[int, int, int, int]]) -> bytes:
    pkt = bytearray()
    pkt.append(HEADER)

    sample_count = len(samples)
    pkt.append((sample_count >> 8) & 0xFF)
    pkt.append(sample_count & 0xFF)

    for x1, x2, y1, y2 in samples:
        pkt.extend(pack_u12_be(x1))
        pkt.extend(pack_u12_be(x2))
        pkt.extend(pack_u12_be(y1))
        pkt.extend(pack_u12_be(y2))

    pkt.append(FOOTER)
    return bytes(pkt)


def build_packets_from_hex(path: Path) -> tuple[list[bytes], list[list[tuple[int, int, int, int]]], dict[str, int]]:
    events, metadata = load_events_from_hex(path)
    packets = [build_packet(event) for event in events]
    return packets, events, metadata


def hex_bytes(data: bytes) -> str:
    return " ".join(f"{b:02X}" for b in data)


def transmit_packets(packets: list[bytes], expected_reply_len: int) -> list[bytes]:
    import serial

    replies: list[bytes] = []

    with serial.Serial(PORT, BAUD, timeout=TIMEOUT) as ser:
        time.sleep(0.2)
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        for idx, packet in enumerate(packets, start=1):
            ser.write(packet)
            ser.flush()

            reply = ser.read(expected_reply_len)
            replies.append(reply)

            print(f"TX packet {idx}: {len(packet)} bytes")
            print(hex_bytes(packet[:32]) + (" ..." if len(packet) > 32 else ""))
            print(f"RX packet {idx}: {len(reply)} bytes")
            print(hex_bytes(reply))
            print()

            if INTER_PACKET_DELAY > 0:
                time.sleep(INTER_PACKET_DELAY)

        write_fpga_csv(replies)

    return replies


def parse_dsp_reply(data: bytes) -> dict | None:
    """Parse an 18-byte DSP pipeline reply into tag, x, y, mag."""
    if len(data) != 18:
        return None
    tag = int.from_bytes(data[0:8], "big", signed=False)
    x   = int.from_bytes(data[8:12], "big", signed=True)
    y   = int.from_bytes(data[12:16], "big", signed=True)
    mag = int.from_bytes(data[16:18], "big", signed=True)
    return {"tag": tag, "x_microns": x, "y_microns": y, "mag": mag}


def write_fpga_csv(replies: list[bytes], path: str = "fpga_results.csv") -> None:
    """Parse all replies and write the CSV that CompareResults expects."""
    rows = []
    for idx, reply in enumerate(replies, start=1):
        parsed = parse_dsp_reply(reply)
        if parsed is None:
            print(f"  WARNING: event {idx} reply is {len(reply)} bytes, skipping")
            continue
        rows.append({
            "event_id":    idx,
            "x_microns":   parsed["x_microns"],
            "y_microns":   parsed["y_microns"],
            "charge_sum":  parsed["mag"],
        })

    with open(path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["event_id", "x_microns", "y_microns", "charge_sum"])
        writer.writeheader()
        writer.writerows(rows)

    print(f"\nWrote {len(rows)} events to {path}")


def main() -> None:
    # Make sure hexdata/ exists so --list doesn't crash on a fresh clone.
    HEXDATA_DIR.mkdir(parents=True, exist_ok=True)

    # Rewrite '-bird' / '--bird' into 'bird' before argparse sees it.
    argv = normalize_argv(sys.argv[1:])

    available = list_available_names()
    examples_block = (
        "Examples:\n"
        "  python uartsource.py bird          # send hexdata/bird.hex\n"
        "  python uartsource.py -bird         # same, dash-prefixed shorthand\n"
        "  python uartsource.py bird --dry-run  # preview packets, don't open serial\n"
        "  python uartsource.py --list        # list .hex names available in hexdata/"
    )

    parser = argparse.ArgumentParser(
        prog="uartsource.py",
        description=(
            "Transmit one UART packet per event from a hex file in the hexdata/ "
            "folder over the serial port to the FPGA, then collect replies.\n\n"
            "Hex files are produced by GenerateTestVectors.py and live in "
            "hexdata/<name>.hex. After transmission, replies are saved to "
            "fpga_results.csv in the current directory.\n\n"
            "IMPORTANT: the serial port (PORT) and baud rate (BAUD) are "
            "constants near the top of this script. Edit them to match your "
            "hardware before running (e.g. PORT='COM5' on Windows or "
            "PORT='/dev/ttyUSB0' on Linux/macOS).\n\n"
            "Part of the FPGA test workflow alongside GenerateTestVectors.py "
            "and CompareResults.py."
        ),
        epilog=examples_block,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "hex_file",
        nargs="?",
        default=None,
        help=(
            "name of a hex file in hexdata/ (e.g. 'bird' -> hexdata/bird.hex), "
            "or a full path to a .hex file. You can also prefix the name with "
            "a dash (e.g. -bird or --bird). Required unless using --list."
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="parse and print packet info without opening the serial port",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="list the hex files available in hexdata/ and exit",
    )
    args = parser.parse_args(argv)

    if args.list:
        if available:
            print(f"Available hex files in {HEXDATA_DIR}/:")
            for name in available:
                print(f"  {name}")
        else:
            print(f"No .hex files found in {HEXDATA_DIR}/")
            print("Run GenerateTestVectors.py to create one.")
        return

    hex_path = resolve_hex_path(args.hex_file)
    packets, events, metadata = build_packets_from_hex(hex_path)

    print(f"Hex file: {hex_path}")
    print(f"Detected events: {len(events)}")
    if events:
        print(f"Samples per event: {len(events[0])}")
    if metadata:
        print(f"Metadata: {metadata}")
    print(f"Total TX packets to send: {len(packets)}")
    print()

    for idx, packet in enumerate(packets, start=1):
        print(
            f"Packet {idx}: sample_count={len(events[idx - 1])}, "
            f"length={len(packet)} bytes"
        )
        print(hex_bytes(packet[:32]) + (" ..." if len(packet) > 32 else ""))
        print()

    if args.dry_run:
        return

    transmit_packets(packets, EXPECTED_REPLY_LEN)


if __name__ == "__main__":
    main()
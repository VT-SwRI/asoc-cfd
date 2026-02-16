import struct

def build_packet(sel, mode, payload) -> bytes:
    return struct.pack("!HH", sel, mode) + payload
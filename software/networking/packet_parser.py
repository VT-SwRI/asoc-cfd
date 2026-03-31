import struct
from dataclasses import dataclass

DATA_LEN = 24  # bytes, based on expected packet structure

@dataclass
class FPGAResponse:
    # change data types as needed, just a guess for now
    packet_type: int
    valid: int
    magnitude: float
    timestamp: float
    x_position: float
    y_position: float


class PacketParser:
    @staticmethod
    def parse_fpga_packet(data: bytes) -> FPGAResponse:
        """
        Expected format:
        [2B type (uint16)]
        [2B valid (uint16)]
        [4B magnitude (fixed point 32 bit)]
        [8B unix time (fixed point 64 bit)]
        [4B x (fixed point 32 bit)]
        [4B y (fixed point 32 bit)]
        Total = 24 bytes
        """
        # size may change
        if len(data) != DATA_LEN:
            raise ValueError(f"Invalid FPGA packet size: {len(data)}")

        # take in the raw bytes and unpack into integer fields
        # magnitude, time, x, and y are fixed point, so we can convert to float after unpacking
        unpacked = struct.unpack("!HHIQII", data)

        response = FPGAResponse(*unpacked)

        # convert fixed point to float (assuming 16.16 format for magnitude and x/y, and 32.32 for timestamp)
        response.magnitude /= 65536.0  # 16.16 fixed point
        response.x_position /= 65536.0  # 16.16 fixed point
        response.y_position /= 65536.0  # 16.16 fixed point
        response.timestamp /= 4294967296.0  # 32.32 fixed point
        
        return response
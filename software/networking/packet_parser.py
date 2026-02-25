import struct
from dataclasses import dataclass


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
        [4B magnitude (float32)]
        [8B unix time (float64)]
        [4B x (float32)]
        [4B y (float32)]
        Total = 24 bytes
        """

        if len(data) != 24:
            raise ValueError(f"Invalid FPGA packet size: {len(data)}")

        unpacked = struct.unpack("!HHfdff", data)

        return FPGAResponse(*unpacked)
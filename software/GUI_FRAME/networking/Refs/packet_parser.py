import struct
from dataclasses import dataclass


@dataclass
class FPGAResponse:
    # change data types as needed, just a guess for now
    packet_type: int
    valid: int
    magnitude: int
    timestamp: int
    x_position: int
    y_position: int


class PacketParser:
    @staticmethod
    def parse_fpga_packet(data: bytes) -> FPGAResponse:
        """
        Expected format:
        [2B type]
        [2B valid]
        [4B magnitude]
        [8B unix time]
        [4B x]
        [4B y]
        Total = 24 bytes
        """

        if len(data) != 24:
            raise ValueError(f"Invalid FPGA packet size: {len(data)}")

        unpacked = struct.unpack("!HHIQII", data)

        return FPGAResponse(*unpacked)
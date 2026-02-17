from enum import IntEnum


class PacketType(IntEnum):
    SET_PARAMETERS = 0x0001
    FPGA_RESPONSE = 0x0002
    # Add more as needed


# Fixed sizes
HOST_HEADER_SIZE = 2 + 2 + 2          # 6 bytes
HOST_PAYLOAD_SIZE = 32                # 32 bytes
HOST_PACKET_SIZE = HOST_HEADER_SIZE + HOST_PAYLOAD_SIZE  # 38 bytes

FPGA_HEADER_SIZE = 2 + 2              # 4 bytes
FPGA_PACKET_SIZE = 2 + 2 + 4 + 8 + 4 + 4  # 24 bytes
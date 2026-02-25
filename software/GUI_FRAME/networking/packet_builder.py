import struct
from packet_types import PacketType
from models.parameters import FPGAParameters


class PacketBuilder:

    @staticmethod
    def build_set_parameters_packet(
        packet_type: PacketType,
        select: int,
        mode: int,
        params: FPGAParameters
    ) -> bytes:
        """
        Builds 38-byte packet:
        [2B type][2B select][2B mode][32B payload]
        """

        # Header (big-endian network order)
        header = struct.pack("!HHH",
                             packet_type,
                             select,
                             mode)

        # Payload (define exact layout)
        # Example:
        # time (4B)
        # delay (4B)
        # attenuation (4B float)
        # threshold (4B)
        # remaining padded to 32 bytes

        payload = struct.pack("!IIfI",
                              params.time,
                              params.delay,
                              params.attenuation,
                              params.threshold)

        # Pad to 32 bytes
        payload = payload.ljust(32, b'\x00')

        return header + payload
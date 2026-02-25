import struct
from .packet_types import PacketType
from ..models.parameters import FPGAParameters


class PacketBuilder:

    @staticmethod
    def build_header(
        packet_type: PacketType,
        select: int,
        mode: int
    ) -> bytes:
        """
        Builds 6-byte header:
        [2B type][2B select][2B mode]
        """
        return struct.pack("!HHH", packet_type, select, mode)

    @staticmethod
    def build_set_parameters_payload(params: FPGAParameters) -> bytes:
        """
        Builds 16-byte payload with CFD parameters:
        [4B time][4B delay][4B attenuation][4B threshold]
        """
        return struct.pack("!IIfI",
                           params.time,
                           params.delay,
                           params.attenuation,
                           params.threshold)
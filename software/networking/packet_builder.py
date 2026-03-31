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

        # convert float to integer to send to FPGA 
        params.time = int(params.time * 65536.0)  # 16.16 fixed point
        params.delay = int(params.delay * 65536.0)  # 16.16 fixed point
        params.attenuation = int(params.attenuation * 65536.0)  # 16.16 fixed point
        params.threshold = int(params.threshold * 4294967296.0)  # 32.32 fixed point

        return struct.pack("!IIII",
                           params.time,
                           params.delay,
                           params.attenuation,
                           params.threshold)
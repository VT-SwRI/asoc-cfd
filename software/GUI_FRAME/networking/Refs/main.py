from packet_builder import PacketBuilder
from packet_types import PacketType
from udp_client import UDPClient
from models.parameters import FPGAParameters


def main():
    # Create UDP client (reads FPGA_IP and FPGA_PORT from environment)
    client = UDPClient()

    # Build parameter object
    params = FPGAParameters(
        time=1000,
        delay=25,
        attenuation=0.75,
        threshold=150
    )

    # Build packet
    packet = PacketBuilder.build_set_parameters_packet(
        packet_type=PacketType.SET_PARAMETERS,
        select=1,
        mode=0,
        params=params
    )

    # Send packet
    client.send(packet)

    print("Packet sent.")

    client.close()


if __name__ == "__main__":
    main()
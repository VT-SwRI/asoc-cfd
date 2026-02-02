# ASOC CFD FPGA HDL Subsystem (APB3/AHB-Lite)

This HDL implements the FPGA-side architecture that matches the firmware register map
(`firmware/include/fpga_ctrl.h`) and provides a practical set of APB3 peripherals:

- `apb_fpga_ctrl`: firmware-visible control/status regs + readout FIFO (`FIFO_LEVEL`, `FIFO_DATA`)
- `apb_asoc_spi_portal`: ASIC register portal over SPI (matches firmware's `asoc_bus_spi.h` pattern)
- `apb_uart_simple` (optional): small APB UART for debug/CLI if you don't use a vendor UART core
- `asoc_acq_core`: placeholder acquisition core that can accept sample streams, run a simple CFD,
  and push event words into the readout FIFO. It includes a simulation-friendly pattern generator.

Top-level options:
- `top/asoc_fpga_top.sv` exposes a *single* APB3 target interface and internally decodes to
  the peripherals (easy to drop behind a single CoreAPB3 slot).
- If you prefer to connect each peripheral as an independent APB target, instantiate them directly
  and skip `apb/apb_decoder.sv`.

Address map (default, configurable in `asoc_fpga_top.sv`):
- 0x0000_0000 : FPGA_CTRL regs (0x0000..0x00FF)
- 0x0000_1000 : ASOC_SPI portal (0x1000..0x10FF)
- 0x0000_2000 : UART (optional)  (0x2000..0x20FF)

Notes:
- APB3 timing follows the AMBA3 APB spec (setup phase then access phase).
- AHB-Lite to APB3 bridge included for convenience (`apb/ahb_lite_to_apb3_bridge.sv`);
  you may replace it with vendor cores (e.g., Microchip CoreAHBLite + CoreAPB3).

Build/sim:
- Files are plain SystemVerilog and should compile in most simulators.
- The acquisition core can be left disconnected in early bring-up; you can still exercise the
  register map and SPI portal via firmware.


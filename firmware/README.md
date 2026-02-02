# Firmware (expanded scaffold)

This firmware tree is an expanded, modular version of the single-file example that shipped in the zip.

It is designed to run in two modes:

- **Mock/host build (default)**: builds and runs on a PC for unit-testing protocol logic and algorithms.
- **A3PE target build**: intended to run on a soft CPU in the ProASIC3E/A3PE FPGA design (you will still need to wire up the platform HAL to your Libero SoC peripheral addresses).

## Why the abstraction layers look this way

Nalu's software stack (naludaq) separates control domains (analog regs, digital regs, FPGA control, I2C auxiliaries) and also supports a **serial register path when parallel access is unavailable**. citeturn12view1  
This tree mirrors that separation so you can evolve toward a board-accurate implementation without rewriting your higher-level run/control code.

## Build (mock)

```bash
cd firmware
make
./build/fw_mock
```

## Porting notes (A3PE starter kit)

The A3PE-STARTER-KIT-2 is based on ProASIC3E and is commonly used as a prototyping platform. citeturn12view3  
To port to the A3PE target, edit:

- `platform/platform_config.h` (set `PLATFORM_TARGET_A3PE=1`)
- `platform/platform_common.c` (implement UART, SPI, delay, millis)

Then make sure `FPGA_REG_BASE` matches the APB address of your custom register block in Libero SoC.

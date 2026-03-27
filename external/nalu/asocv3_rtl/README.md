# ASOC v3 RTL Behavioural Model

Full behavioural RTL model of the **Nalu Scientific ASOC v3** waveform-digitiser ASIC,
written in synthesisable/simulation-ready Verilog-2012.

---

## File Structure

```
asoc_v3_rtl/
├── asoc_v3.v               Top-level chip with exact QFN-64 port names
├── asoc_v3_adc_channel.v   ADC channel: quantiser + 16k sample buffer
├── asoc_v3_serial_if.v     4-wire SPI-like configuration & readout bus
├── asoc_v3_lvds_tx.v       LVDS serialiser (SOF header + 12-bit data)
├── asoc_v3_tb.v            Self-checking testbench
├── Makefile                Build + run (Icarus Verilog)
└── README.md               This file
```

---

## Architecture Overview

```
                       ┌──────────────────────────────────────┐
  rfin_W[7:0] ──────▶ │           ASOC v3 Top                │
  rfin_E[7:0] ──────▶ │                                      │
                       │  ┌──────────┐   ┌────────────────┐  │
  adc_clk ──────────▶ │  │  ADC Ch0 │──▶│  LVDS TX 0     │──┼──▶ TxOut[0]±
  acquire ──────────▶ │  │  (16k buf)│  │  TxClkOut[0]±  │  │    TxClkOut[0]±
                       │  └──────────┘   └────────────────┘  │
                       │  ┌──────────┐   ┌────────────────┐  │
                       │  │  ADC Ch1 │──▶│  LVDS TX 1     │──┼──▶ TxOut[1]±
                       │  └──────────┘   └────────────────┘  │
                       │  ┌──────────┐   ┌────────────────┐  │
                       │  │  ADC Ch2 │──▶│  LVDS TX 2     │──┼──▶ TxOut[2]±
                       │  └──────────┘   └────────────────┘  │
                       │  ┌──────────┐   ┌────────────────┐  │
                       │  │  ADC Ch3 │──▶│  LVDS TX 3     │──┼──▶ TxOut[3]±
                       │  └──────────┘   └────────────────┘  │
                       │                                      │
                       │  ┌──────────────────────────────┐   │
  SdA_B (SCLK) ──────▶│  │  Serial Interface (SPI-like) │   │
  SdB_B (MOSI) ──────▶│  │  8-bit addr / 16-bit data    │   │
  SdC_B (MISO) ◀──────│  │  Reg map: CTRL, STATUS,      │   │
  SdD_B (CS_N) ──────▶│  │  RD_ADDR, RD_DATA, SAMP_CNT  │   │
                       │  └──────────────────────────────┘   │
                       └──────────────────────────────────────┘
```

---

## Signal Mapping to QFN-64 Pins

| Pin(s)         | Signal           | Direction | Description                     |
|----------------|------------------|-----------|---------------------------------|
| 1,3,5,7,9,11,13,15 | rfin_W[7:0]  | In (real) | West RF analog inputs           |
| 34,36,38,40,42,44,46,48 | rfin_E[7:0] | In (real) | East RF analog inputs       |
| 19 (SdA_B)     | sda_b (SCLK)    | In        | Serial clock                    |
| 20 (SdB_B)     | sdb_b (MOSI)    | In        | Serial data in                  |
| 21 (SdC_B)     | sdc_b (MISO)    | Out       | Serial data out                 |
| 22 (SdD_B)     | sdd_b (CS_N)    | In        | Chip select (active-low)        |
| 25–28          | TxClkOut[0..3]± | Out (LVDS)| Companion clocks for data       |
| 29–32          | TxOut[0..3]±    | Out (LVDS)| Serialised digitised data       |
| 2,4,14,35,45,47| VDD 2.5 V       | PWR       | Analog supply                   |
| 6,8,10,12,16,33,37,39,41,43 | VDD 1.2 V | PWR | Digital core supply         |
| 17             | Vdda_B          | PWR       | Analog bank-B supply            |
| 18             | Vddp_B          | PWR       | Digital bank-B supply           |
| 23             | Vdda_A          | PWR       | Analog bank-A supply            |
| 24             | Vddp_A          | PWR       | Digital bank-A supply           |
| EP (exposed pad)| VSS (GND)      | PWR       | Ground                          |

---

## ADC Channel Model (`asoc_v3_adc_channel.v`)

- **Resolution:** 12-bit two's complement
- **Full scale:** ±1.0 V (parameterisable via `VREF_POS` / `VREF_NEG`)
- **Buffer depth:** 16 384 samples (parameterisable)
- **Input mux:** 4 sub-channels rotate on every `adc_clk` edge — models
  time-interleaved sampling across the 4 RF inputs per ADC channel
- **Quantisation:** `(Vin − Vref−) / (Vref+ − Vref−) × (2^N − 1) − 2^(N-1)`
- **Read port:** synchronous, `sys_clk` domain

---

## LVDS Serialiser (`asoc_v3_lvds_tx.v`)

Frame format (16 bits per sample, MSB first):

```
[15:12]  SOF header  = 4'hA
[11:0]   ADC sample  (12-bit two's complement)
```

The companion clock (`TxClkOut_p/n`) toggles at the same rate as the data
stream, providing source-synchronous capture at the FPGA receiver.

Differential pairs are modelled as complementary single-bit wires
(`_p` / `_n`), with `_n = ~_p` at all times.

---

## Serial Register Map

| Addr | Name       | Access | Description                          |
|------|------------|--------|--------------------------------------|
| 0x00 | CTRL       | RW     | [0]=soft_acquire, [3:2]=ch_select    |
| 0x01 | STATUS     | RO     | [3:0]=data_ready per channel         |
| 0x02 | RD_ADDR_L  | RW     | Lower 8 bits of sample read pointer  |
| 0x03 | RD_ADDR_H  | RW     | Upper 6 bits of sample read pointer  |
| 0x04 | RD_DATA    | RO     | 12-bit sample from selected channel  |
| 0x05 | SAMPLE_CNT | RO     | Number of captured samples           |
| 0x06 | THRESH_L   | RW     | Capture depth, low byte              |
| 0x07 | THRESH_H   | RW     | Capture depth, high byte             |

---

## Running the Simulation

```bash
# Install Icarus Verilog if needed
sudo apt install iverilog

# Compile and run
make

# View waveforms (requires GTKWave)
make wave
```

Expected output:
```
============================================================
 ASOC v3 RTL Behavioural Simulation
============================================================
[100 ns] Reset released
--- TEST 1: Serial-interface register write/read ---
--- TEST 2: Acquire trigger + buffer fill ---
[...] data_ready_out=0xF – all channels captured OK
--- TEST 3: LVDS streaming – channel 0 ---
  [LVDS CH0] Transmission started
  [LVDS CH0] Sample[0] raw=0x000  signed=0
  ...
  [LVDS CH0] 64 samples captured, 0 errors
  PASS: No LVDS framing errors
--- TEST 4: Serial readback ...
--- TEST 5: Soft acquire ...
============================================================
 Simulation complete.
============================================================
```

---

## Parameters

All key sizing parameters are in the submodule headers and can be overridden:

| Parameter     | Default | Description                  |
|---------------|---------|------------------------------|
| `ADC_BITS`    | 12      | ADC resolution (bits)        |
| `BUFFER_DEPTH`| 16384   | Samples per channel          |
| `ADDR_W`      | 14      | = log₂(BUFFER_DEPTH)         |
| `VREF_POS`    | 1.0     | Positive full-scale (V)      |
| `VREF_NEG`    | −1.0    | Negative full-scale (V)      |
| `FRAME_BITS`  | 16      | Bits per LVDS frame (SOF+data)|

// =============================================================================
// ASOC v3 – Simulation Makefile  (GNU Make)
// =============================================================================
// Usage:
//   make          – compile and run all tests (Icarus Verilog)
//   make wave     – open VCD in GTKWave after simulation
//   make clean    – remove build artefacts
//
// Requires: iverilog >= 11, vvp, gtkwave (optional)
// =============================================================================

SIM      = vvp
IVERILOG = iverilog
FLAGS    = -g2012 -Wall
TOP      = asoc_v3_tb
SRCS     = asoc_v3_tb.v asoc_v3.v asoc_v3_adc_channel.v \
           asoc_v3_serial_if.v asoc_v3_lvds_tx.v
OUT      = sim_asoc_v3
VCD      = asoc_v3_tb.vcd

all: compile run

compile:
	$(IVERILOG) $(FLAGS) -o $(OUT) $(SRCS)

run: $(OUT)
	$(SIM) $(OUT)

wave: $(VCD)
	gtkwave $(VCD) &

clean:
	rm -f $(OUT) $(VCD)

.PHONY: all compile run wave clean

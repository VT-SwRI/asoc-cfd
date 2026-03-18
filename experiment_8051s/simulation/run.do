quietly set ACTELLIBNAME ProASIC3E
quietly set PROJECT_DIR "C:/Users/tyler/S26_23/experiment_8051s"
source "${PROJECT_DIR}/simulation/bfmCompile.tcl";source "${PROJECT_DIR}/simulation/bfmtovec_compile.tcl";

if {[file exists presynth/_info]} {
   echo "INFO: Simulation library presynth already exists"
} else {
   file delete -force presynth 
   vlib presynth
}
vmap presynth presynth
vmap proasic3e "C:/Microsemi/Libero_SoC_v11.9/Designer/lib/modelsim/precompiled/vlog/proasic3e"
vmap CORE8051S_LIB "../component/Actel/DirectCore/CORE8051S/2.4.101/mti/user_vlog/CORE8051S_LIB"
vcom -work CORE8051S_LIB -force_refresh
vlog -work CORE8051S_LIB -force_refresh
if {[file exists COREAPB3_LIB/_info]} {
   echo "INFO: Simulation library COREAPB3_LIB already exists"
} else {
   file delete -force COREAPB3_LIB 
   vlib COREAPB3_LIB
}
vmap COREAPB3_LIB "COREAPB3_LIB"

vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/ram256x8.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/ram256x20.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/ram256x8_block_ram.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/isr.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/cpu.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/clkctrl.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/memctrl.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/oci.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/pmu.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/rstctrl.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/instrdec.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/alu.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/ramsfrctrl.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/intctrl.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/main8051.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/core8051s_globs_a3pe.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/jtagu.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/jtag.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/debug.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/trace.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/trigger.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/ocia51.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/ram256x8_registers.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/Actel/DirectCore/CORE8051S/2.4.101/rtl/verilog/o/core8051s.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/hdl/mem_interface.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/smartgen/ram_core/ram_core.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/work/top/CoreGPIO_0/rtl/vlog/core/coregpio.v"
vlog -vlog01compat -work COREAPB3_LIB "${PROJECT_DIR}/component/Actel/DirectCore/CoreAPB3/4.2.100/rtl/vlog/core/coreapb3_muxptob3.v"
vlog -vlog01compat -work COREAPB3_LIB "${PROJECT_DIR}/component/Actel/DirectCore/CoreAPB3/4.2.100/rtl/vlog/core/coreapb3_iaddr_reg.v"
vlog -vlog01compat -work COREAPB3_LIB "${PROJECT_DIR}/component/Actel/DirectCore/CoreAPB3/4.2.100/rtl/vlog/core/coreapb3.v"
vlog -vlog01compat -work presynth "${PROJECT_DIR}/component/work/top/top.v"
vlog "+incdir+${PROJECT_DIR}/stimulus" -vlog01compat -work presynth "${PROJECT_DIR}/stimulus/tb_top.v"

vsim -L proasic3e -L presynth -L CORE8051S_LIB -L COREAPB3_LIB  -t 1ps presynth.tb_top
add wave /tb_top/*
run 1000ns

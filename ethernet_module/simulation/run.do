quietly set ACTELLIBNAME ProASIC3E
quietly set PROJECT_DIR "C:/Users/zackp/OneDrive/Documents/ECE_4806/Libero/ethernet_module"
source "${PROJECT_DIR}/simulation/bfmCompile.tcl";source "${PROJECT_DIR}/simulation/bfmtovec_compile.tcl";

if {[file exists postsynth/_info]} {
   echo "INFO: Simulation library postsynth already exists"
} else {
   file delete -force postsynth 
   vlib postsynth
}
vmap postsynth postsynth
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

vlog -vlog01compat -work postsynth "${PROJECT_DIR}/synthesis/ethernet_module.v"
vlog "+incdir+${PROJECT_DIR}/component/work/sd_tb" -vlog01compat -work postsynth "${PROJECT_DIR}/component/work/sd_tb/sd_tb.v"

vsim -L proasic3e -L postsynth -L CORE8051S_LIB -L COREAPB3_LIB  -t 1ps postsynth.sd_tb
add wave /sd_tb/*
run 1000ns

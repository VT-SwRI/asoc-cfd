# ============================================
# Core8051s Full System Debug Waveforms
# ============================================
# do wave.do
# restart -f
# run 5ms

# ---- Top Level ----
add wave -group "Top Level" \
    /tb_top/CLK \
    /tb_top/NSYSRESET \
    /tb_top/LED

# ---- Core8051s: Program Fetch ----
add wave -group "Core8051s Fetch" \
    -radix hex /tb_top/DUT/CORE8051S_0/MEMADDR \
    /tb_top/DUT/CORE8051S_0/MEMPSRD \
    -radix hex /tb_top/DUT/CORE8051S_0/MEMDATAI \
    -radix hex /tb_top/DUT/CORE8051S_0/MEMDATAO \
    /tb_top/DUT/CORE8051S_0/MEMPSACKI

# ---- Core8051s: Data Memory ----
add wave -group "Core8051s Data" \
    /tb_top/DUT/CORE8051S_0/MEMRD \
    /tb_top/DUT/CORE8051S_0/MEMWR \
    /tb_top/DUT/CORE8051S_0/MEMACKI \
    /tb_top/DUT/CORE8051S_0/MOVX

# ---- Core8051s: APB Master ----
add wave -group "Core8051s APB" \
    -radix hex /tb_top/DUT/CORE8051S_0/PADDR \
    /tb_top/DUT/CORE8051S_0/PSEL \
    /tb_top/DUT/CORE8051S_0/PENABLE \
    /tb_top/DUT/CORE8051S_0/PWRITE \
    -radix hex /tb_top/DUT/CORE8051S_0/PWDATA \
    -radix hex /tb_top/DUT/CORE8051S_0/PRDATA \
    /tb_top/DUT/CORE8051S_0/PREADY

# ---- Core8051s: Control ----
add wave -group "Core8051s Control" \
    /tb_top/DUT/CORE8051S_0/CLK \
    /tb_top/DUT/CORE8051S_0/NSYSRESET \
    /tb_top/DUT/CORE8051S_0/PRESETN \
    /tb_top/DUT/CORE8051S_0/WDOGRES \
    /tb_top/DUT/CORE8051S_0/WDOGRESN \
    /tb_top/DUT/CORE8051S_0/INT0 \
    /tb_top/DUT/CORE8051S_0/INT1

# ---- Memory Interface ----
add wave -group "Mem Interface" \
    -radix hex /tb_top/DUT/mem_interface_0/MEMADDR \
    /tb_top/DUT/mem_interface_0/MEMPSRD \
    /tb_top/DUT/mem_interface_0/MEMPSACKI \
    /tb_top/DUT/mem_interface_0/MEMACKI \
    /tb_top/DUT/mem_interface_0/MEMRD \
    /tb_top/DUT/mem_interface_0/MEMWR \
    -radix hex /tb_top/DUT/mem_interface_0/MEMDATAI \
    -radix hex /tb_top/DUT/mem_interface_0/MEMDATAO \
    /tb_top/DUT/mem_interface_0/REN \
    -radix hex /tb_top/DUT/mem_interface_0/RADDR \
    -radix hex /tb_top/DUT/mem_interface_0/RD

# ---- RAM ----
add wave -group "RAM" \
    /tb_top/DUT/ram_core_0/RWCLK \
    /tb_top/DUT/ram_core_0/REN \
    -radix hex /tb_top/DUT/ram_core_0/RADDR \
    -radix hex /tb_top/DUT/ram_core_0/RD \
    /tb_top/DUT/ram_core_0/WEN \
    -radix hex /tb_top/DUT/ram_core_0/WADDR \
    -radix hex /tb_top/DUT/ram_core_0/WD

# ---- CoreAPB3 ----
add wave -group "CoreAPB3" \
    /tb_top/DUT/CoreAPB3_0/*

# ---- CoreGPIO ----
add wave -group "CoreGPIO" \
    /tb_top/DUT/CoreGPIO_0/PCLK \
    /tb_top/DUT/CoreGPIO_0/PRESETN \
    /tb_top/DUT/CoreGPIO_0/GPIO_OUT \
    /tb_top/DUT/CoreGPIO_0/GPIO_OE \
    /tb_top/DUT/CoreGPIO_0/GPIO_IN \
    /tb_top/DUT/CoreGPIO_0/INT

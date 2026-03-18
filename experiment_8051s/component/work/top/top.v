//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Wed Mar 18 00:40:15 2026
// Version: v11.9 SP6 11.9.6.7
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

// top
module top(
    // Inputs
    NSYSRESET,
    SYSCLK,
    // Outputs
    LED
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input        NSYSRESET;
input        SYSCLK;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output [0:0] LED;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire          CORE8051S_0_APB3master_PENABLE;
wire   [31:0] CORE8051S_0_APB3master_PRDATA;
wire          CORE8051S_0_APB3master_PREADY;
wire          CORE8051S_0_APB3master_PSELx;
wire          CORE8051S_0_APB3master_PSLVERR;
wire   [31:0] CORE8051S_0_APB3master_PWDATA;
wire          CORE8051S_0_APB3master_PWRITE;
wire   [15:0] CORE8051S_0_MEMADDR;
wire   [7:0]  CORE8051S_0_MEMDATAO;
wire          CORE8051S_0_MEMPSRD;
wire          CORE8051S_0_MEMRD;
wire          CORE8051S_0_MEMWR;
wire          CORE8051S_0_PRESETN;
wire          CoreAPB3_0_APBmslave0_PENABLE;
wire   [31:0] CoreAPB3_0_APBmslave0_PRDATA;
wire          CoreAPB3_0_APBmslave0_PREADY;
wire          CoreAPB3_0_APBmslave0_PSELx;
wire          CoreAPB3_0_APBmslave0_PSLVERR;
wire   [31:0] CoreAPB3_0_APBmslave0_PWDATA;
wire          CoreAPB3_0_APBmslave0_PWRITE;
wire   [0:0]  LED_net_0;
wire          mem_interface_0_MEMACKI;
wire   [7:0]  mem_interface_0_MEMDATAI;
wire          mem_interface_0_MEMPSACKI;
wire   [11:0] mem_interface_0_RADDR;
wire          mem_interface_0_REN;
wire          NSYSRESET;
wire   [7:0]  ram_core_0_RD;
wire          SYSCLK;
wire   [0:0]  LED_net_1;
//--------------------------------------------------------------------
// TiedOff Nets
//--------------------------------------------------------------------
wire          GND_net;
wire   [7:0]  WD_const_net_0;
wire   [11:0] WADDR_const_net_0;
wire          VCC_net;
wire   [3:0]  MEMBANK_const_net_0;
wire   [31:0] IADDR_const_net_0;
wire   [31:0] PRDATAS1_const_net_0;
wire   [31:0] PRDATAS2_const_net_0;
wire   [31:0] PRDATAS3_const_net_0;
wire   [31:0] PRDATAS4_const_net_0;
wire   [31:0] PRDATAS5_const_net_0;
wire   [31:0] PRDATAS6_const_net_0;
wire   [31:0] PRDATAS7_const_net_0;
wire   [31:0] PRDATAS8_const_net_0;
wire   [31:0] PRDATAS9_const_net_0;
wire   [31:0] PRDATAS10_const_net_0;
wire   [31:0] PRDATAS11_const_net_0;
wire   [31:0] PRDATAS12_const_net_0;
wire   [31:0] PRDATAS13_const_net_0;
wire   [31:0] PRDATAS14_const_net_0;
wire   [31:0] PRDATAS15_const_net_0;
wire   [31:0] PRDATAS16_const_net_0;
//--------------------------------------------------------------------
// Bus Interface Nets Declarations - Unequal Pin Widths
//--------------------------------------------------------------------
wire   [11:0] CORE8051S_0_APB3master_PADDR;
wire   [31:12]CORE8051S_0_APB3master_PADDR_0_31to12;
wire   [11:0] CORE8051S_0_APB3master_PADDR_0_11to0;
wire   [31:0] CORE8051S_0_APB3master_PADDR_0;
wire   [31:0] CoreAPB3_0_APBmslave0_PADDR;
wire   [7:0]  CoreAPB3_0_APBmslave0_PADDR_0_7to0;
wire   [7:0]  CoreAPB3_0_APBmslave0_PADDR_0;
//--------------------------------------------------------------------
// Constant assignments
//--------------------------------------------------------------------
assign GND_net               = 1'b0;
assign WD_const_net_0        = 8'h00;
assign WADDR_const_net_0     = 12'h000;
assign VCC_net               = 1'b1;
assign MEMBANK_const_net_0   = 4'h0;
assign IADDR_const_net_0     = 32'h00000000;
assign PRDATAS1_const_net_0  = 32'h00000000;
assign PRDATAS2_const_net_0  = 32'h00000000;
assign PRDATAS3_const_net_0  = 32'h00000000;
assign PRDATAS4_const_net_0  = 32'h00000000;
assign PRDATAS5_const_net_0  = 32'h00000000;
assign PRDATAS6_const_net_0  = 32'h00000000;
assign PRDATAS7_const_net_0  = 32'h00000000;
assign PRDATAS8_const_net_0  = 32'h00000000;
assign PRDATAS9_const_net_0  = 32'h00000000;
assign PRDATAS10_const_net_0 = 32'h00000000;
assign PRDATAS11_const_net_0 = 32'h00000000;
assign PRDATAS12_const_net_0 = 32'h00000000;
assign PRDATAS13_const_net_0 = 32'h00000000;
assign PRDATAS14_const_net_0 = 32'h00000000;
assign PRDATAS15_const_net_0 = 32'h00000000;
assign PRDATAS16_const_net_0 = 32'h00000000;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign LED_net_1[0] = LED_net_0[0];
assign LED[0:0]     = LED_net_1[0];
//--------------------------------------------------------------------
// Bus Interface Nets Assignments - Unequal Pin Widths
//--------------------------------------------------------------------
assign CORE8051S_0_APB3master_PADDR_0_31to12 = 20'h0;
assign CORE8051S_0_APB3master_PADDR_0_11to0 = CORE8051S_0_APB3master_PADDR[11:0];
assign CORE8051S_0_APB3master_PADDR_0 = { CORE8051S_0_APB3master_PADDR_0_31to12, CORE8051S_0_APB3master_PADDR_0_11to0 };

assign CoreAPB3_0_APBmslave0_PADDR_0_7to0 = CoreAPB3_0_APBmslave0_PADDR[7:0];
assign CoreAPB3_0_APBmslave0_PADDR_0 = { CoreAPB3_0_APBmslave0_PADDR_0_7to0 };

//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------CORE8051S   -   Actel:DirectCore:CORE8051S:2.4.101
CORE8051S #( 
        .APB_DWIDTH            ( 32 ),
        .DEBUG                 ( 0 ),
        .EN_FF_OPTS            ( 0 ),
        .FAMILY                ( 16 ),
        .INCL_DPTR1            ( 0 ),
        .INCL_MUL_DIV_DA       ( 1 ),
        .INCL_TRACE            ( 0 ),
        .INTRAM_IMPLEMENTATION ( 0 ),
        .STRETCH_VAL           ( 1 ),
        .TRIG_NUM              ( 0 ),
        .VARIABLE_STRETCH      ( 0 ),
        .VARIABLE_WAIT         ( 0 ),
        .WAIT_VAL              ( 1 ) )
CORE8051S_0(
        // Inputs
        .CLK        ( SYSCLK ),
        .NSYSRESET  ( NSYSRESET ),
        .WDOGRES    ( GND_net ), // tied to 1'b0 from definition
        .INT0       ( GND_net ), // tied to 1'b0 from definition
        .INT1       ( GND_net ), // tied to 1'b0 from definition
        .PREADY     ( CORE8051S_0_APB3master_PREADY ),
        .PSLVERR    ( CORE8051S_0_APB3master_PSLVERR ),
        .MEMPSACKI  ( mem_interface_0_MEMPSACKI ),
        .MEMACKI    ( mem_interface_0_MEMACKI ),
        .TCK        ( VCC_net ), // tied to 1'b1 from definition
        .TMS        ( GND_net ), // tied to 1'b0 from definition
        .TDI        ( GND_net ), // tied to 1'b0 from definition
        .TRSTN      ( VCC_net ), // tied to 1'b1 from definition
        .BREAKIN    ( GND_net ), // tied to 1'b0 from definition
        .PRDATA     ( CORE8051S_0_APB3master_PRDATA ),
        .MEMDATAI   ( mem_interface_0_MEMDATAI ),
        .MEMBANK    ( MEMBANK_const_net_0 ), // tied to 4'h0 from definition
        // Outputs
        .PRESETN    ( CORE8051S_0_PRESETN ),
        .WDOGRESN   (  ),
        .MOVX       (  ),
        .PWRITE     ( CORE8051S_0_APB3master_PWRITE ),
        .PENABLE    ( CORE8051S_0_APB3master_PENABLE ),
        .PSEL       ( CORE8051S_0_APB3master_PSELx ),
        .MEMPSRD    ( CORE8051S_0_MEMPSRD ),
        .MEMWR      ( CORE8051S_0_MEMWR ),
        .MEMRD      ( CORE8051S_0_MEMRD ),
        .TDO        (  ),
        .BREAKOUT   (  ),
        .DBGMEMPSWR (  ),
        .TRIGOUT    (  ),
        .AUXOUT     (  ),
        .PADDR      ( CORE8051S_0_APB3master_PADDR ),
        .PWDATA     ( CORE8051S_0_APB3master_PWDATA ),
        .MEMDATAO   ( CORE8051S_0_MEMDATAO ),
        .MEMADDR    ( CORE8051S_0_MEMADDR ) 
        );

//--------CoreAPB3   -   Actel:DirectCore:CoreAPB3:4.2.100
CoreAPB3 #( 
        .APB_DWIDTH      ( 32 ),
        .APBSLOT0ENABLE  ( 1 ),
        .APBSLOT1ENABLE  ( 0 ),
        .APBSLOT2ENABLE  ( 0 ),
        .APBSLOT3ENABLE  ( 0 ),
        .APBSLOT4ENABLE  ( 0 ),
        .APBSLOT5ENABLE  ( 0 ),
        .APBSLOT6ENABLE  ( 0 ),
        .APBSLOT7ENABLE  ( 0 ),
        .APBSLOT8ENABLE  ( 0 ),
        .APBSLOT9ENABLE  ( 0 ),
        .APBSLOT10ENABLE ( 0 ),
        .APBSLOT11ENABLE ( 0 ),
        .APBSLOT12ENABLE ( 0 ),
        .APBSLOT13ENABLE ( 0 ),
        .APBSLOT14ENABLE ( 0 ),
        .APBSLOT15ENABLE ( 0 ),
        .FAMILY          ( 16 ),
        .IADDR_OPTION    ( 0 ),
        .MADDR_BITS      ( 12 ),
        .SC_0            ( 0 ),
        .SC_1            ( 0 ),
        .SC_2            ( 0 ),
        .SC_3            ( 0 ),
        .SC_4            ( 0 ),
        .SC_5            ( 0 ),
        .SC_6            ( 0 ),
        .SC_7            ( 0 ),
        .SC_8            ( 0 ),
        .SC_9            ( 0 ),
        .SC_10           ( 0 ),
        .SC_11           ( 0 ),
        .SC_12           ( 0 ),
        .SC_13           ( 0 ),
        .SC_14           ( 0 ),
        .SC_15           ( 0 ),
        .UPR_NIBBLE_POSN ( 6 ) )
CoreAPB3_0(
        // Inputs
        .PRESETN    ( GND_net ), // tied to 1'b0 from definition
        .PCLK       ( GND_net ), // tied to 1'b0 from definition
        .PWRITE     ( CORE8051S_0_APB3master_PWRITE ),
        .PENABLE    ( CORE8051S_0_APB3master_PENABLE ),
        .PSEL       ( CORE8051S_0_APB3master_PSELx ),
        .PREADYS0   ( CoreAPB3_0_APBmslave0_PREADY ),
        .PSLVERRS0  ( CoreAPB3_0_APBmslave0_PSLVERR ),
        .PREADYS1   ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS1  ( GND_net ), // tied to 1'b0 from definition
        .PREADYS2   ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS2  ( GND_net ), // tied to 1'b0 from definition
        .PREADYS3   ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS3  ( GND_net ), // tied to 1'b0 from definition
        .PREADYS4   ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS4  ( GND_net ), // tied to 1'b0 from definition
        .PREADYS5   ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS5  ( GND_net ), // tied to 1'b0 from definition
        .PREADYS6   ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS6  ( GND_net ), // tied to 1'b0 from definition
        .PREADYS7   ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS7  ( GND_net ), // tied to 1'b0 from definition
        .PREADYS8   ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS8  ( GND_net ), // tied to 1'b0 from definition
        .PREADYS9   ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS9  ( GND_net ), // tied to 1'b0 from definition
        .PREADYS10  ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS10 ( GND_net ), // tied to 1'b0 from definition
        .PREADYS11  ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS11 ( GND_net ), // tied to 1'b0 from definition
        .PREADYS12  ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS12 ( GND_net ), // tied to 1'b0 from definition
        .PREADYS13  ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS13 ( GND_net ), // tied to 1'b0 from definition
        .PREADYS14  ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS14 ( GND_net ), // tied to 1'b0 from definition
        .PREADYS15  ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS15 ( GND_net ), // tied to 1'b0 from definition
        .PREADYS16  ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS16 ( GND_net ), // tied to 1'b0 from definition
        .PADDR      ( CORE8051S_0_APB3master_PADDR_0 ),
        .PWDATA     ( CORE8051S_0_APB3master_PWDATA ),
        .PRDATAS0   ( CoreAPB3_0_APBmslave0_PRDATA ),
        .PRDATAS1   ( PRDATAS1_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS2   ( PRDATAS2_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS3   ( PRDATAS3_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS4   ( PRDATAS4_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS5   ( PRDATAS5_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS6   ( PRDATAS6_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS7   ( PRDATAS7_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS8   ( PRDATAS8_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS9   ( PRDATAS9_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS10  ( PRDATAS10_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS11  ( PRDATAS11_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS12  ( PRDATAS12_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS13  ( PRDATAS13_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS14  ( PRDATAS14_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS15  ( PRDATAS15_const_net_0 ), // tied to 32'h00000000 from definition
        .PRDATAS16  ( PRDATAS16_const_net_0 ), // tied to 32'h00000000 from definition
        .IADDR      ( IADDR_const_net_0 ), // tied to 32'h00000000 from definition
        // Outputs
        .PREADY     ( CORE8051S_0_APB3master_PREADY ),
        .PSLVERR    ( CORE8051S_0_APB3master_PSLVERR ),
        .PWRITES    ( CoreAPB3_0_APBmslave0_PWRITE ),
        .PENABLES   ( CoreAPB3_0_APBmslave0_PENABLE ),
        .PSELS0     ( CoreAPB3_0_APBmslave0_PSELx ),
        .PSELS1     (  ),
        .PSELS2     (  ),
        .PSELS3     (  ),
        .PSELS4     (  ),
        .PSELS5     (  ),
        .PSELS6     (  ),
        .PSELS7     (  ),
        .PSELS8     (  ),
        .PSELS9     (  ),
        .PSELS10    (  ),
        .PSELS11    (  ),
        .PSELS12    (  ),
        .PSELS13    (  ),
        .PSELS14    (  ),
        .PSELS15    (  ),
        .PSELS16    (  ),
        .PRDATA     ( CORE8051S_0_APB3master_PRDATA ),
        .PADDRS     ( CoreAPB3_0_APBmslave0_PADDR ),
        .PWDATAS    ( CoreAPB3_0_APBmslave0_PWDATA ) 
        );

//--------top_CoreGPIO_0_CoreGPIO   -   Actel:DirectCore:CoreGPIO:3.2.102
top_CoreGPIO_0_CoreGPIO #( 
        .APB_WIDTH       ( 32 ),
        .FIXED_CONFIG_0  ( 1 ),
        .FIXED_CONFIG_1  ( 0 ),
        .FIXED_CONFIG_2  ( 0 ),
        .FIXED_CONFIG_3  ( 0 ),
        .FIXED_CONFIG_4  ( 0 ),
        .FIXED_CONFIG_5  ( 0 ),
        .FIXED_CONFIG_6  ( 0 ),
        .FIXED_CONFIG_7  ( 0 ),
        .FIXED_CONFIG_8  ( 0 ),
        .FIXED_CONFIG_9  ( 0 ),
        .FIXED_CONFIG_10 ( 0 ),
        .FIXED_CONFIG_11 ( 0 ),
        .FIXED_CONFIG_12 ( 0 ),
        .FIXED_CONFIG_13 ( 0 ),
        .FIXED_CONFIG_14 ( 0 ),
        .FIXED_CONFIG_15 ( 0 ),
        .FIXED_CONFIG_16 ( 0 ),
        .FIXED_CONFIG_17 ( 0 ),
        .FIXED_CONFIG_18 ( 0 ),
        .FIXED_CONFIG_19 ( 0 ),
        .FIXED_CONFIG_20 ( 0 ),
        .FIXED_CONFIG_21 ( 0 ),
        .FIXED_CONFIG_22 ( 0 ),
        .FIXED_CONFIG_23 ( 0 ),
        .FIXED_CONFIG_24 ( 0 ),
        .FIXED_CONFIG_25 ( 0 ),
        .FIXED_CONFIG_26 ( 0 ),
        .FIXED_CONFIG_27 ( 0 ),
        .FIXED_CONFIG_28 ( 0 ),
        .FIXED_CONFIG_29 ( 0 ),
        .FIXED_CONFIG_30 ( 0 ),
        .FIXED_CONFIG_31 ( 0 ),
        .INT_BUS         ( 0 ),
        .IO_INT_TYPE_0   ( 7 ),
        .IO_INT_TYPE_1   ( 7 ),
        .IO_INT_TYPE_2   ( 7 ),
        .IO_INT_TYPE_3   ( 7 ),
        .IO_INT_TYPE_4   ( 7 ),
        .IO_INT_TYPE_5   ( 7 ),
        .IO_INT_TYPE_6   ( 7 ),
        .IO_INT_TYPE_7   ( 7 ),
        .IO_INT_TYPE_8   ( 7 ),
        .IO_INT_TYPE_9   ( 7 ),
        .IO_INT_TYPE_10  ( 7 ),
        .IO_INT_TYPE_11  ( 7 ),
        .IO_INT_TYPE_12  ( 7 ),
        .IO_INT_TYPE_13  ( 7 ),
        .IO_INT_TYPE_14  ( 7 ),
        .IO_INT_TYPE_15  ( 7 ),
        .IO_INT_TYPE_16  ( 7 ),
        .IO_INT_TYPE_17  ( 7 ),
        .IO_INT_TYPE_18  ( 7 ),
        .IO_INT_TYPE_19  ( 7 ),
        .IO_INT_TYPE_20  ( 7 ),
        .IO_INT_TYPE_21  ( 7 ),
        .IO_INT_TYPE_22  ( 7 ),
        .IO_INT_TYPE_23  ( 7 ),
        .IO_INT_TYPE_24  ( 7 ),
        .IO_INT_TYPE_25  ( 7 ),
        .IO_INT_TYPE_26  ( 7 ),
        .IO_INT_TYPE_27  ( 7 ),
        .IO_INT_TYPE_28  ( 7 ),
        .IO_INT_TYPE_29  ( 7 ),
        .IO_INT_TYPE_30  ( 7 ),
        .IO_INT_TYPE_31  ( 7 ),
        .IO_NUM          ( 1 ),
        .IO_TYPE_0       ( 1 ),
        .IO_TYPE_1       ( 0 ),
        .IO_TYPE_2       ( 0 ),
        .IO_TYPE_3       ( 0 ),
        .IO_TYPE_4       ( 0 ),
        .IO_TYPE_5       ( 0 ),
        .IO_TYPE_6       ( 0 ),
        .IO_TYPE_7       ( 0 ),
        .IO_TYPE_8       ( 0 ),
        .IO_TYPE_9       ( 0 ),
        .IO_TYPE_10      ( 0 ),
        .IO_TYPE_11      ( 0 ),
        .IO_TYPE_12      ( 0 ),
        .IO_TYPE_13      ( 0 ),
        .IO_TYPE_14      ( 0 ),
        .IO_TYPE_15      ( 0 ),
        .IO_TYPE_16      ( 0 ),
        .IO_TYPE_17      ( 0 ),
        .IO_TYPE_18      ( 0 ),
        .IO_TYPE_19      ( 0 ),
        .IO_TYPE_20      ( 0 ),
        .IO_TYPE_21      ( 0 ),
        .IO_TYPE_22      ( 0 ),
        .IO_TYPE_23      ( 0 ),
        .IO_TYPE_24      ( 0 ),
        .IO_TYPE_25      ( 0 ),
        .IO_TYPE_26      ( 0 ),
        .IO_TYPE_27      ( 0 ),
        .IO_TYPE_28      ( 0 ),
        .IO_TYPE_29      ( 0 ),
        .IO_TYPE_30      ( 0 ),
        .IO_TYPE_31      ( 0 ),
        .IO_VAL_0        ( 0 ),
        .IO_VAL_1        ( 0 ),
        .IO_VAL_2        ( 0 ),
        .IO_VAL_3        ( 0 ),
        .IO_VAL_4        ( 0 ),
        .IO_VAL_5        ( 0 ),
        .IO_VAL_6        ( 0 ),
        .IO_VAL_7        ( 0 ),
        .IO_VAL_8        ( 0 ),
        .IO_VAL_9        ( 0 ),
        .IO_VAL_10       ( 0 ),
        .IO_VAL_11       ( 0 ),
        .IO_VAL_12       ( 0 ),
        .IO_VAL_13       ( 0 ),
        .IO_VAL_14       ( 0 ),
        .IO_VAL_15       ( 0 ),
        .IO_VAL_16       ( 0 ),
        .IO_VAL_17       ( 0 ),
        .IO_VAL_18       ( 0 ),
        .IO_VAL_19       ( 0 ),
        .IO_VAL_20       ( 0 ),
        .IO_VAL_21       ( 0 ),
        .IO_VAL_22       ( 0 ),
        .IO_VAL_23       ( 0 ),
        .IO_VAL_24       ( 0 ),
        .IO_VAL_25       ( 0 ),
        .IO_VAL_26       ( 0 ),
        .IO_VAL_27       ( 0 ),
        .IO_VAL_28       ( 0 ),
        .IO_VAL_29       ( 0 ),
        .IO_VAL_30       ( 0 ),
        .IO_VAL_31       ( 0 ),
        .OE_TYPE         ( 0 ) )
CoreGPIO_0(
        // Inputs
        .PRESETN  ( CORE8051S_0_PRESETN ),
        .PCLK     ( SYSCLK ),
        .PSEL     ( CoreAPB3_0_APBmslave0_PSELx ),
        .PENABLE  ( CoreAPB3_0_APBmslave0_PENABLE ),
        .PWRITE   ( CoreAPB3_0_APBmslave0_PWRITE ),
        .PADDR    ( CoreAPB3_0_APBmslave0_PADDR_0 ),
        .PWDATA   ( CoreAPB3_0_APBmslave0_PWDATA ),
        .GPIO_IN  ( GND_net ),
        // Outputs
        .PSLVERR  ( CoreAPB3_0_APBmslave0_PSLVERR ),
        .PREADY   ( CoreAPB3_0_APBmslave0_PREADY ),
        .INT_OR   (  ),
        .PRDATA   ( CoreAPB3_0_APBmslave0_PRDATA ),
        .INT      (  ),
        .GPIO_OUT ( LED_net_0 ),
        .GPIO_OE  (  ) 
        );

//--------mem_interface
mem_interface mem_interface_0(
        // Inputs
        .CLK       ( SYSCLK ),
        .RESETN    ( NSYSRESET ),
        .MEMPSRD   ( CORE8051S_0_MEMPSRD ),
        .MEMRD     ( CORE8051S_0_MEMRD ),
        .MEMWR     ( CORE8051S_0_MEMWR ),
        .MEMADDR   ( CORE8051S_0_MEMADDR ),
        .MEMDATAO  ( CORE8051S_0_MEMDATAO ),
        .RD        ( ram_core_0_RD ),
        // Outputs
        .MEMPSACKI ( mem_interface_0_MEMPSACKI ),
        .MEMACKI   ( mem_interface_0_MEMACKI ),
        .REN       ( mem_interface_0_REN ),
        .MEMDATAI  ( mem_interface_0_MEMDATAI ),
        .RADDR     ( mem_interface_0_RADDR ) 
        );

//--------ram_core
ram_core ram_core_0(
        // Inputs
        .WEN   ( GND_net ),
        .REN   ( mem_interface_0_REN ),
        .RWCLK ( SYSCLK ),
        .WD    ( WD_const_net_0 ),
        .WADDR ( WADDR_const_net_0 ),
        .RADDR ( mem_interface_0_RADDR ),
        // Outputs
        .RD    ( ram_core_0_RD ) 
        );


endmodule

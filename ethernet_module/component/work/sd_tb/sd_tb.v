//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Wed Mar 25 15:33:30 2026
// Version: v11.9 SP6 11.9.6.7
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

// sd_tb
module sd_tb(
    // Inputs
    CLK,
    CLKR,
    CLKT,
    NSYSRESET,
    RXD,
    RX_DV,
    RX_ER,
    // Outputs
    LED,
    MDC,
    TXD,
    TXER,
    TX_EN,
    // Inouts
    mdio
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input        CLK;
input        CLKR;
input        CLKT;
input        NSYSRESET;
input  [3:0] RXD;
input        RX_DV;
input        RX_ER;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output       LED;
output       MDC;
output [3:0] TXD;
output       TXER;
output       TX_EN;
//--------------------------------------------------------------------
// Inout
//--------------------------------------------------------------------
inout        mdio;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire         CLK;
wire         CLKR;
wire         CLKT;
wire         LED_net_0;
wire         MDC_net_0;
wire         mdio;
wire         NSYSRESET;
wire         RX_DV;
wire         RX_ER;
wire   [3:0] RXD;
wire         TX_EN_net_0;
wire   [3:0] TXD_net_0;
wire         TXER_net_0;
wire         TX_EN_net_1;
wire         MDC_net_1;
wire         TXER_net_1;
wire   [3:0] TXD_net_1;
wire         LED_net_1;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign TX_EN_net_1 = TX_EN_net_0;
assign TX_EN       = TX_EN_net_1;
assign MDC_net_1   = MDC_net_0;
assign MDC         = MDC_net_1;
assign TXER_net_1  = TXER_net_0;
assign TXER        = TXER_net_1;
assign TXD_net_1   = TXD_net_0;
assign TXD[3:0]    = TXD_net_1;
assign LED_net_1   = LED_net_0;
assign LED         = LED_net_1;
//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------ethernet_module
ethernet_module ethernet_module_0(
        // Inputs
        .NSYSRESET ( NSYSRESET ),
        .RX_ER     ( RX_ER ),
        .CLK       ( CLK ),
        .RX_DV     ( RX_DV ),
        .CLKR      ( CLKR ),
        .CLKT      ( CLKT ),
        .RXD       ( RXD ),
        // Outputs
        .TX_EN     ( TX_EN_net_0 ),
        .MDC       ( MDC_net_0 ),
        .TXER      ( TXER_net_0 ),
        .TXD       ( TXD_net_0 ),
        .LED       ( LED_net_0 ),
        // Inouts
        .mdio      ( mdio ) 
        );


endmodule

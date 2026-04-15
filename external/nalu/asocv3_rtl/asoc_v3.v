// =============================================================================
// ASOC v3 – Top-Level RTL Behavioural Model
// -----------------------------------------------------------------------------
// Nalu Scientific ASOC v3
//   • 64-lead QFN, 9×9 mm package
//   • 4 ADC channels, 2.4–3.6 GSa/s, 16k-sample buffer each
//   • 16 single-ended RF inputs  (RFin_W[7:0], RFin_E[7:0])
//   • 4-wire serial interface    (SdA_B..SdD_B, pins 19–22)
//   • 4× LVDS data outputs       (TxOut[3:0], pins 29–32)
//   • 4× LVDS clock outputs      (TxClkOut[3:0], pins 25–28)
//   • VDD rails: 2.5 V analog, 1.2 V digital (modelled as supply nets)
//   • VSS exposed pad
//
// Pin-to-port mapping reflects the QFN-64 pinout described in the ASOC v3
// interface document (pins 1-48 enumerated).  Power pins are declared as
// supply inputs and are not toggled in simulation.
//
// Simulation note:
//   Analog inputs are `real` typed.  To compile with Icarus Verilog use the
//   -g2012 flag and link with the VPI real library.  For Questa/ModelSim and
//   Synopsys VCS the default language settings suffice.
// =============================================================================

`timescale 1ns / 1ps

module asoc_v3 (
    // =========================================================================
    // POWER / GROUND  (pins enumerated per QFN-64 document)
    // =========================================================================
    // VDD 2.5 V  – pins 2, 4, 14, 35, 45, 47
    inout wire  vdd_2v5_p02,
    inout wire  vdd_2v5_p04,
    inout wire  vdd_2v5_p14,
    inout wire  vdd_2v5_p35,
    inout wire  vdd_2v5_p45,
    inout wire  vdd_2v5_p47,
    // VDD 1.2 V  – pins 6,8,10,12,16,33,37,39,41,43
    inout wire  vdd_1v2_p06,
    inout wire  vdd_1v2_p08,
    inout wire  vdd_1v2_p10,
    inout wire  vdd_1v2_p12,
    inout wire  vdd_1v2_p16,
    inout wire  vdd_1v2_p33,
    inout wire  vdd_1v2_p37,
    inout wire  vdd_1v2_p39,
    inout wire  vdd_1v2_p41,
    inout wire  vdd_1v2_p43,
    // Analog bank supplies – pins 17, 23
    inout wire  vdda_b_p17,
    inout wire  vdda_a_p23,
    // Digital bank supplies – pins 18, 24
    inout wire  vddp_b_p18,
    inout wire  vddp_a_p24,
    // VSS – exposed centre pad (implicit; tied to 0 externally)

    // =========================================================================
    // ANALOG INPUTS  (real-valued, single-ended, 50 Ω nominal)
    // =========================================================================
    // West side – pins 1,3,5,7,9,11,13,15
    input real rfin_w0,   // pin  1  RFin_W<0>
    input real rfin_w1,   // pin  3  RFin_W<1>
    input real rfin_w2,   // pin  5  RFin_W<2>
    input real rfin_w3,   // pin  7  RFin_W<3>
    input real rfin_w4,   // pin  9  RFin_W<4>
    input real rfin_w5,   // pin 11  RFin_W<5>
    input real rfin_w6,   // pin 13  RFin_W<6>
    input real rfin_w7,   // pin 15  RFin_W<7>
    // East side – pins 48,46,44,42,40,38,36,34
    input real rfin_e0,   // pin 48  RFin_E<0>
    input real rfin_e1,   // pin 46  RFin_E<1>
    input real rfin_e2,   // pin 44  RFin_E<2>
    input real rfin_e3,   // pin 42  RFin_E<3>
    input real rfin_e4,   // pin 40  RFin_E<4>
    input real rfin_e5,   // pin 38  RFin_E<5>
    input real rfin_e6,   // pin 36  RFin_E<6>
    input real rfin_e7,   // pin 34  RFin_E<7>

    // =========================================================================
    // SERIAL INTERFACE  (pins 19–22, daisy-chain SPI-like)
    // =========================================================================
    input  wire sda_b,    // pin 19  SCLK  (SdA_B)
    input  wire sdb_b,    // pin 20  MOSI  (SdB_B)
    output wire sdc_b,    // pin 21  MISO  (SdC_B)
    input  wire sdd_b,    // pin 22  CS_N  (SdD_B)

    // =========================================================================
    // SYSTEM CLOCK & TRIGGER  (implicit / assigned via spare / serial pins)
    // =========================================================================
    input  wire sys_clk,  // digital system clock  (e.g. 100 MHz)
    input  wire adc_clk,  // high-speed ADC sampling clock (2.4–3.6 GHz model)
    input  wire ser_clk,  // LVDS serialiser clock (≥12× ADC word rate)
    input  wire rst_n,    // active-low global reset
    input  wire acquire,  // trigger: rising edge starts capture on all channels

    // =========================================================================
    // LVDS DATA OUTPUTS  (pins 29–32)
    // =========================================================================
    output wire txout0_p, // pin 29  TxOut[0] positive
    output wire txout0_n,
    output wire txout1_p, // pin 30  TxOut[1] positive
    output wire txout1_n,
    output wire txout2_p, // pin 31  TxOut[2] positive
    output wire txout2_n,
    output wire txout3_p, // pin 32  TxOut[3] positive
    output wire txout3_n,

    // =========================================================================
    // LVDS CLOCK OUTPUTS  (pins 25–28)
    // =========================================================================
    output wire txclkout0_p, // pin 25
    output wire txclkout0_n,
    output wire txclkout1_p, // pin 26
    output wire txclkout1_n,
    output wire txclkout2_p, // pin 27
    output wire txclkout2_n,
    output wire txclkout3_p, // pin 28
    output wire txclkout3_n,

    // =========================================================================
    // STATUS (observable externally – derived from serial or spare pins)
    // =========================================================================
    output wire [3:0] data_ready_out  // per-channel DataReady flags
);

    // =========================================================================
    // Parameters
    // =========================================================================
    localparam ADC_BITS     = 12;
    localparam BUFFER_DEPTH = 16384;
    localparam ADDR_W       = 14;

    // =========================================================================
    // Internal wires
    // =========================================================================

    // ADC channel read-back bus
    wire [ADC_BITS-1:0]  adc_rd_data [0:3];
    wire [ADDR_W-1:0]    adc_rd_addr [0:3];
    wire [3:0]           ch_data_ready;
    wire [ADDR_W-1:0]    ch_sample_count [0:3];

    // Serial interface decoded signals
    wire                 soft_acquire;
    wire [1:0]           ch_select;
    wire [ADDR_W-1:0]    ser_rd_addr;

    // Combined acquire
    wire acq = acquire | soft_acquire;

    // =========================================================================
    // Channel input assignment
    // =========================================================================
    // Channel 0 : rfin_w0, rfin_w1, rfin_e0, rfin_e1
    // Channel 1 : rfin_w2, rfin_w3, rfin_e2, rfin_e3
    // Channel 2 : rfin_w4, rfin_w5, rfin_e4, rfin_e5
    // Channel 3 : rfin_w6, rfin_w7, rfin_e6, rfin_e7

    // =========================================================================
    // ADC Channels 0..3
    // =========================================================================
    genvar ch;
    generate
        // Channel 0
        asoc_v3_adc_channel #(
            .ADC_BITS(ADC_BITS), .BUFFER_DEPTH(BUFFER_DEPTH), .ADDR_W(ADDR_W)
        ) u_adc_ch0 (
            .adc_clk     (adc_clk),
            .sys_clk     (sys_clk),
            .rst_n       (rst_n),
            .rfin_0      (rfin_w0),
            .rfin_1      (rfin_w1),
            .rfin_2      (rfin_e0),
            .rfin_3      (rfin_e1),
            .acquire     (acq),
            .data_ready  (ch_data_ready[0]),
            .rd_addr     (adc_rd_addr[0]),
            .rd_data     (adc_rd_data[0]),
            .sample_count(ch_sample_count[0])
        );

        // Channel 1
        asoc_v3_adc_channel #(
            .ADC_BITS(ADC_BITS), .BUFFER_DEPTH(BUFFER_DEPTH), .ADDR_W(ADDR_W)
        ) u_adc_ch1 (
            .adc_clk     (adc_clk),
            .sys_clk     (sys_clk),
            .rst_n       (rst_n),
            .rfin_0      (rfin_w2),
            .rfin_1      (rfin_w3),
            .rfin_2      (rfin_e2),
            .rfin_3      (rfin_e3),
            .acquire     (acq),
            .data_ready  (ch_data_ready[1]),
            .rd_addr     (adc_rd_addr[1]),
            .rd_data     (adc_rd_data[1]),
            .sample_count(ch_sample_count[1])
        );

        // Channel 2
        asoc_v3_adc_channel #(
            .ADC_BITS(ADC_BITS), .BUFFER_DEPTH(BUFFER_DEPTH), .ADDR_W(ADDR_W)
        ) u_adc_ch2 (
            .adc_clk     (adc_clk),
            .sys_clk     (sys_clk),
            .rst_n       (rst_n),
            .rfin_0      (rfin_w4),
            .rfin_1      (rfin_w5),
            .rfin_2      (rfin_e4),
            .rfin_3      (rfin_e5),
            .acquire     (acq),
            .data_ready  (ch_data_ready[2]),
            .rd_addr     (adc_rd_addr[2]),
            .rd_data     (adc_rd_data[2]),
            .sample_count(ch_sample_count[2])
        );

        // Channel 3
        asoc_v3_adc_channel #(
            .ADC_BITS(ADC_BITS), .BUFFER_DEPTH(BUFFER_DEPTH), .ADDR_W(ADDR_W)
        ) u_adc_ch3 (
            .adc_clk     (adc_clk),
            .sys_clk     (sys_clk),
            .rst_n       (rst_n),
            .rfin_0      (rfin_w6),
            .rfin_1      (rfin_w7),
            .rfin_2      (rfin_e6),
            .rfin_3      (rfin_e7),
            .acquire     (acq),
            .data_ready  (ch_data_ready[3]),
            .rd_addr     (adc_rd_addr[3]),
            .rd_data     (adc_rd_data[3]),
            .sample_count(ch_sample_count[3])
        );
    endgenerate

    // =========================================================================
    // Multiplexed readback bus: serial interface reads from selected channel
    // =========================================================================
    wire [ADC_BITS-1:0] mux_rd_data   = adc_rd_data[ch_select];
    wire [ADDR_W-1:0]   mux_samp_cnt  = ch_sample_count[ch_select];

    // Route serial rd_addr to selected channel
    assign adc_rd_addr[0] = (ch_select == 2'd0) ? ser_rd_addr : 14'h0;
    assign adc_rd_addr[1] = (ch_select == 2'd1) ? ser_rd_addr : 14'h0;
    assign adc_rd_addr[2] = (ch_select == 2'd2) ? ser_rd_addr : 14'h0;
    assign adc_rd_addr[3] = (ch_select == 2'd3) ? ser_rd_addr : 14'h0;

    // =========================================================================
    // Serial Interface  (SdA_B..SdD_B → pins 19-22)
    // =========================================================================
    asoc_v3_serial_if #(
        .ADC_BITS(ADC_BITS), .ADDR_W(ADDR_W)
    ) u_serial_if (
        .sys_clk      (sys_clk),
        .rst_n        (rst_n),
        .sclk         (sda_b),
        .mosi         (sdb_b),
        .miso         (sdc_b),
        .cs_n         (sdd_b),
        .soft_acquire (soft_acquire),
        .ch_select    (ch_select),
        .rd_addr      (ser_rd_addr),
        .rd_data      (mux_rd_data),
        .data_ready   (ch_data_ready),
        .sample_count (mux_samp_cnt),
        .reg_addr_out (),
        .reg_data_out (),
        .reg_wr_out   ()
    );

    // =========================================================================
    // LVDS Transmitters  (TxOut[0..3], TxClkOut[0..3])
    // =========================================================================
    // Each channel has its own LVDS TX; rd_addr comes from the TX itself
    // (independent streaming readout after data_ready).

    wire [ADDR_W-1:0] tx_rd_addr [0:3];
    wire [3:0]        tx_active;

    // Disambiguate: during LVDS streaming the TX drives rd_addr.
    // We mux: if TX is active, TX wins; else serial-IF wins.
    // (In a real design separate ping-pong buffers or arbitration is used.)
    wire [ADDR_W-1:0] ch0_rd_addr_mux = tx_active[0] ? tx_rd_addr[0] : adc_rd_addr[0];
    wire [ADDR_W-1:0] ch1_rd_addr_mux = tx_active[1] ? tx_rd_addr[1] : adc_rd_addr[1];
    wire [ADDR_W-1:0] ch2_rd_addr_mux = tx_active[2] ? tx_rd_addr[2] : adc_rd_addr[2];
    wire [ADDR_W-1:0] ch3_rd_addr_mux = tx_active[3] ? tx_rd_addr[3] : adc_rd_addr[3];

    asoc_v3_lvds_tx #(.ADC_BITS(ADC_BITS),.BUFFER_DEPTH(BUFFER_DEPTH),.ADDR_W(ADDR_W))
    u_lvds_tx0 (
        .sys_clk    (sys_clk), .ser_clk (ser_clk), .rst_n (rst_n),
        .data_ready (ch_data_ready[0]), .tx_active (tx_active[0]),
        .rd_addr    (tx_rd_addr[0]),    .rd_data   (adc_rd_data[0]),
        .tx_p       (txout0_p),         .tx_n      (txout0_n),
        .clk_p      (txclkout0_p),      .clk_n     (txclkout0_n)
    );

    asoc_v3_lvds_tx #(.ADC_BITS(ADC_BITS),.BUFFER_DEPTH(BUFFER_DEPTH),.ADDR_W(ADDR_W))
    u_lvds_tx1 (
        .sys_clk    (sys_clk), .ser_clk (ser_clk), .rst_n (rst_n),
        .data_ready (ch_data_ready[1]), .tx_active (tx_active[1]),
        .rd_addr    (tx_rd_addr[1]),    .rd_data   (adc_rd_data[1]),
        .tx_p       (txout1_p),         .tx_n      (txout1_n),
        .clk_p      (txclkout1_p),      .clk_n     (txclkout1_n)
    );

    asoc_v3_lvds_tx #(.ADC_BITS(ADC_BITS),.BUFFER_DEPTH(BUFFER_DEPTH),.ADDR_W(ADDR_W))
    u_lvds_tx2 (
        .sys_clk    (sys_clk), .ser_clk (ser_clk), .rst_n (rst_n),
        .data_ready (ch_data_ready[2]), .tx_active (tx_active[2]),
        .rd_addr    (tx_rd_addr[2]),    .rd_data   (adc_rd_data[2]),
        .tx_p       (txout2_p),         .tx_n      (txout2_n),
        .clk_p      (txclkout2_p),      .clk_n     (txclkout2_n)
    );

    asoc_v3_lvds_tx #(.ADC_BITS(ADC_BITS),.BUFFER_DEPTH(BUFFER_DEPTH),.ADDR_W(ADDR_W))
    u_lvds_tx3 (
        .sys_clk    (sys_clk), .ser_clk (ser_clk), .rst_n (rst_n),
        .data_ready (ch_data_ready[3]), .tx_active (tx_active[3]),
        .rd_addr    (tx_rd_addr[3]),    .rd_data   (adc_rd_data[3]),
        .tx_p       (txout3_p),         .tx_n      (txout3_n),
        .clk_p      (txclkout3_p),      .clk_n     (txclkout3_n)
    );

    // =========================================================================
    // Status outputs
    // =========================================================================
    assign data_ready_out = ch_data_ready;

endmodule

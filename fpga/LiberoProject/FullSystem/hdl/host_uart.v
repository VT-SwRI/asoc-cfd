/////////////////////////////////////////////////////////////////////////////////////////////////////
// Company: SWRI/VT
//
// File: host_uart.v
// Description:
//    RX path : receives 19 bytes from the PC, asserts data_out_valid
//           for one clock cycle once all 19 bytes have arrived.
//
//    TX path : when data_in_valid pulses for one cycle, latches the 144-bit value
//           from bridge_fsm, packs it into exactly 18 bytes (big-endian, MSB
//           first), and streams them out over UART.
//
//    Packet layout (18 bytes, big-endian):
//     byte[0]  = data_in[143:136]    tag[63:56]
//     byte[1]  = data_in[135:128]    tag[55:48]
//     byte[2]  = data_in[127:120]    tag[47:40]
//     byte[3]  = data_in[119:112]    tag[39:32]
//     byte[4]  = data_in[111:104]    tag[31:24]
//     byte[5]  = data_in[103:96]     tag[23:16]
//     byte[6]  = data_in[95:88]      tag[15:8]
//     byte[7]  = data_in[87:80]      tag[7:0]
//     byte[8]  = data_in[79:72]      x[31:24]
//     byte[9]  = data_in[71:64]      x[23:16]
//     byte[10] = data_in[63:56]      x[15:8]
//     byte[11] = data_in[55:48]      x[7:0]
//     byte[12] = data_in[47:40]      y[31:24]
//     byte[13] = data_in[39:32]      y[23:16]
//     byte[14] = data_in[31:24]      y[15:8]
//     byte[15] = data_in[23:16]      y[7:0]
//     byte[16] = data_in[15:8]       mag[15:8]
//     byte[17] = data_in[7:0]        mag[7:0]
//
//    Neither RX nor TX path depends on the other : they run concurrently.
//
//    Submodules: uart_rx and uart_tx (replaces earlier receiver/transmitter pair).
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: VT MDE S26-23
/////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module host_uart #(
    parameter CLKS_PER_BIT    = 43,
    parameter DATA_INPUT_SIZE = 151
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        rx,
    output wire        tx,

    // RX downstream module
    output reg  [DATA_INPUT_SIZE - 1:0] data_out,        // stable when data_out_valid pulses
    output reg                          data_out_valid,  // single-cycle pulse

    // bridge_fsm TX
    input  wire [143:0] data_in,           // {tag[63:0], x[31:0], y[31:0], mag[15:0]}
    input  wire         data_in_valid      // single-cycle pulse from bridge_fsm
);

    //
    // Sub-module wiring
    //
    wire       rx_dv;
    wire [7:0] rx_byte;

    wire       tx_active;
    wire [7:0] tx_byte;
    wire       tx_dv;
    wire       tx_done;   // available but unused

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_uart_rx (
        .i_clk       (clk),
        .i_rst       (rst),
        .i_rx_serial (rx),
        .o_rx_dv     (rx_dv),
        .o_rx_byte   (rx_byte)
    );

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_uart_tx (
        .i_clk       (clk),
        .i_rst       (rst),
        .i_tx_dv     (tx_dv),
        .i_tx_byte   (tx_byte),
        .o_tx_active (tx_active),
        .o_tx_serial (tx),
        .o_tx_done   (tx_done)
    );

    //
    // RX FSM : collect 19 bytes, then pulse data_out_valid for one cycle
    //
    localparam RXS_RECV = 1'b0,
               RXS_DONE = 1'b1;

    reg       rx_state;
    reg [4:0] rx_idx;
    reg [7:0] rx_buf [0:18];

    integer rx_init_i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_state       <= RXS_RECV;
            rx_idx         <= 5'd0;
            data_out       <= {DATA_INPUT_SIZE{1'b0}};
            data_out_valid <= 1'b0;
            for (rx_init_i = 0; rx_init_i < 19; rx_init_i = rx_init_i + 1)
                rx_buf[rx_init_i] <= 8'h00;
        end else begin
            data_out_valid <= 1'b0;

            case (rx_state)

                RXS_RECV: begin
                    if (rx_dv) begin
                        rx_buf[rx_idx] <= rx_byte;
                        if (rx_idx == 5'd18) begin
                            rx_idx   <= 5'd0;
                            rx_state <= RXS_DONE;
                        end else begin
                            rx_idx <= rx_idx + 5'd1;
                        end
                    end
                end

                RXS_DONE: begin
                    // Big-endian assembly: buf[0][6:0] are the top 7 bits;
                    // bit 7 of buf[0] is discarded (frame padding).
                    data_out <= {       rx_buf[0][6:0], rx_buf[1],  rx_buf[2],  rx_buf[3],
                                        rx_buf[4],      rx_buf[5],  rx_buf[6],  rx_buf[7],
                                        rx_buf[8],      rx_buf[9],  rx_buf[10], rx_buf[11],
                                        rx_buf[12],     rx_buf[13], rx_buf[14], rx_buf[15],
                                        rx_buf[16],     rx_buf[17], rx_buf[18]};
                    data_out_valid <= 1'b1;
                    rx_state       <= RXS_RECV;
                end

                default: rx_state <= RXS_RECV;

            endcase
        end
    end

    //
    // TX FSM : latch 144-bit input from bridge_fsm, send as 18 bytes MSB-first
    //
    localparam [2:0] TXS_IDLE       = 3'd0,
                     TXS_LOAD       = 3'd1,
                     TXS_SEND       = 3'd2,
                     TXS_WAIT_START = 3'd3,
                     TXS_WAIT_END   = 3'd4;

    reg [2:0] tx_state;
    reg [4:0] tx_idx;
    reg [7:0] tx_buf [0:17];

    integer tx_init_i;

    assign tx_byte = tx_buf[tx_idx];
    assign tx_dv   = (tx_state == TXS_SEND) && !tx_active;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_state <= TXS_IDLE;
            tx_idx   <= 5'd0;
            for (tx_init_i = 0; tx_init_i < 18; tx_init_i = tx_init_i + 1)
                tx_buf[tx_init_i] <= 8'h00;
        end else begin
            case (tx_state)

                TXS_IDLE: begin
                    if (data_in_valid) begin
                        tx_buf[0]  <= data_in[143:136];
                        tx_buf[1]  <= data_in[135:128];
                        tx_buf[2]  <= data_in[127:120];
                        tx_buf[3]  <= data_in[119:112];
                        tx_buf[4]  <= data_in[111:104];
                        tx_buf[5]  <= data_in[103:96];
                        tx_buf[6]  <= data_in[95:88];
                        tx_buf[7]  <= data_in[87:80];
                        tx_buf[8]  <= data_in[79:72];
                        tx_buf[9]  <= data_in[71:64];
                        tx_buf[10] <= data_in[63:56];
                        tx_buf[11] <= data_in[55:48];
                        tx_buf[12] <= data_in[47:40];
                        tx_buf[13] <= data_in[39:32];
                        tx_buf[14] <= data_in[31:24];
                        tx_buf[15] <= data_in[23:16];
                        tx_buf[16] <= data_in[15:8];
                        tx_buf[17] <= data_in[7:0];
                        tx_idx     <= 5'd0;
                        tx_state   <= TXS_LOAD;
                    end
                end

                TXS_LOAD: begin
                    tx_state <= TXS_SEND;
                end

                TXS_SEND: begin
                    if (!tx_active) begin
                        tx_idx <= tx_idx + 5'd1;
                        if (tx_idx == 5'd17)
                            tx_state <= TXS_WAIT_START;
                    end
                end

                TXS_WAIT_START: begin
                    if (tx_active) tx_state <= TXS_WAIT_END;
                end

                TXS_WAIT_END: begin
                    if (!tx_active) tx_state <= TXS_IDLE;
                end

                default: tx_state <= TXS_IDLE;

            endcase
        end
    end

endmodule
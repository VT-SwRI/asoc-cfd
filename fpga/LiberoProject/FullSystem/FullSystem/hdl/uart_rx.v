///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: uart_rx.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

`timescale 1ns/1ps

module uart_rx
#(
    parameter integer CLKS_PER_BIT = 347  // Example: 40 MHz clock, 115200 baud
)
(
    input  wire       i_clk,
    input  wire       i_rst,     // active-low reset
    input  wire       i_rx_serial, // UART RX line from USB-UART adapter TX

    output reg        o_rx_dv,     // 1-clock pulse when a byte is received
    output reg [7:0]  o_rx_byte    // received byte
);

    //========================================================
    // Synchronizer for asynchronous UART input
    //========================================================
    reg r_rx_meta;
    reg r_rx_sync;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_rx_meta <= 1'b1;
            r_rx_sync <= 1'b1;
        end else begin
            r_rx_meta <= i_rx_serial;
            r_rx_sync <= r_rx_meta;
        end
    end

    //========================================================
    // State encoding
    //========================================================
    localparam [2:0] S_IDLE      = 3'd0;
    localparam [2:0] S_RX_START  = 3'd1;
    localparam [2:0] S_RX_DATA   = 3'd2;
    localparam [2:0] S_RX_STOP   = 3'd3;
    localparam [2:0] S_CLEANUP   = 3'd4;

    reg [2:0] r_state;
    reg [15:0] r_clk_count;
    reg [2:0]  r_bit_index;
    reg [7:0]  r_rx_byte;

    //========================================================
    // UART RX FSM
    //========================================================
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_state     <= S_IDLE;
            r_clk_count <= 16'd0;
            r_bit_index <= 3'd0;
            r_rx_byte   <= 8'd0;
            o_rx_byte   <= 8'd0;
            o_rx_dv     <= 1'b0;
        end else begin
            // default
            o_rx_dv <= 1'b0;

            case (r_state)

                //================================================
                // Wait for line to go low = start bit
                // UART line sits high when idle
                //================================================
                S_IDLE: begin
                    r_clk_count <= 16'd0;
                    r_bit_index <= 3'd0;

                    if (r_rx_sync == 1'b0)
                        r_state <= S_RX_START;
                    else
                        r_state <= S_IDLE;
                end

                //================================================
                // Move to middle of start bit and confirm it is
                // still low. This rejects glitches/noise.
                //================================================
                S_RX_START: begin
                    if (r_clk_count == (CLKS_PER_BIT-1)/2) begin
                        if (r_rx_sync == 1'b0) begin
                            r_clk_count <= 16'd0;
                            r_state     <= S_RX_DATA;
                        end else begin
                            // False start, go back to idle
                            r_state <= S_IDLE;
                        end
                    end else begin
                        r_clk_count <= r_clk_count + 16'd1;
                        r_state     <= S_RX_START;
                    end
                end

                //================================================
                // Sample each data bit in the middle of the bit
                // period. UART sends LSB first.
                //================================================
                S_RX_DATA: begin
                    if (r_clk_count < CLKS_PER_BIT-1) begin
                        r_clk_count <= r_clk_count + 16'd1;
                        r_state     <= S_RX_DATA;
                    end else begin
                        r_clk_count <= 16'd0;

                        r_rx_byte[r_bit_index] <= r_rx_sync;

                        if (r_bit_index < 3'd7) begin
                            r_bit_index <= r_bit_index + 3'd1;
                            r_state     <= S_RX_DATA;
                        end else begin
                            r_bit_index <= 3'd0;
                            r_state     <= S_RX_STOP;
                        end
                    end
                end

                //================================================
                // Sample stop bit. For a valid UART frame, stop
                // bit should be high.
                //================================================
                S_RX_STOP: begin
                    if (r_clk_count < CLKS_PER_BIT-1) begin
                        r_clk_count <= r_clk_count + 16'd1;
                        r_state     <= S_RX_STOP;
                    end else begin
                        o_rx_byte   <= r_rx_byte;
                        o_rx_dv     <= 1'b1;
                        r_clk_count <= 16'd0;
                        r_state     <= S_CLEANUP;
                    end
                end

                //================================================
                // Single-cycle cleanup state
                //================================================
                S_CLEANUP: begin
                    r_state <= S_IDLE;
                end
  
                default: begin
                    r_state <= S_IDLE;
                end
            endcase
        end
    end

endmodule


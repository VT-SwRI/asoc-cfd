///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: uart_tx.v
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

module uart_tx
#(
    parameter integer CLKS_PER_BIT = 347
)
(
    input  wire       i_clk,
    input  wire       i_rst,
    input  wire       i_tx_dv,      // pulse high for 1 clock to start transmit
    input  wire [7:0] i_tx_byte,    // byte to transmit

    output reg        o_tx_active,  // high while transmission is in progress
    output reg        o_tx_serial,  // UART TX line
    output reg        o_tx_done     // 1-clock pulse when finished
);

    localparam [2:0] S_IDLE      = 3'd0;
    localparam [2:0] S_TX_START  = 3'd1;
    localparam [2:0] S_TX_DATA   = 3'd2;
    localparam [2:0] S_TX_STOP   = 3'd3;
    localparam [2:0] S_CLEANUP   = 3'd4;

    reg [2:0]  r_state;
    reg [15:0] r_clk_count;
    reg [2:0]  r_bit_index;
    reg [7:0]  r_tx_data;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_state     <= S_IDLE;
            r_clk_count <= 16'd0;
            r_bit_index <= 3'd0;
            r_tx_data   <= 8'd0;
            o_tx_active <= 1'b0;
            o_tx_serial <= 1'b1; // idle line is high
            o_tx_done   <= 1'b0;
        end else begin
            o_tx_done <= 1'b0;

            case (r_state)
                S_IDLE: begin
                    o_tx_serial <= 1'b1;
                    o_tx_active <= 1'b0;
                    r_clk_count <= 16'd0;
                    r_bit_index <= 3'd0;

                    if (i_tx_dv) begin
                        r_tx_data   <= i_tx_byte;
                        o_tx_active <= 1'b1;
                        r_state     <= S_TX_START;
                    end
                end

                S_TX_START: begin
                    o_tx_serial <= 1'b0; // start bit

                    if (r_clk_count < CLKS_PER_BIT-1) begin
                        r_clk_count <= r_clk_count + 16'd1;
                    end else begin
                        r_clk_count <= 16'd0;
                        r_state     <= S_TX_DATA;
                    end
                end

                S_TX_DATA: begin
                    o_tx_serial <= r_tx_data[r_bit_index];

                    if (r_clk_count < CLKS_PER_BIT-1) begin
                        r_clk_count <= r_clk_count + 16'd1;
                    end else begin
                        r_clk_count <= 16'd0;

                        if (r_bit_index < 3'd7) begin
                            r_bit_index <= r_bit_index + 3'd1;
                        end else begin
                            r_bit_index <= 3'd0;
                            r_state     <= S_TX_STOP;
                        end
                    end
                end

                S_TX_STOP: begin
                    o_tx_serial <= 1'b1; // stop bit

                    if (r_clk_count < CLKS_PER_BIT-1) begin
                        r_clk_count <= r_clk_count + 16'd1;
                    end else begin
                        r_clk_count <= 16'd0;
                        o_tx_done   <= 1'b1;
                        r_state     <= S_CLEANUP;
                    end
                end

                S_CLEANUP: begin
                    o_tx_active <= 1'b0;
                    r_state     <= S_IDLE;
                end

                default: begin
                    r_state <= S_IDLE;
                end
            endcase
        end
    end

endmodule


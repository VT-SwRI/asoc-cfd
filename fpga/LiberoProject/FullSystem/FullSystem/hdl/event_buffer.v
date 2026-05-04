///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: event_buffer.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description:
//
//   Stores a parsed event in 4 BRAM-mapped sample arrays, then on i_event_commit
//   replays the samples one per clock to the DSP pipeline as o_adc_x1/x2/y1/y2
//   with o_adc_valid strobed.
//
//   The `acquire` input gates the replay: o_adc_valid is held low whenever
//   acquire is deasserted, so the DSP only sees samples when the GUI has
//   commanded data acquisition (start_stop = 1). Writes from the parser are
//   always accepted regardless of acquire.
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: <Name>
//
///////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module event_buffer #(
    parameter integer MAX_SAMPLES = 1024,
    parameter integer IDLE_GAP    = 4
)(
    input  wire        i_clk,
    input  wire        i_rst,

    // GUI-controlled acquisition gate (1 = pass samples to DSP, 0 = hold off)
    input  wire        acquire,

    // write side from parser
    input  wire        i_wr_en,
    input  wire [15:0] i_wr_addr,
    input  wire [11:0] i_wr_x1,
    input  wire [11:0] i_wr_x2,
    input  wire [11:0] i_wr_y1,
    input  wire [11:0] i_wr_y2,

    input  wire [15:0] i_sample_count,
    input  wire        i_event_commit,

    // replay side to DSP
    output reg         o_adc_valid,
    output reg  [11:0] o_adc_x1,
    output reg  [11:0] o_adc_x2,
    output reg  [11:0] o_adc_y1,
    output reg  [11:0] o_adc_y2,

    output reg         o_busy
);

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2 = 0;
            while (v > 0) begin
                v = v >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam integer ADDR_W = clog2(MAX_SAMPLES);
    localparam integer GAP_W  = clog2(IDLE_GAP + 1);

    localparam [1:0]
        S_IDLE  = 2'd0,
        S_BURST = 2'd1,
        S_GAP   = 2'd2;

    reg [1:0] r_state;

    reg [11:0] mem_x1 [0:MAX_SAMPLES-1];
    reg [11:0] mem_x2 [0:MAX_SAMPLES-1];
    reg [11:0] mem_y1 [0:MAX_SAMPLES-1];
    reg [11:0] mem_y2 [0:MAX_SAMPLES-1];

    reg [ADDR_W-1:0] r_rd_addr;
    reg [15:0]       r_burst_remaining;
    reg [GAP_W-1:0]  r_gap_cnt;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_state           <= S_IDLE;
            r_rd_addr         <= {ADDR_W{1'b0}};
            r_burst_remaining <= 16'd0;
            r_gap_cnt         <= {GAP_W{1'b0}};

            o_adc_valid <= 1'b0;
            o_adc_x1    <= 12'd0;
            o_adc_x2    <= 12'd0;
            o_adc_y1    <= 12'd0;
            o_adc_y2    <= 12'd0;
            o_busy      <= 1'b0;
        end else begin
            if (i_wr_en) begin
                mem_x1[i_wr_addr[ADDR_W-1:0]] <= i_wr_x1;
                mem_x2[i_wr_addr[ADDR_W-1:0]] <= i_wr_x2;
                mem_y1[i_wr_addr[ADDR_W-1:0]] <= i_wr_y1;
                mem_y2[i_wr_addr[ADDR_W-1:0]] <= i_wr_y2;
            end

            case (r_state)
                S_IDLE: begin
                    o_busy      <= 1'b0;
                    o_adc_valid <= 1'b0;
                    o_adc_x1    <= 12'd0;
                    o_adc_x2    <= 12'd0;
                    o_adc_y1    <= 12'd0;
                    o_adc_y2    <= 12'd0;

                    if (i_event_commit) begin
                        o_busy            <= 1'b1;
                        r_rd_addr         <= {ADDR_W{1'b0}};
                        r_burst_remaining <= i_sample_count;
                        r_state           <= S_BURST;
                    end
                end

                S_BURST: begin
                    o_busy      <= 1'b1;
                    o_adc_valid <= acquire;   // gated by GUI start_stop

                    o_adc_x1 <= mem_x1[r_rd_addr];
                    o_adc_x2 <= mem_x2[r_rd_addr];
                    o_adc_y1 <= mem_y1[r_rd_addr];
                    o_adc_y2 <= mem_y2[r_rd_addr];

                    r_rd_addr         <= r_rd_addr + 1'b1;
                    r_burst_remaining <= r_burst_remaining - 16'd1;

                    if (r_burst_remaining == 16'd1) begin
                        r_gap_cnt <= {GAP_W{1'b0}};
                        r_state   <= S_GAP;
                    end
                end

                S_GAP: begin
                    o_busy      <= 1'b1;
                    o_adc_valid <= 1'b0;
                    o_adc_x1    <= 12'd0;
                    o_adc_x2    <= 12'd0;
                    o_adc_y1    <= 12'd0;
                    o_adc_y2    <= 12'd0;

                    if (IDLE_GAP == 0) begin
                        o_busy  <= 1'b0;
                        r_state <= S_IDLE;
                    end else if (r_gap_cnt == IDLE_GAP[GAP_W-1:0] - 1'b1) begin
                        o_busy  <= 1'b0;
                        r_state <= S_IDLE;
                    end else begin
                        r_gap_cnt <= r_gap_cnt + 1'b1;
                    end
                end

                default: begin
                    r_state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
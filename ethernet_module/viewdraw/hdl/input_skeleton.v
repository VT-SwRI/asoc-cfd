///////////////////////////////////////////////////////////////////////////////////////////////////
// Author: Zack Kreitzer
//
// File: input_skeleton.v
// File history:
//      1: 2/2/26: Initial design concept for Input module
//
// Description: 
//
// Describes the input module to receive input from an ASOC Nalu digitizer
// Assumes the input from Nalu is 15 bits with 12 data bits, 1 valid bit, and 2 channel 
// encoding bits
// Assumes nalu data comes in as {valid, channel, padding, data}
//
// Targeted device: <Family::ProASIC3> <Die::A3PN250> <Package::100 VQFP>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module input_skeleton(clk, reset_n, timestamp, sys_en, nalu_data, nalu_clk, nalu_rst_n, valid, ch1, ch2, ch3, ch4, time_out);
    input       [15:0]  nalu_data;
    input               nalu_clk;
    input               nalu_rst_n;
    input               clk;
    input               reset_n;
    input       [51:0]  timestamp;
    input               sys_en;
    output reg          valid;
    output      [51:0]  time_out;
    output reg  [11:0]  ch1, ch2, ch3, ch4;

    // pass along time
    assign time_out = timestamp;

    // demultiplex the nalu input data
    wire        data_valid      = nalu_data[15];
    wire [1:0]  data_channel    = nalu_data[14:13];
    wire [11:0] data_sample     = nalu_data[11:0];

    // write side for FIFO
    wire        wr_en;
    wire [13:0] wr_data;

    assign wr_en = data_valid;
    assign wr_data = {data_channel, data_sample};

    // read side for FIFO
    wire        rd_en;
    wire [13:0] rd_data;
    wire        empty;
    wire        full;

    // 48-bit buffer to hold channel data before passing
    reg [11:0] channel_data [3:0];
    reg [3:0]  channel_valid;

    wire [1:0] rd_chan = rd_data[13:12];
    wire [11:0] rd_val = rd_data[11:0];

    assign rd_en = !empty && (channel_valid != 4'b1111);

    async_fifo #(
        .DATA_WIDTH(14),
        .DEPTH(1024)
    ) big_buffer (
        .wr_clk   (nalu_clk),
        .wr_rst_n   (nalu_rst_n),
        .wr_en    (wr_en),
        .din      (wr_data),
        .full     (full),

        .rd_clk   (clk),
        .rd_rst_n   (reset_n),
        .rd_en    (rd_en),
        .dout     (rd_data),
        .empty    (empty)
    );


    // channel logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            channel_valid   <= 4'b0000;
            valid <= 1'b0;
        end else begin
            valid <= 1'b0;
            // write data to specific channel
            if (rd_en) begin
                channel_data[rd_chan] <= rd_val;
                channel_valid[rd_chan] <= 1'b1;
            end

            // When all 4 channels are present
            if (channel_valid == 4'b1111) begin
                ch1 <= channel_data[0];
                ch2 <= channel_data[1];
                ch3 <= channel_data[2];
                ch4 <= channel_data[3];

                valid <= 1'b1;
                channel_valid   <= 4'b0000; // ready for next set
            end
        end
    end
    


endmodule


///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: SwRI/VT
//
// File: adc_preprocess_4ch.v
// File history: 
//
//
// Description: 
//
// The following module preprocesses 4 12-bit ADC channels by calculating baseline values using
// the average of the first 8 samples on each channel, and subtracting these baselines from all
// samples in the corresponding channels for the entirety of the event.
//
// The start of an event is indicated by in_valid going high, and the end of an event is indicated
// by in_valid going low. If an input event has fewer than 8 samples (per channel), then no 
// output is produced.
//
// This module introduces a total of 9 cycles of latency.
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: VT MDE S26-23
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

module adc_preprocess_4ch (
    input  wire        clk,
    input  wire        rst,

    // UQ12.0 Raw 12-bit ADC inputs (active when in_valid is high)
    input  wire        in_valid,
    input  wire [11:0] x1_raw,
    input  wire [11:0] x2_raw,
    input  wire [11:0] y1_raw,
    input  wire [11:0] y2_raw,

    // Event tag (registered on rising edge of in_valid)
    input  wire [63:0] tag_in,
    output reg  [63:0] tag_out,

    // Q12.3 Outputs with baseline subtracted (active when out_valid is high)
    output reg         out_valid,
    output reg  signed [15:0] x1_out,
    output reg  signed [15:0] x2_out,
    output reg  signed [15:0] y1_out,
    output reg  signed [15:0] y2_out
);

    // delayed in_valid
    reg in_valid_d;

    always @(posedge clk or posedge rst) begin
        if (rst)
            in_valid_d <= 1'b0;
        else
            in_valid_d <= in_valid;
    end

    wire event_start = in_valid & ~in_valid_d;

    // tag register, latched at the start of each event
    reg [63:0] tag_reg;

    always @(posedge clk or posedge rst) begin
        if (rst)
            tag_reg <= 64'd0;
        else if (event_start)
            tag_reg <= tag_in;
    end

    reg baseline_done;

    // Flush logic
    // When in_valid drops, flush_active goes high for 8 cycles to drain the shift register.
    // If a new event starts mid-flush, the new samples push old ones through naturally.

    reg        flush_active;
    reg  [2:0] flush_cnt;

    // saved baselines and tag so a new event doesn't corrupt the flush subtraction
    reg [14:0] flush_bl_x1, flush_bl_x2, flush_bl_y1, flush_bl_y2;
    reg [63:0] flush_tag;

    // per-channel baselines
    reg [14:0] bl_x1, bl_x2, bl_y1, bl_y2;

    // single-cycle bridge between in_valid dropping and flush_active going high
    wire start_flush = baseline_done & in_valid_d & ~in_valid & ~flush_active;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset to defaults
            flush_active <= 1'b0;
            flush_cnt    <= 3'd0;
            flush_bl_x1  <= 15'd0;
            flush_bl_x2  <= 15'd0;
            flush_bl_y1  <= 15'd0;
            flush_bl_y2  <= 15'd0;
            flush_tag    <= 64'd0;
        end else if (start_flush) begin
            // start new flush
            flush_active <= 1'b1;
            flush_cnt    <= 3'd6;
            flush_bl_x1  <= bl_x1;
            flush_bl_x2  <= bl_x2;
            flush_bl_y1  <= bl_y1;
            flush_bl_y2  <= bl_y2;
            flush_tag    <= tag_reg;
        end else if (flush_active) begin
            // continue currently active flush
            if (flush_cnt == 3'd0)
                flush_active <= 1'b0;
            else
                flush_cnt <= flush_cnt - 3'd1;
        end
    end

    // shift enable - active during valid input, flush, or the bridge cycle
    wire do_shift = in_valid | flush_active | start_flush;

    // 8-deep shift registers for each channel
    // new samples enter at [0], the oldest exit at [7]
    // during flush without new event, zeros enter
    reg [11:0] sr_x1 [0:7];
    reg [11:0] sr_x2 [0:7];
    reg [11:0] sr_y1 [0:7];
    reg [11:0] sr_y2 [0:7];

    wire [11:0] sr_in_x1 = in_valid ? x1_raw : 12'd0;
    wire [11:0] sr_in_x2 = in_valid ? x2_raw : 12'd0;
    wire [11:0] sr_in_y1 = in_valid ? y1_raw : 12'd0;
    wire [11:0] sr_in_y2 = in_valid ? y2_raw : 12'd0;

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                sr_x1[i] <= 12'd0;
                sr_x2[i] <= 12'd0;
                sr_y1[i] <= 12'd0;
                sr_y2[i] <= 12'd0;
            end
        end else if (do_shift) begin
            sr_x1[0] <= sr_in_x1;
            sr_x2[0] <= sr_in_x2;
            sr_y1[0] <= sr_in_y1;
            sr_y2[0] <= sr_in_y2;
            for (i = 1; i < 8; i = i + 1) begin
                sr_x1[i] <= sr_x1[i-1];
                sr_x2[i] <= sr_x2[i-1];
                sr_y1[i] <= sr_y1[i-1];
                sr_y2[i] <= sr_y2[i-1];
            end
        end
    end

    // Baseline accumulators
    // sum of first 8 samples per channel (15-bit, max = 32760 = 8*4095)
    // this sum is the average in UQ12.3
    reg [3:0] accum_cnt;

    wire accumulating = in_valid & ~baseline_done;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset
            bl_x1         <= 15'd0;
            bl_x2         <= 15'd0;
            bl_y1         <= 15'd0;
            bl_y2         <= 15'd0;
            accum_cnt     <= 4'd0;
            baseline_done <= 1'b0;
        end else if (event_start) begin
            // start new event
            bl_x1         <= {3'd0, x1_raw};
            bl_x2         <= {3'd0, x2_raw};
            bl_y1         <= {3'd0, y1_raw};
            bl_y2         <= {3'd0, y2_raw};
            accum_cnt     <= 4'd1;
            baseline_done <= 1'b0;
        end else if (accumulating) begin
            // continue accumulation of current event
            bl_x1 <= bl_x1 + {3'd0, x1_raw};
            bl_x2 <= bl_x2 + {3'd0, x2_raw};
            bl_y1 <= bl_y1 + {3'd0, y1_raw};
            bl_y2 <= bl_y2 + {3'd0, y2_raw};
            accum_cnt <= accum_cnt + 4'd1;
            if (accum_cnt == 4'd7)
                baseline_done <= 1'b1;
        end
    end

    wire flush_outputting = flush_active | start_flush;

    // baseline mux: 
    // use saved flush baseline during when a flush is active, otherwise use the current baseline
    wire [14:0] out_bl_x1 = flush_active ? flush_bl_x1 : bl_x1;
    wire [14:0] out_bl_x2 = flush_active ? flush_bl_x2 : bl_x2;
    wire [14:0] out_bl_y1 = flush_active ? flush_bl_y1 : bl_y1;
    wire [14:0] out_bl_y2 = flush_active ? flush_bl_y2 : bl_y2;

    // tag mux:
    // use saved flush tag during when a flush is active, otherwise use the current tag
    wire [63:0] tag_mux = flush_active ? flush_tag : tag_reg;

    // pad delayed samples to UQ12.3 and subtract the baseline
    wire [14:0] padded_x1 = {sr_x1[7], 3'b000};
    wire [14:0] padded_x2 = {sr_x2[7], 3'b000};
    wire [14:0] padded_y1 = {sr_y1[7], 3'b000};
    wire [14:0] padded_y2 = {sr_y2[7], 3'b000};

    // output valid from normal streaming or flush
    wire stream_out = baseline_done & in_valid & ~event_start;
    wire producing  = stream_out | flush_outputting;

    // register output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset
            out_valid <= 1'b0;
            x1_out    <= 16'sd0;
            x2_out    <= 16'sd0;
            y1_out    <= 16'sd0;
            y2_out    <= 16'sd0;
            tag_out   <= 64'd0;
        end else begin
            // register outputs when producing
            out_valid <= producing;
            if (producing) begin
                x1_out  <= $signed({1'b0, padded_x1}) - $signed({1'b0, out_bl_x1});
                x2_out  <= $signed({1'b0, padded_x2}) - $signed({1'b0, out_bl_x2});
                y1_out  <= $signed({1'b0, padded_y1}) - $signed({1'b0, out_bl_y1});
                y2_out  <= $signed({1'b0, padded_y2}) - $signed({1'b0, out_bl_y2});
                tag_out <= tag_mux;
            end
        end
    end

endmodule
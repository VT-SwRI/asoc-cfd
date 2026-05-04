///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: SwRI/VT
//
// File: peak_detector_4ch.v
// File history:
//
// Description:
//
// Finds the peak (max signed value) of each of 4 ADC channels over an event, sums the
// 4 peaks, and outputs the result as Q15.0 signed (truncated from Q12.3 input). Event
// boundaries follow in_valid: high = active, low = end of event. Timestamp tag is captured on
// the first sample of each burst.
//
// Total latency: 3 cycles
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: VT MDE S26-23
//
///////////////////////////////////////////////////////////////////////////////////////////////////

`default_nettype none

module peak_detector_4ch #(
    parameter integer ADC_WIDTH = 16,
    parameter integer TS_WIDTH  = 64,
    parameter integer OUT_WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  in_valid,
    input  wire signed [ADC_WIDTH-1:0] adc0,
    input  wire signed [ADC_WIDTH-1:0] adc1,
    input  wire signed [ADC_WIDTH-1:0] adc2,
    input  wire signed [ADC_WIDTH-1:0] adc3,
    input  wire        [TS_WIDTH-1:0]  in_timestamp,

    output reg                   out_valid,
    (* syn_preserve = "true" *) output reg signed [OUT_WIDTH-1:0] out_sum,
    output reg         [TS_WIDTH-1:0]  out_timestamp
);

    localparam integer FRAC_BITS      = 3;                // Q12.3 -> Q15.0
    localparam integer PEAK_SUM_WIDTH = ADC_WIDTH + 2;    // sum of 4 signed values
    localparam signed [ADC_WIDTH-1:0] PEAK_MIN = {1'b1, {(ADC_WIDTH-1){1'b0}}};

    // input registers
    reg                        in_valid_r;
    reg signed [ADC_WIDTH-1:0] adc0_r, adc1_r, adc2_r, adc3_r;
    reg        [TS_WIDTH-1:0]  in_timestamp_r;

    // per-channel peak tracking
    reg signed [ADC_WIDTH-1:0] peak0, peak1, peak2, peak3;

    reg                        prev_valid;
    reg        [TS_WIDTH-1:0]  registered_ts;

    // internal output stage (single-cycle pulse at end of burst)
    reg                                     internal_valid;
    (* syn_preserve = "true" *) reg signed [OUT_WIDTH-1:0] internal_sum;
    reg        [TS_WIDTH-1:0]               internal_timestamp;

    // sum of 4 peaks, then truncate fractional bits with sign extension
    wire signed [PEAK_SUM_WIDTH-1:0] peak_sum = peak0 + peak1 + peak2 + peak3;
    wire signed [OUT_WIDTH-1:0] peak_sum_truncated =
        {{(OUT_WIDTH - (PEAK_SUM_WIDTH - FRAC_BITS)){peak_sum[PEAK_SUM_WIDTH-1]}},
         peak_sum[PEAK_SUM_WIDTH-1:FRAC_BITS]};

    // register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_valid_r     <= 1'b0;
            adc0_r         <= {ADC_WIDTH{1'b0}};
            adc1_r         <= {ADC_WIDTH{1'b0}};
            adc2_r         <= {ADC_WIDTH{1'b0}};
            adc3_r         <= {ADC_WIDTH{1'b0}};
            in_timestamp_r <= {TS_WIDTH{1'b0}};
        end else begin
            in_valid_r     <= in_valid;
            adc0_r         <= adc0;
            adc1_r         <= adc1;
            adc2_r         <= adc2;
            adc3_r         <= adc3;
            in_timestamp_r <= in_timestamp;
        end
    end

    // main logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset
            prev_valid         <= 1'b0;
            registered_ts      <= {TS_WIDTH{1'b0}};
            peak0              <= PEAK_MIN;
            peak1              <= PEAK_MIN;
            peak2              <= PEAK_MIN;
            peak3              <= PEAK_MIN;
            internal_valid     <= 1'b0;
            internal_sum       <= {OUT_WIDTH{1'b0}};
            internal_timestamp <= {TS_WIDTH{1'b0}};
        end else begin
            internal_valid <= 1'b0;

            if (in_valid_r) begin
                prev_valid <= 1'b1;

                if (!prev_valid) begin
                    // first sample: capture timestamp, seed peaks
                    registered_ts <= in_timestamp_r;
                    peak0         <= adc0_r;
                    peak1         <= adc1_r;
                    peak2         <= adc2_r;
                    peak3         <= adc3_r;
                end else begin
                    // update peaks
                    if (adc0_r > peak0) peak0 <= adc0_r;
                    if (adc1_r > peak1) peak1 <= adc1_r;
                    if (adc2_r > peak2) peak2 <= adc2_r;
                    if (adc3_r > peak3) peak3 <= adc3_r;
                end
            end else if (prev_valid) begin
                // end of burst: output result, reset peaks
                prev_valid         <= 1'b0;
                internal_valid     <= 1'b1;
                internal_sum       <= peak_sum_truncated;
                internal_timestamp <= registered_ts;
                peak0              <= PEAK_MIN;
                peak1              <= PEAK_MIN;
                peak2              <= PEAK_MIN;
                peak3              <= PEAK_MIN;
            end
        end
    end

    // output pipeline register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_valid     <= 1'b0;
            out_sum       <= {OUT_WIDTH{1'b0}};
            out_timestamp <= {TS_WIDTH{1'b0}};
        end else begin
            out_valid     <= internal_valid;
            out_sum       <= internal_sum;
            out_timestamp <= internal_timestamp;
        end
    end

endmodule

`default_nettype wire
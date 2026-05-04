///////////////////////////////////////////////////////////////////////////////////////////////////
// File: timestamp_generator.v
//
// Description:
//   64-bit microsecond timestamp generator. Loads an initial epoch-microsecond
//   value from the host (Python: int(time.time() * 1_000_000)) when
//   set_time_valid pulses, then increments locally once per microsecond.
//
//   Self-contained: derives the 1 us tick directly from `clk` via a
//   modulo-CLKS_PER_US divider. PPS support has been removed.
//
//   On reset the timestamp is zero. After the host pulses set_time_valid the
//   running count tracks the host wall clock to within +/- 1 us.
//
// Parameters:
//   CLK_FREQ - Input clock frequency in Hz (default 40 MHz => 40 clocks/us)
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
///////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module timestamp_generator #(
    parameter integer CLK_FREQ = 40_000_000
)(
    input  wire        clk,
    input  wire        reset,            // active-high

    // Host-supplied epoch-microsecond timestamp
    input  wire [63:0] set_time,
    input  wire        set_time_valid,   // single-cycle pulse: latch set_time

    // Running 64-bit microsecond timestamp
    output reg  [63:0] timestamp
);

    // Clocks per microsecond. For 40 MHz this is 40.
    localparam integer CLKS_PER_US = CLK_FREQ / 1_000_000;

    // Width of the divider counter (handles CLKS_PER_US - 1)
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

    localparam integer DIV_W = (clog2(CLKS_PER_US) < 1) ? 1 : clog2(CLKS_PER_US);

    reg [DIV_W-1:0] div_cnt;
    reg             us_tick;

    // -------------------------------------------------------------------------
    // Microsecond tick: pulses for one clock every CLKS_PER_US clocks.
    // The divider also restarts on set_time_valid so the first tick after a
    // host load arrives exactly 1 us later.
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            div_cnt <= {DIV_W{1'b0}};
            us_tick <= 1'b0;
        end else if (set_time_valid) begin
            div_cnt <= {DIV_W{1'b0}};
            us_tick <= 1'b0;
        end else if (div_cnt == CLKS_PER_US - 1) begin
            div_cnt <= {DIV_W{1'b0}};
            us_tick <= 1'b1;
        end else begin
            div_cnt <= div_cnt + {{(DIV_W-1){1'b0}}, 1'b1};
            us_tick <= 1'b0;
        end
    end

    // -------------------------------------------------------------------------
    // 64-bit loadable microsecond counter.
    // Priority: load (set_time_valid) > increment (us_tick).
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            timestamp <= 64'd0;
        end else if (set_time_valid) begin
            timestamp <= set_time;
        end else if (us_tick) begin
            timestamp <= timestamp + 64'd1;
        end
    end

endmodule
///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: SWRI/VT
//
// File: bridge_fsm.v
// Description:
//   Accepts individual tag/x/y/magnitude fields along with a data-valid strobe.
//   On each valid pulse (and when not already busy), latches all fields,
//   concatenates them into a 144-bit packet, and asserts out_dv for exactly
//   one clock cycle.  Any in_dv pulse that arrives while a transmission is
//   in progress is silently dropped (fire-and-forget).
//
//   Output packet bit layout [143:0]:
//     [143:80]  tag        (64 bits)
//     [79:48]   x          (32 bits, signed)
//     [47:16]   y          (32 bits, signed)
//     [15:0]    magnitude  (16 bits, signed)
//
// Latency: 3 cycles per event
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: VT MDE S26-23
///////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module bridge_fsm #(
    parameter integer TAG_WIDTH      = 64,
    parameter integer POS_WIDTH      = 32,
    parameter integer MAG_WIDTH      = 16,
    parameter integer DATA_OUT_SIZE  = 144   // TAG + POS + POS + MAG = 64+32+32+16
)(
    input  wire                          clk,
    input  wire                          rst,

    // incoming data
    input  wire                          in_dv,
    input  wire [TAG_WIDTH-1:0]          in_tag,
    input  wire signed [POS_WIDTH-1:0]   in_x,
    input  wire signed [POS_WIDTH-1:0]   in_y,
    input  wire signed [MAG_WIDTH-1:0]   in_mag,

    // diagnostic strobes (registered; no effect on datapath)
    input  wire                          event_dropped,
    input  wire                          pos_rejected,

    // output to uart
    output wire [DATA_OUT_SIZE-1:0]      out,
    output reg                           out_dv,

    output reg  [15:0]                   cnt_dropped,
    output reg  [15:0]                   cnt_rejected
);

    // FSM state encoding
    localparam [1:0] S_IDLE = 2'd0,
                     S_SEND = 2'd1,
                     S_BUSY = 2'd2;

    reg [1:0] state;

    // Registered copies of input fields (latched on in_dv)
    reg [TAG_WIDTH-1:0] r_tag;
    reg [POS_WIDTH-1:0] r_x;
    reg [POS_WIDTH-1:0] r_y;
    reg [MAG_WIDTH-1:0] r_mag;

    // Internal saturating counter for in_dv pulses lost while in S_BUSY
    reg [15:0] cnt_dropped_busy;

    // Datapath: concatenate tag | x | y | mag
    assign out = {r_tag, r_x, r_y, r_mag};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state            <= S_IDLE;
            out_dv           <= 1'b0;
            r_tag            <= {TAG_WIDTH{1'b0}};
            r_x              <= {POS_WIDTH{1'b0}};
            r_y              <= {POS_WIDTH{1'b0}};
            r_mag            <= {MAG_WIDTH{1'b0}};
            cnt_dropped      <= 16'h0;
            cnt_rejected     <= 16'h0;
            cnt_dropped_busy <= 16'h0;
        end else begin
            // default outputs
            out_dv <= 1'b0;

            // diagnostic counters (saturating)
            if (event_dropped && !(&cnt_dropped))  cnt_dropped  <= cnt_dropped  + 16'd1;
            if (pos_rejected  && !(&cnt_rejected)) cnt_rejected <= cnt_rejected + 16'd1;

            case (state)

                // wait for a valid data strobe
                S_IDLE: begin
                    if (in_dv) begin
                        r_tag <= in_tag;
                        r_x   <= in_x;
                        r_y   <= in_y;
                        r_mag <= in_mag;
                        state <= S_SEND;
                    end
                end

                // assert out_dv for exactly one cycle; `out` is already
                // driven combinationally from r_*, so the UART wrapper
                // sees stable data on the same cycle as out_dv.
                S_SEND: begin
                    out_dv <= 1'b1;
                    state  <= S_BUSY;
                end

                // one extra cycle to avoid re-triggering before the UART
                // TX FSM has latched out_dv.
                S_BUSY: begin
                    if (in_dv) begin
                        if (!(&cnt_dropped_busy)) cnt_dropped_busy <= cnt_dropped_busy + 16'd1;
                    end
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;

            endcase
        end
    end

endmodule
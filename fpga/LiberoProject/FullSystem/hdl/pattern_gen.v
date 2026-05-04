///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: SwRI/VT
//
// File: pattern_gen.v
// File history:
//
//
// Description:
//
// Test pattern generator that outputs simulated events in the same format as the DSP pipeline.
// Used to verify connectivity between the FPGA board and downstream systems without requiring
// real detector signals.
//
// Generates a square spiral pattern of (x, y) positions starting from the origin and spiraling
// outward. Each point is emitted as a single-cycle pulse on out_valid with x, y, magnitude,
// and a sequential tag. Points are emitted at a configurable rate (one per DIV clock cycles).
//
// The spiral alternates step direction (R, U, L, D), growing the segment length after every
// two segments. A small +/-2 count dither is applied to each step to avoid perfectly regular
// spacing. The pattern stops when the next point would exceed BOUND_ABS in either axis.
//
// Pipeline stages used to meet timing:
//   Boundary check (runs continuously, 4 stages):
//     Stage B1: register step_amt from dither
//     Stage B2: add step to position, register next position
//     Stage B3: compute absolute value, register it
//     Stage B4: compare against bound, register hit_bound
//   Emit pulse (1 stage):
//     div_cnt comparison is registered into emit_pulse_r
//   Step-left next value (1 stage):
//     step_left decrement and segment-end mux are pre-computed and registered
//
// DIV must be >= 6 to allow all pipeline stages to settle.
//
// Output format (matches dsp_pipeline):
//   - out_x, out_y:  32-bit signed position in microns
//   - out_mag:        16-bit signed, rotates through 4 distinct values
//   - out_tag:        64-bit sequential tag (upper 32 = TAG_PREFIX, lower 32 = point count)
//   - out_valid:      single-cycle pulse when a new point is emitted
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: VT MDE S26-23
//
///////////////////////////////////////////////////////////////////////////////////////////////////

module pattern_generator #(
    parameter integer       POS_WIDTH  = 32,
    parameter integer       MAG_WIDTH  = 16,
    parameter integer       DIV        = 20000,         // emit one point every DIV clocks (min 6)
    parameter signed [31:0] POINT_STEP = 32'sd50,     // approximate spacing between points (um)
    parameter integer       LEN_INC    = 100,           // segment length growth per ring
    parameter [31:0]        BOUND_ABS  = 32'd51000,    // stop when |x| or |y| would exceed this
    parameter [31:0]        TAG_PREFIX = 32'hCAFE0000  // upper 32 bits of emitted tags
)(
    input  wire clk,
    input  wire rst,
    input  wire enable,

    // combined event output (matches dsp_pipeline)
    output reg                           out_valid,
    output reg  [63:0]                   out_tag,
    output reg  signed [POS_WIDTH-1:0]   out_x,
    output reg  signed [POS_WIDTH-1:0]   out_y,
    output reg  signed [MAG_WIDTH-1:0]   out_mag
);

    // clog2 for counter width
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

    localparam integer DIV_W = (clog2(DIV) < 1) ? 1 : clog2(DIV);
    localparam integer WIDE  = POS_WIDTH + 2;

    // enable rising-edge detect
    reg enable_d;
    wire enable_rise;

    always @(posedge clk or posedge rst) begin
        if (rst) enable_d <= 1'b0;
        else     enable_d <= enable;
    end

    assign enable_rise = enable & ~enable_d;

    // FSM states
    localparam [1:0] S_IDLE = 2'd0,
                     S_RUN  = 2'd1,
                     S_DONE = 2'd2;

    reg [1:0] state;

    // emit divider with registered output
    reg  [DIV_W-1:0] div_cnt;
    reg  emit_pulse_r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            div_cnt     <= {DIV_W{1'b0}};
            emit_pulse_r <= 1'b0;
        end else if (!enable || enable_rise || (state != S_RUN)) begin
            div_cnt     <= {DIV_W{1'b0}};
            emit_pulse_r <= 1'b0;
        end else if (emit_pulse_r) begin
            // one cycle after emit, reset counter
            div_cnt     <= {DIV_W{1'b0}};
            emit_pulse_r <= 1'b0;
        end else if (div_cnt == (DIV - 2)) begin
            // fire one cycle early so emit_pulse_r is registered
            div_cnt     <= div_cnt + {{(DIV_W-1){1'b0}}, 1'b1};
            emit_pulse_r <= 1'b1;
        end else begin
            div_cnt     <= div_cnt + {{(DIV_W-1){1'b0}}, 1'b1};
            emit_pulse_r <= 1'b0;
        end
    end

    // spiral internal state
    reg signed [POS_WIDTH-1:0] x_state, y_state;
    reg [1:0]  dir;          // 0=R, 1=U, 2=L, 3=D
    reg [15:0] step_len;     // current segment length in points
    reg [15:0] step_left;    // points remaining in current segment
    reg        seg_in_pair;  // toggles each segment; grow after two
    reg        step_dither;  // alternates +/-2 around POINT_STEP

    // pre-computed step_left next value (registered to break timing)
    reg [15:0] step_left_next;
    reg [1:0]  dir_next;
    reg        seg_in_pair_next;
    reg [15:0] step_len_next;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            step_left_next   <= 16'd1;
            dir_next         <= 2'd1;
            seg_in_pair_next <= 1'b1;
            step_len_next    <= 16'd1;
        end else begin
            if (!enable || enable_rise) begin
                step_left_next   <= 16'd1;
                dir_next         <= 2'd1;
                seg_in_pair_next <= 1'b1;
                step_len_next    <= 16'd1;
            end else if (step_left == 16'd1) begin
                // at segment boundary: precompute next segment values
                dir_next <= dir + 2'd1;
                if (seg_in_pair) begin
                    step_len_next    <= step_len + LEN_INC[15:0];
                    step_left_next   <= step_len + LEN_INC[15:0];
                    seg_in_pair_next <= 1'b0;
                end else begin
                    step_len_next    <= step_len;
                    step_left_next   <= step_len;
                    seg_in_pair_next <= 1'b1;
                end
            end else begin
                // mid-segment: precompute decremented value
                step_left_next   <= step_left - 16'd1;
                dir_next         <= dir;
                seg_in_pair_next <= seg_in_pair;
                step_len_next    <= step_len;
            end
        end
    end

    // --- boundary check pipeline stage 1: register step amount from dither ---
    reg signed [POS_WIDTH-1:0] step_amt_r;

    always @(posedge clk or posedge rst) begin
        if (rst)
            step_amt_r <= {POS_WIDTH{1'b0}};
        else
            step_amt_r <= step_dither
                ? (POINT_STEP[POS_WIDTH-1:0] - {{(POS_WIDTH-2){1'b0}}, 2'sd2})
                : (POINT_STEP[POS_WIDTH-1:0] + {{(POS_WIDTH-2){1'b0}}, 2'sd2});
    end

    // --- boundary check pipeline stage 2: add step to position ---
    wire signed [WIDE-1:0] step_ext = {{2{step_amt_r[POS_WIDTH-1]}}, step_amt_r};
    wire signed [WIDE-1:0] x_ext   = {{2{x_state[POS_WIDTH-1]}}, x_state};
    wire signed [WIDE-1:0] y_ext   = {{2{y_state[POS_WIDTH-1]}}, y_state};

    reg signed [POS_WIDTH-1:0] x_next_reg, y_next_reg;

    always @(posedge clk) begin
        if (rst) begin
            x_next_reg <= {POS_WIDTH{1'b0}};
            y_next_reg <= {POS_WIDTH{1'b0}};
        end else begin
            x_next_reg <= x_state;
            y_next_reg <= y_state;
            case (dir)
                2'd0: x_next_reg <= (x_ext + step_ext);
                2'd1: y_next_reg <= (y_ext + step_ext);
                2'd2: x_next_reg <= (x_ext - step_ext);
                2'd3: y_next_reg <= (y_ext - step_ext);
                default: begin end
            endcase
        end
    end

    // --- boundary check pipeline stage 3: absolute value ---
    wire signed [WIDE-1:0] x_next_ext = {{2{x_next_reg[POS_WIDTH-1]}}, x_next_reg};
    wire signed [WIDE-1:0] y_next_ext = {{2{y_next_reg[POS_WIDTH-1]}}, y_next_reg};

    reg [WIDE-1:0] x_abs_r, y_abs_r;

    always @(posedge clk) begin
        if (rst) begin
            x_abs_r <= {WIDE{1'b0}};
            y_abs_r <= {WIDE{1'b0}};
        end else begin
            x_abs_r <= x_next_ext[WIDE-1] ? (-x_next_ext) : x_next_ext;
            y_abs_r <= y_next_ext[WIDE-1] ? (-y_next_ext) : y_next_ext;
        end
    end

    // --- boundary check pipeline stage 4: compare against bound ---
    wire [WIDE-1:0] bound_ext = {{(WIDE-POS_WIDTH){1'b0}}, BOUND_ABS[POS_WIDTH-1:0]};

    reg hit_bound_reg;

    always @(posedge clk or posedge rst) begin
        if (rst)
            hit_bound_reg <= 1'b0;
        else
            hit_bound_reg <= (x_abs_r >= bound_ext) || (y_abs_r >= bound_ext);
    end

    // sequential tag counter
    reg [31:0] point_count;

    // magnitude rotation: cycles through 4 distinct values
    reg [1:0] mag_idx;

    wire signed [MAG_WIDTH-1:0] mag_table [0:3];
    assign mag_table[0] = 16'sd1000;
    assign mag_table[1] = 16'sd2000;
    assign mag_table[2] = 16'sd3000;
    assign mag_table[3] = 16'sd4000;

    // main sequential logic ? reads only registered signals
    always @(posedge clk) begin
        if (rst) begin
            state       <= S_IDLE;
            out_valid   <= 1'b0;
            out_tag     <= 64'd0;
            out_x       <= {POS_WIDTH{1'b0}};
            out_y       <= {POS_WIDTH{1'b0}};
            out_mag     <= {MAG_WIDTH{1'b0}};
            x_state     <= {POS_WIDTH{1'b0}};
            y_state     <= {POS_WIDTH{1'b0}};
            dir         <= 2'd0;
            step_len    <= 16'd1;
            step_left   <= 16'd1;
            seg_in_pair <= 1'b0;
            step_dither <= 1'b0;
            point_count <= 32'd0;
            mag_idx     <= 2'd0;
        end else begin
            out_valid <= 1'b0;

            if (!enable) begin
                state       <= S_IDLE;
                x_state     <= {POS_WIDTH{1'b0}};
                y_state     <= {POS_WIDTH{1'b0}};
                dir         <= 2'd0;
                step_len    <= 16'd1;
                step_left   <= 16'd1;
                seg_in_pair <= 1'b0;
                step_dither <= 1'b0;
                point_count <= 32'd0;
                mag_idx     <= 2'd0;

            end else if (enable_rise) begin
                state       <= S_RUN;
                x_state     <= {POS_WIDTH{1'b0}};
                y_state     <= {POS_WIDTH{1'b0}};
                dir         <= 2'd0;
                step_len    <= 16'd1;
                step_left   <= 16'd1;
                seg_in_pair <= 1'b0;
                step_dither <= 1'b0;
                point_count <= 32'd0;
                mag_idx     <= 2'd0;

            end else begin
                case (state)
                    S_IDLE: begin
                        // idle until enabled
                    end

                    S_RUN: begin
                        if (emit_pulse_r) begin
                            if (hit_bound_reg) begin
                                state       <= S_DONE;
                                x_state     <= {POS_WIDTH{1'b0}};
                                y_state     <= {POS_WIDTH{1'b0}};
                                dir         <= 2'd0;
                                step_len    <= 16'd1;
                                step_left   <= 16'd1;
                                seg_in_pair <= 1'b0;
                                step_dither <= 1'b0;
                                point_count <= 32'd0;
                                mag_idx     <= 2'd0;
                            end else begin
                                // advance position from registered values
                                x_state <= x_next_reg;
                                y_state <= y_next_reg;

                                // emit event
                                out_valid <= 1'b1;
                                out_x     <= x_next_reg;
                                out_y     <= y_next_reg;
                                out_tag   <= {TAG_PREFIX, point_count + 32'd1};
                                out_mag   <= mag_table[mag_idx];

                                // advance counters
                                point_count <= point_count + 32'd1;
                                mag_idx     <= mag_idx + 2'd1;
                                step_dither <= ~step_dither;

                                // commit pre-computed segment state
                                step_left   <= step_left_next;
                                dir         <= dir_next;
                                seg_in_pair <= seg_in_pair_next;
                                step_len    <= step_len_next;
                            end
                        end
                    end

                    S_DONE: begin
                        // wait until enable goes low, then enable_rise restarts
                    end

                    default: state <= S_IDLE;
                endcase
            end
        end
    end

endmodule
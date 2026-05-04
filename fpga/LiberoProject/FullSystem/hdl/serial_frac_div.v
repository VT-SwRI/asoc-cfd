///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: SwRI/VT
//
// File: serial_frac_div.v
// File history:
//
//
// Description:
//
// Unsigned fractional serial divider. Computes Q = num / den as a FRAC_BITS-bit fixed-point
// fraction in [0, 1). Each iteration shifts remainder left, compares with denominator, 
// and subtracts if greater.
//
// Latency: FRAC_BITS clock cycles after start.
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: VT MDE S26-23
//
///////////////////////////////////////////////////////////////////////////////////////////////////

module serial_frac_div #(
    parameter integer W         = 17,
    parameter integer FRAC_BITS = 10
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 start,
    input  wire [W-1:0]         num,
    input  wire [W-1:0]         den,
    output reg                  busy,
    output reg                  done,
    output reg  [FRAC_BITS-1:0] q
);

    reg [W-1:0] rem;                          // running remainder
    reg [W-1:0] denom;                        // latched denominator  
    reg [$clog2(FRAC_BITS+1)-1:0] bit_cnt;    // iterations remaining
    reg [FRAC_BITS-2:0] q_r;                  // quotient shift register (all bits except last)

    wire [W:0]   rem_shifted = {rem, 1'b0};                    // remainder << 1
    wire         cmp         = (rem_shifted >= {1'b0, denom}); // high when subtraction should occur
    wire [W-1:0] rem_sub     = rem_shifted[W-1:0] - denom;     // remainder after subtraction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset
            busy    <= 1'b0;
            done    <= 1'b0;
            q       <= {FRAC_BITS{1'b0}};
            q_r     <= {(FRAC_BITS-1){1'b0}};
            rem     <= {W{1'b0}};
            denom   <= {W{1'b0}};
            bit_cnt <= {($clog2(FRAC_BITS+1)){1'b0}};
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                // start new division
                busy    <= 1'b1;
                q_r     <= {(FRAC_BITS-1){1'b0}};
                rem     <= num;
                denom   <= den;
                bit_cnt <= FRAC_BITS[$clog2(FRAC_BITS+1)-1:0];
            end else if (busy) begin
                // shift and subtract
                if (cmp) begin
                    rem <= rem_sub;
                    q_r <= {q_r[FRAC_BITS-3:0], 1'b1};
                end else begin
                    rem <= rem_shifted[W-1:0];
                    q_r <= {q_r[FRAC_BITS-3:0], 1'b0};
                end

                bit_cnt <= bit_cnt - 1'b1;

                // on the final iteration, capture completed quotient
                // (q_r hasn't updated yet, so build q from pre-update q_r + current bit)
                if (bit_cnt == 1) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    q    <= {q_r, cmp};
                end
            end
        end
    end

endmodule
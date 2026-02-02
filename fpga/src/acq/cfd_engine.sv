// cfd_engine.sv - Simple digital constant-fraction discriminator.
// Implements y[n] = x[n] - frac * x[n-delay]
// where frac is Q1.15 fixed-point (0..1.999) and delay is integer samples.
// Detect rising zero-crossing of y, interpolate a fractional sample timestamp.
//
// This is a simplified, synthesizable baseline for FPGA-side CFD.
// You will likely tune fixed-point widths and filtering for your ASOC noise/bandwidth.
module cfd_engine #(
  parameter int SAMPLE_W = 14,
  parameter int DELAY    = 8
)(
  input  logic                     clk,
  input  logic                     rst_n,

  // config
  input  logic [15:0]              frac_q1_15,   // fraction in Q1.15
  input  logic signed [SAMPLE_W-1:0] threshold,  // simple magnitude threshold gate

  // sample stream
  input  logic                     s_valid,
  input  logic signed [SAMPLE_W-1:0] s_data,
  output logic                     s_ready,

  // output event (one per crossing)
  output logic                     evt_valid,
  output logic [31:0]              evt_time_q16, // sample_index<<16 | frac
  output logic signed [SAMPLE_W-1:0] evt_amp,
  input  logic                     evt_ready
);

  assign s_ready = 1'b1; // always accept (adjust if you add backpressure)

  // Delay line for x[n-delay]
  logic signed [SAMPLE_W-1:0] dline [DELAY];
  logic [$clog2(DELAY+1)-1:0] di;

  logic [31:0] sample_index;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i=0;i<DELAY;i++) dline[i] <= '0;
      sample_index <= 32'd0;
    end else if (s_valid) begin
      dline[0] <= s_data;
      for (int j=1;j<DELAY;j++) dline[j] <= dline[j-1];
      sample_index <= sample_index + 1'd1;
    end
  end

  // Compute y[n] with fixed-point multiply: frac_q1_15 * x_delayed
  logic signed [SAMPLE_W-1:0] x_d;
  logic signed [SAMPLE_W-1:0] x_n;
  logic signed [SAMPLE_W+15:0] mult;
  logic signed [SAMPLE_W+1:0]  frac_xd;
  logic signed [SAMPLE_W+2:0]  y_n;

  always_comb begin
    x_n = s_data;
    x_d = dline[DELAY-1];
    mult = $signed({1'b0, frac_q1_15}) * $signed(x_d);
    // mult is (SAMPLE_W+16) bits; shift down by 15
    frac_xd = mult >>> 15;
    y_n = $signed(x_n) - $signed(frac_xd);
  end

  // Zero-cross detect: rising through 0 (y_prev < 0 && y_curr >= 0)
  logic signed [SAMPLE_W+2:0] y_prev;
  logic armed;
  logic pending;

  // fractional interpolation: frac = (-y_prev)/(y_curr - y_prev)
  // output Q16 fraction

  function automatic [31:0] interp_frac_q16(input logic signed [SAMPLE_W+2:0] a,
                                            input logic signed [SAMPLE_W+2:0] b);
    // a = y_prev (negative), b = y_curr (>=0), denom = b - a > 0
    logic signed [SAMPLE_W+3:0] denom;
    logic signed [SAMPLE_W+3:0] num;
    logic [47:0] q;
    begin
      denom = b - a;
      num   = -a;
      if (denom == 0) interp_frac_q16 = 32'd0;
      else begin
        // (num<<16)/denom
        q = ({{16{1'b0}}, num} << 16) / denom;
        interp_frac_q16 = q[31:0];
      end
    end
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      y_prev   <= '0;
      armed    <= 1'b0;
      pending  <= 1'b0;
      evt_valid<= 1'b0;
      evt_time_q16 <= '0;
      evt_amp  <= '0;
    end else begin
      // default: drop evt_valid when accepted
      if (evt_valid && evt_ready) evt_valid <= 1'b0;

      if (s_valid) begin
        // Simple arming gate based on threshold on x[n]
        if (!armed && (x_n > threshold)) armed <= 1'b1;

        if (armed) begin
          if ((y_prev < 0) && (y_n >= 0)) begin
            // generate event if output not busy
            if (!evt_valid) begin
              evt_time_q16 <= ((sample_index - 1) << 16) | (interp_frac_q16(y_prev, y_n)[15:0]);
              evt_amp <= x_n;
              evt_valid <= 1'b1;
              armed <= 1'b0; // one-shot, re-arm after crossing
            end
          end
        end

        y_prev <= y_n;
      end
    end
  end

endmodule

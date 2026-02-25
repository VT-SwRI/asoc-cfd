`timescale 1ns/1ps
`default_nettype none

module tb_position_calculator;

  // ----------------------------
  // Parameters (match DUT defaults)
  // ----------------------------
  localparam int MULT_LATENCY = 3;                 // DUT parameter
  localparam int TOTAL_LAT    = MULT_LATENCY + 2;  // valid_in -> valid_out latency

  localparam int EDGE_CASE_TRIALS = 20000;
  localparam int TRIALS           = 200000;

  // ----------------------------
  // Clock / Reset
  // ----------------------------
  logic clk;
  logic rst_n;

  initial begin
    clk = 1'b0;
    forever #5ns clk = ~clk; // 100 MHz
  end

  initial begin
    rst_n = 1'b1;
    #2ns;
    rst_n = 1'b0;
    #20ns;
    rst_n = 1'b1;
  end

  // ----------------------------
  // DUT I/O
  // ----------------------------
  logic                valid_in;
  logic [15:0]         tpx1_in, tpx2_in, tpy1_in, tpy2_in;
  logic signed [15:0]  posconst_x_in, posconst_y_in;
  logic [51:0]         timestamp_in;

  logic signed [31:0]  position_x_out, position_y_out;
  logic [51:0]         timestamp_out;
  logic                valid_out;
  logic                overflow_out;

  Position_Calculator #(.MULT_LATENCY(MULT_LATENCY)) dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .valid_in       (valid_in),
    .tpx1_in        (tpx1_in),
    .tpx2_in        (tpx2_in),
    .tpy1_in        (tpy1_in),
    .tpy2_in        (tpy2_in),
    .posconst_x_in  (posconst_x_in),
    .posconst_y_in  (posconst_y_in),
    .timestamp_in   (timestamp_in),
    .position_x_out (position_x_out),
    .position_y_out (position_y_out),
    .timestamp_out  (timestamp_out),
    .valid_out      (valid_out),
    .overflow_out   (overflow_out)
  );

  // ----------------------------
  // Scoreboard (pipeline model)
  // ----------------------------
  typedef struct packed {
    logic                v;
    logic [51:0]         ts;
    logic signed [31:0]  px;
    logic signed [31:0]  py;
    logic                ovf;
  } exp_t;

  exp_t exp_pipe [0:TOTAL_LAT]; // exp_pipe[TOTAL_LAT] aligns with DUT output cycle

  // Helper function: compute one expected output from current *inputs*
  function automatic exp_t compute_expected(
    input logic               v_in,
    input logic [51:0]        ts_in,
    input logic [15:0]        ax1, ax2, ay1, ay2,
    input logic signed [15:0] pcx, pcy
  );
    exp_t e;
    logic signed [16:0] dx, dy;
    logic signed [32:0] px33, py33;
    logic               ovx, ovy;
    begin
      dx   = $signed({1'b0, ax1}) - $signed({1'b0, ax2});
      dy   = $signed({1'b0, ay1}) - $signed({1'b0, ay2});
      px33 = dx * pcx;
      py33 = dy * pcy;

      ovx = (px33[32] ^ px33[31]);
      ovy = (py33[32] ^ py33[31]);

      e.v   = v_in;
      e.ts  = ts_in;
      e.px  = px33[31:0];
      e.py  = py33[31:0];
      e.ovf = v_in & (ovx | ovy);
      return e;
    end
  endfunction

  // Drive defaults
  initial begin
    valid_in       = 1'b0;
    tpx1_in        = 16'd0;
    tpx2_in        = 16'd0;
    tpy1_in        = 16'd0;
    tpy2_in        = 16'd0;
    posconst_x_in  = 16'sd0;
    posconst_y_in  = 16'sd0;
    timestamp_in   = 52'd0;
  end

  // Pipeline update + checking
  int test_count = 0;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i <= TOTAL_LAT; i++) exp_pipe[i] <= '0;
    end else begin
      // shift
      for (int i = TOTAL_LAT; i > 0; i--) exp_pipe[i] <= exp_pipe[i-1];

      // IMPORTANT: DUT captures valid_in/timestamps/etc into v0/ts0 at this edge,
      // then v1 one cycle later, then MULT_LATENCY regs, then output reg.
      // Net effect is TOTAL_LAT = MULT_LATENCY+2.
      exp_pipe[0] <= compute_expected(valid_in, timestamp_in,
                                      tpx1_in, tpx2_in, tpy1_in, tpy2_in,
                                      posconst_x_in, posconst_y_in);

      // Check outputs every cycle (only enforce when expected valid is 1)
      if (exp_pipe[TOTAL_LAT].v) begin
        test_count++;

        assert(valid_out === 1'b1)
          else $fatal(1, "valid_out mismatch: expected 1, got %0b", valid_out);

        assert(timestamp_out === exp_pipe[TOTAL_LAT].ts)
          else $fatal(1, "timestamp_out mismatch exp=%0h got=%0h",
                      exp_pipe[TOTAL_LAT].ts, timestamp_out);

        assert(position_x_out === exp_pipe[TOTAL_LAT].px)
          else $fatal(1, "position_x_out mismatch exp=%0d got=%0d",
                      exp_pipe[TOTAL_LAT].px, position_x_out);

        assert(position_y_out === exp_pipe[TOTAL_LAT].py)
          else $fatal(1, "position_y_out mismatch exp=%0d got=%0d",
                      exp_pipe[TOTAL_LAT].py, position_y_out);

        assert(overflow_out === exp_pipe[TOTAL_LAT].ovf)
          else $fatal(1, "overflow_out mismatch exp=%0b got=%0b",
                      exp_pipe[TOTAL_LAT].ovf, overflow_out);
      end else begin
        // Optional sanity: valid_out should be 0 when expected valid is 0
        assert(valid_out === 1'b0)
          else $fatal(1, "valid_out should be 0 when no valid expected (got %0b)", valid_out);
      end
    end
  end

  // ----------------------------
  // Stimulus helpers
  // ----------------------------
  task automatic drive_one(
    input logic               v,
    input logic [51:0]        ts,
    input logic [15:0]        ax1, ax2, ay1, ay2,
    input logic signed [15:0] pcx, pcy
  );
    begin
      valid_in       = v;
      timestamp_in   = ts;
      tpx1_in        = ax1;
      tpx2_in        = ax2;
      tpy1_in        = ay1;
      tpy2_in        = ay2;
      posconst_x_in  = pcx;
      posconst_y_in  = pcy;
      @(posedge clk);
    end
  endtask

  // ----------------------------
  // Test sequence
  // ----------------------------
  initial begin
    // wait reset release
    @(posedge rst_n);
    repeat (5) @(posedge clk);

    // ---- Directed: invalid cycles (should not count/check outputs)
    $display("[Position TB] Directed: invalid cycles");
    for (int i = 0; i < 100; i++) begin
      drive_one(1'b0, $urandom(), $urandom(), $urandom(), $urandom(), $urandom(),
                $signed($urandom()), $signed($urandom()));
    end

    // ---- Directed: diff=0 => output 0 regardless of posconst
    $display("[Position TB] Directed: diff=0 -> output 0");
    for (int i = 0; i < EDGE_CASE_TRIALS; i++) begin
      logic [15:0] t = $urandom();
      drive_one(1'b1, $urandom(), t, t, t, t,
                $signed($urandom()), $signed($urandom()));
    end

    // ---- Directed: overflow-forcing corner
    // diff_x = -65535 (tpx1=0, tpx2=65535), posconst_x = -32768 => product = +2^31 (OVERFLOW)
    $display("[Position TB] Directed: overflow corner");
    drive_one(1'b1, 52'h12345, 16'd0, 16'hFFFF, 16'd10, 16'd10,
              16'sh8000, 16'sd1); // overflow in X only

    // ---- Directed: min negative exactly fits (no overflow)
    // diff_x = +65535, posconst_x = -32768 => product = -2^31 (fits signed32)
    $display("[Position TB] Directed: -2^31 corner (no overflow expected)");
    drive_one(1'b1, 52'h6789A, 16'hFFFF, 16'd0, 16'd10, 16'd10,
              16'sh8000, 16'sd1);

    // ---- Random tests (mix of valid/invalid)
    $display("[Position TB] Random tests");
    for (int i = 0; i < TRIALS; i++) begin
      logic v = ($urandom_range(0,9) != 0); // ~90% valid
      drive_one(v,
                {$urandom(), $urandom_range(0,(1<<20)-1)}, // some timestamp entropy
                $urandom(), $urandom(), $urandom(), $urandom(),
                $signed($urandom()), $signed($urandom()));
    end

    // Drain the pipeline
    $display("[Position TB] Draining pipeline...");
    for (int i = 0; i < TOTAL_LAT + 5; i++) begin
      drive_one(1'b0, 52'd0, 16'd0, 16'd0, 16'd0, 16'd0, 16'sd0, 16'sd0);
    end

    $display("[Position TB] PASS. Checked valid outputs: %0d", test_count);
    $stop;
  end

endmodule

`default_nettype wire


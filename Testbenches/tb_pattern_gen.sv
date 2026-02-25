`timescale 1ns/1ps

module tb_pattern_gen;

  // --------------------------------------------------------------------------
  // Fast simulation parameters (override DUT defaults)
  // --------------------------------------------------------------------------
  localparam int      DIV_TB       = 4;          // emit every 4 clocks
  localparam shortint POINT_STEP_TB = 16'sd10;    // smaller step for quick bound hit
  localparam int      LEN_INC_TB    = 3;          // grows faster
  localparam shortint BOUND_ABS_TB  = 16'd60;     // stop early

  // --------------------------------------------------------------------------
  // DUT I/O
  // --------------------------------------------------------------------------
  logic clk;
  logic rst_n;
  logic enable;

  wire signed [15:0] x;
  wire signed [15:0] y;
  wire               valid;

  wire [31:0] point_count_out;
  wire [19:0] rot20_out;

  pattern_gen #(
    .DIV(DIV_TB),
    .POINT_STEP(POINT_STEP_TB),
    .LEN_INC(LEN_INC_TB),
    .BOUND_ABS(BOUND_ABS_TB)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .enable(enable),
    .x(x),
    .y(y),
    .valid(valid),
    .point_count_out(point_count_out),
    .rot20_out(rot20_out)
  );

  // --------------------------------------------------------------------------
  // Clock gen
  // --------------------------------------------------------------------------
  initial clk = 1'b0;
  always #5 clk = ~clk; // 100 MHz

  // --------------------------------------------------------------------------
  // Reference model state (mirrors RTL intent)
  // --------------------------------------------------------------------------
  typedef enum logic [1:0] {S_IDLE=2'd0, S_RUN=2'd1, S_DONE=2'd2} st_t;
  st_t st_ref;

  // divider ref
  int unsigned div_cnt_ref;

  // pattern state ref
  logic signed [15:0] x_state_ref, y_state_ref;
  logic [1:0]         dir_ref;        // 0=R,1=U,2=L,3=D
  logic [15:0]        step_len_ref;
  logic [15:0]        step_left_ref;
  logic               seg_in_pair_ref;
  logic               step_dither_ref;

  logic [31:0] point_count_ref;
  logic [19:0] rot20_ref;

  // enable edge detect ref
  logic enable_d_ref;
  logic enable_rise_ref;

  // helpers
  function automatic int unsigned abs_int18(input int signed v);
    abs_int18 = (v < 0) ? int'(-v) : int'(v);
  endfunction

  function automatic logic is_onehot20(input logic [19:0] v);
    return (v != 20'd0) && ((v & (v - 20'd1)) == 20'd0);
  endfunction

  // Compute expected "emit_pulse" like the RTL:
  // emit_pulse = enable && st==RUN && div_cnt==(DIV-1)
  function automatic logic emit_pulse_ref();
    return (enable && (st_ref == S_RUN) && (div_cnt_ref == (DIV_TB-1)));
  endfunction

  // --------------------------------------------------------------------------
  // Reset / stimulus
  // --------------------------------------------------------------------------
  task automatic do_reset();
    rst_n  = 1'b0;
    enable = 1'b0;
    repeat (5) @(posedge clk);
    rst_n  = 1'b1;
    repeat (2) @(posedge clk);
  endtask

  task automatic start_enable();
    enable = 1'b0;
    repeat (2) @(posedge clk);
    enable = 1'b1;
  endtask

  task automatic stop_enable();
    enable = 1'b0;
  endtask

  // --------------------------------------------------------------------------
  // Reference model update (cycle-accurate enough for checking DUT outputs)
  // --------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      enable_d_ref     <= 1'b0;
      st_ref           <= S_IDLE;
      div_cnt_ref      <= 0;

      x_state_ref      <= 16'sd0;
      y_state_ref      <= 16'sd0;
      dir_ref          <= 2'd0;
      step_len_ref     <= 16'd1;
      step_left_ref    <= 16'd1;
      seg_in_pair_ref  <= 1'b0;
      step_dither_ref  <= 1'b0;

      point_count_ref  <= 32'd0;
      rot20_ref        <= 20'd1;

    end else begin
      enable_d_ref    <= enable;
      enable_rise_ref <= (enable && !enable_d_ref);

      // divider behavior mirrors your RTL structure
      if (!enable) begin
        div_cnt_ref <= 0;
      end else if (enable && !enable_d_ref) begin // enable rising
        div_cnt_ref <= 0;
      end else if (st_ref != S_RUN) begin
        div_cnt_ref <= 0;
      end else if (emit_pulse_ref()) begin
        div_cnt_ref <= 0;
      end else begin
        div_cnt_ref <= div_cnt_ref + 1;
      end

      // FSM / pattern behavior
      if (!enable) begin
        st_ref          <= S_IDLE;

        x_state_ref     <= 16'sd0;
        y_state_ref     <= 16'sd0;
        dir_ref         <= 2'd0;
        step_len_ref    <= 16'd1;
        step_left_ref   <= 16'd1;
        seg_in_pair_ref <= 1'b0;
        step_dither_ref <= 1'b0;

        point_count_ref <= 32'd0;
        rot20_ref       <= 20'd1;

      end else if (enable && !enable_d_ref) begin
        // enable rising: start run and reset state
        st_ref          <= S_RUN;

        x_state_ref     <= 16'sd0;
        y_state_ref     <= 16'sd0;
        dir_ref         <= 2'd0;
        step_len_ref    <= 16'd1;
        step_left_ref   <= 16'd1;
        seg_in_pair_ref <= 1'b0;
        step_dither_ref <= 1'b0;

        point_count_ref <= 32'd0;
        rot20_ref       <= 20'd1;

      end else begin
        case (st_ref)
          S_IDLE: begin
            // nothing
          end

          S_RUN: begin
            if (emit_pulse_ref()) begin
              // compute next step_amt with dither
              logic signed [15:0] step_amt;
              int signed x_next_w, y_next_w;
              int unsigned x_abs_next, y_abs_next;
              logic hit_bound;

              step_amt = (step_dither_ref) ? (POINT_STEP_TB - 16'sd2)
                                           : (POINT_STEP_TB + 16'sd2);

              x_next_w = x_state_ref;
              y_next_w = y_state_ref;
              unique case (dir_ref)
                2'd0: x_next_w = x_state_ref + step_amt; // R
                2'd1: y_next_w = y_state_ref + step_amt; // U
                2'd2: x_next_w = x_state_ref - step_amt; // L
                2'd3: y_next_w = y_state_ref - step_amt; // D
              endcase

              x_abs_next = abs_int18(x_next_w);
              y_abs_next = abs_int18(y_next_w);
              hit_bound  = (x_abs_next >= BOUND_ABS_TB) || (y_abs_next >= BOUND_ABS_TB);

              if (hit_bound) begin
                // matches DUT: go done and reset internal state
                st_ref          <= S_DONE;

                x_state_ref     <= 16'sd0;
                y_state_ref     <= 16'sd0;
                dir_ref         <= 2'd0;
                step_len_ref    <= 16'd1;
                step_left_ref   <= 16'd1;
                seg_in_pair_ref <= 1'b0;
                step_dither_ref <= 1'b0;

                point_count_ref <= 32'd0;
                rot20_ref       <= 20'd1;

              end else begin
                // commit position
                x_state_ref <= logic'(x_next_w[15:0]);
                y_state_ref <= logic'(y_next_w[15:0]);

                // metadata
                point_count_ref <= point_count_ref + 32'd1;
                rot20_ref       <= {rot20_ref[18:0], rot20_ref[19]};

                // dither toggles every emitted point
                step_dither_ref <= ~step_dither_ref;

                // segment bookkeeping
                if (step_left_ref == 16'd1) begin
                  dir_ref <= dir_ref + 2'd1;

                  if (seg_in_pair_ref) begin
                    step_len_ref    <= step_len_ref + LEN_INC_TB[15:0];
                    step_left_ref   <= step_len_ref + LEN_INC_TB[15:0];
                    seg_in_pair_ref <= 1'b0;
                  end else begin
                    step_left_ref   <= step_len_ref;
                    seg_in_pair_ref <= 1'b1;
                  end
                end else begin
                  step_left_ref <= step_left_ref - 16'd1;
                end
              end
            end
          end

          S_DONE: begin
            // stay done until enable drops (handled above)
          end

          default: st_ref <= S_IDLE;
        endcase
      end
    end
  end

  // --------------------------------------------------------------------------
  // Assertions / checks against DUT
  // --------------------------------------------------------------------------
  // 1) When valid=0, DUT forces outputs to zero (per your RTL "Default" behavior)
  property p_outputs_zero_when_invalid;
    @(posedge clk) disable iff (!rst_n)
      (!valid) |-> (x == 16'sd0 && y == 16'sd0 &&
                    point_count_out == 32'd0 && rot20_out == 20'd0);
  endproperty
  assert property (p_outputs_zero_when_invalid)
    else $fatal(1, "DUT outputs not forced to zero when valid=0");

  // 2) rot20_out should be onehot when valid=1 (your design rotates a one-hot)
  property p_rot20_onehot_on_valid;
    @(posedge clk) disable iff (!rst_n)
      valid |-> is_onehot20(rot20_out);
  endproperty
  assert property (p_rot20_onehot_on_valid)
    else $fatal(1, "rot20_out not onehot on valid");

  // 3) On each emit_pulse (i.e., when ref model expects a point), compare DUT
  always_ff @(posedge clk) begin
    if (rst_n) begin
      // Determine what the DUT should be doing based on ref state BEFORE update?
      // We check against the *expected output behavior* for the current cycle:
      // - If emit_pulse_ref() and st_ref==RUN and next point doesn't hit bound => valid=1 and match
      // - If emit_pulse_ref() and next hits bound => valid=0
      if (emit_pulse_ref() && (st_ref == S_RUN)) begin
        logic signed [15:0] step_amt;
        int signed x_next_w, y_next_w;
        int unsigned x_abs_next, y_abs_next;
        logic hit_bound;

        step_amt = (step_dither_ref) ? (POINT_STEP_TB - 16'sd2)
                                     : (POINT_STEP_TB + 16'sd2);

        x_next_w = x_state_ref;
        y_next_w = y_state_ref;
        unique case (dir_ref)
          2'd0: x_next_w = x_state_ref + step_amt;
          2'd1: y_next_w = y_state_ref + step_amt;
          2'd2: x_next_w = x_state_ref - step_amt;
          2'd3: y_next_w = y_state_ref - step_amt;
        endcase

        x_abs_next = abs_int18(x_next_w);
        y_abs_next = abs_int18(y_next_w);
        hit_bound  = (x_abs_next >= BOUND_ABS_TB) || (y_abs_next >= BOUND_ABS_TB);

        if (hit_bound) begin
          // Expect DUT NOT to assert valid on the boundary-hit emission
          assert (!valid)
            else $fatal(1, "Expected valid=0 on bound hit, got valid=1");
        end else begin
          // Expect a valid pulse and matching outputs/metadata
          assert (valid)
            else $fatal(1, "Expected valid=1 on emit, got valid=0");

          assert (x == x_next_w[15:0] && y == y_next_w[15:0])
            else $fatal(1, "XY mismatch. DUT=(%0d,%0d) EXP=(%0d,%0d)",
                        x, y, x_next_w[15:0], y_next_w[15:0]);

          assert (point_count_out == (point_count_ref + 32'd1))
            else $fatal(1, "point_count_out mismatch. DUT=%0d EXP=%0d",
                        point_count_out, point_count_ref + 32'd1);

          assert (rot20_out == rot20_ref)
            else $fatal(1, "rot20_out mismatch. DUT=%h EXP=%h",
                        rot20_out, rot20_ref);
        end
      end

      // 4) In DONE state, DUT should remain quiet (valid=0) while enable stays high.
      if ((st_ref == S_DONE) && enable) begin
        assert (!valid)
          else $fatal(1, "Expected valid=0 in DONE while enable=1");
      end
    end
  end

  // --------------------------------------------------------------------------
  // Test sequence
  // --------------------------------------------------------------------------
  initial begin
    // init
    rst_n  = 1'b0;
    enable = 1'b0;

    do_reset();

    // Run 1: start pattern, let it hit bound & stop
    start_enable();
    repeat (400) @(posedge clk); // plenty for early bound

    // Ensure it is quiet at this point (either still running or done; quiet is acceptable)
    // The DONE assertion above will trip if it incorrectly asserts valid in DONE.

    // Drop enable, then restart (should repeat from origin)
    stop_enable();
    repeat (10) @(posedge clk);

    start_enable();
    repeat (80) @(posedge clk);

    $display("TB completed with no assertion failures.");
    $finish;
  end

endmodule

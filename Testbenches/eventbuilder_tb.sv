`timescale 1ns/1ps

module tb_eventbuilder;

  // ============================
  // Match DUT parameters
  // ============================
  localparam int TS_WIDTH   = 52;
  localparam int POS_WIDTH  = 32;
  localparam int MAG_WIDTH  = 26;
  localparam int DEPTH_LOG2 = 3;
  localparam int DEPTH      = (1 << DEPTH_LOG2);

  // ============================
  // Clock / Reset
  // ============================
  logic clk;
  logic rst_n;

  initial clk = 1'b0;
  always #5 clk = ~clk;  // 100 MHz

  // ============================
  // DUT I/O
  // ============================
  logic                  pos_valid;
  logic [TS_WIDTH-1:0]   pos_time;
  logic [POS_WIDTH-1:0]  pos_data;

  logic                  chg_valid;
  logic [TS_WIDTH-1:0]   chg_time;
  logic [MAG_WIDTH-1:0]  chg_mag;
  logic                  chg_overflow;

  wire                   out_valid;
  wire [TS_WIDTH-1:0]    out_time;
  wire [POS_WIDTH-1:0]   out_pos;
  wire [MAG_WIDTH-1:0]   out_mag;
  wire                   drop_pos;
  wire                   drop_chg;
  wire                   match_overflow;

  // ============================
  // Instantiate DUT (Verilog RTL)
  // ============================
  eventbuilder #(
    .TS_WIDTH(TS_WIDTH),
    .POS_WIDTH(POS_WIDTH),
    .MAG_WIDTH(MAG_WIDTH),
    .DEPTH_LOG2(DEPTH_LOG2)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .pos_valid(pos_valid),
    .pos_time(pos_time),
    .pos_data(pos_data),
    .chg_valid(chg_valid),
    .chg_time(chg_time),
    .chg_mag(chg_mag),
    .chg_overflow(chg_overflow),
    .out_valid(out_valid),
    .out_time(out_time),
    .out_pos(out_pos),
    .out_mag(out_mag),
    .drop_pos(drop_pos),
    .drop_chg(drop_chg),
    .match_overflow(match_overflow)
  );

  // ============================================================
  // Reference model structures (SV-lite, no classes)
  // ============================================================
  typedef struct packed {
    logic [TS_WIDTH-1:0]  t;
    logic [POS_WIDTH-1:0] p;
  } pos_item_t;

  typedef struct packed {
    logic [TS_WIDTH-1:0]  t;
    logic [MAG_WIDTH-1:0] m;
    logic                 of;
  } chg_item_t;

  typedef struct packed {
    logic [TS_WIDTH-1:0]  t;
    logic [POS_WIDTH-1:0] p;
    logic [MAG_WIDTH-1:0] m;
    logic                 of;
  } out_item_t;

  // model FIFOs (queues)
  pos_item_t pos_q[$];
  chg_item_t chg_q[$];

  // expected output events (queue)
  out_item_t exp_q[$];

  // stats / error bookkeeping
  int unsigned errors;
  int unsigned matches_model;
  int unsigned drops_pos_model;
  int unsigned drops_chg_model;
  int unsigned drop_new_pos_full;
  int unsigned drop_new_chg_full;

  // ============================================================
  // Utilities
  // ============================================================
  task automatic reset_stats_and_model();
    begin
      pos_q.delete();
      chg_q.delete();
      exp_q.delete();
      errors            = 0;
      matches_model     = 0;
      drops_pos_model   = 0;
      drops_chg_model   = 0;
      drop_new_pos_full = 0;
      drop_new_chg_full = 0;
    end
  endtask

  task automatic do_reset();
    begin
      rst_n       = 1'b0;
      pos_valid   = 1'b0;
      pos_time    = '0;
      pos_data    = '0;
      chg_valid   = 1'b0;
      chg_time    = '0;
      chg_mag     = '0;
      chg_overflow= 1'b0;

      reset_stats_and_model();

      repeat (5) @(posedge clk);
      rst_n = 1'b1;
      repeat (2) @(posedge clk);
    end
  endtask

  function automatic logic is_x(input logic [1023:0] dummy); // unused helper placeholder
    is_x = 1'b0;
  endfunction

  // ============================================================
  // Reference model behavior
  // ============================================================

  // Push into model FIFOs with DUT-identical behavior:
  // if full, drop the new incoming item silently.
  task automatic model_push_pos(input pos_item_t it);
    begin
      if (pos_q.size() < DEPTH) pos_q.push_back(it);
      else drop_new_pos_full++;
    end
  endtask

  task automatic model_push_chg(input chg_item_t it);
    begin
      if (chg_q.size() < DEPTH) chg_q.push_back(it);
      else drop_new_chg_full++;
    end
  endtask

  // One "cycle" of match/drop decision.
  // Must be called exactly once per posedge when rst_n is high,
  // because DUT makes one decision per cycle.
  task automatic model_step();
    pos_item_t ph;
    chg_item_t ch;
    begin
      if ((pos_q.size() > 0) && (chg_q.size() > 0)) begin
        ph = pos_q[0];
        ch = chg_q[0];

        if (ph.t == ch.t) begin
          out_item_t oi;
          oi.t  = ph.t;
          oi.p  = ph.p;
          oi.m  = ch.m;
          oi.of = ch.of;

          exp_q.push_back(oi);
          matches_model++;

          pos_q.pop_front();
          chg_q.pop_front();
        end
        else if (ph.t < ch.t) begin
          pos_q.pop_front();
          drops_pos_model++;
        end
        else begin
          chg_q.pop_front();
          drops_chg_model++;
        end
      end
    end
  endtask

  // ============================================================
  // Drivers (1-cycle valid pulses)
  // ============================================================
  task automatic drive_pos_pulse(input logic [TS_WIDTH-1:0] t,
                                 input logic [POS_WIDTH-1:0] p);
    begin
      @(posedge clk);
      pos_valid <= 1'b1;
      pos_time  <= t;
      pos_data  <= p;
      model_push_pos('{t:t, p:p});

      @(posedge clk);
      pos_valid <= 1'b0;
    end
  endtask

  task automatic drive_chg_pulse(input logic [TS_WIDTH-1:0] t,
                                 input logic [MAG_WIDTH-1:0] m,
                                 input logic of);
    begin
      @(posedge clk);
      chg_valid    <= 1'b1;
      chg_time     <= t;
      chg_mag      <= m;
      chg_overflow <= of;
      model_push_chg('{t:t, m:m, of:of});

      @(posedge clk);
      chg_valid <= 1'b0;
    end
  endtask

  task automatic drive_both_pulse_same_cycle(input logic [TS_WIDTH-1:0] tpos,
                                             input logic [POS_WIDTH-1:0] p,
                                             input logic [TS_WIDTH-1:0] tchg,
                                             input logic [MAG_WIDTH-1:0] m,
                                             input logic of);
    begin
      @(posedge clk);
      pos_valid    <= 1'b1;
      pos_time     <= tpos;
      pos_data     <= p;
      chg_valid    <= 1'b1;
      chg_time     <= tchg;
      chg_mag      <= m;
      chg_overflow <= of;

      model_push_pos('{t:tpos, p:p});
      model_push_chg('{t:tchg, m:m, of:of});

      @(posedge clk);
      pos_valid <= 1'b0;
      chg_valid <= 1'b0;
    end
  endtask

  // optional idle cycles
  task automatic idle_cycles(input int n);
    int i;
    begin
      for (i=0; i<n; i++) @(posedge clk);
    end
  endtask

  // ============================================================
  // Monitor + Scoreboard check
  // ============================================================
  // IMPORTANT: Order matters:
  // DUT updates out_valid/out_* on posedge based on current FIFO heads.
  // Our model_step must be called on the same posedge to predict that cycle?s output.
  always @(posedge clk) begin
    if (!rst_n) begin
      // nothing
    end else begin
      model_step();

      // Scoreboard compare
      if (out_valid) begin
        if (exp_q.size() == 0) begin
          $error("[%0t] ERROR: out_valid but model expected none", $time);
          errors++;
        end else begin
          out_item_t exp;
          exp = exp_q.pop_front();

          if (out_time !== exp.t) begin
            $error("[%0t] ERROR: out_time exp=%0h got=%0h", $time, exp.t, out_time);
            errors++;
          end
          if (out_pos !== exp.p) begin
            $error("[%0t] ERROR: out_pos exp=%0h got=%0h", $time, exp.p, out_pos);
            errors++;
          end
          if (out_mag !== exp.m) begin
            $error("[%0t] ERROR: out_mag exp=%0h got=%0h", $time, exp.m, out_mag);
            errors++;
          end
          if (match_overflow !== exp.of) begin
            $error("[%0t] ERROR: match_overflow exp=%0b got=%0b", $time, exp.of, match_overflow);
            errors++;
          end
        end
      end
    end
  end

  // ============================================================
  // Assertions (protocol + invariants)
  // ============================================================

  // 1-cycle pulses
  property p_one_cycle_pulse(sig);
    @(posedge clk) disable iff (!rst_n)
      sig |=> !sig;
  endproperty

  assert property (p_one_cycle_pulse(out_valid))
    else begin $error("[%0t] out_valid not 1-cycle pulse", $time); errors++; end

  assert property (p_one_cycle_pulse(drop_pos))
    else begin $error("[%0t] drop_pos not 1-cycle pulse", $time); errors++; end

  assert property (p_one_cycle_pulse(drop_chg))
    else begin $error("[%0t] drop_chg not 1-cycle pulse", $time); errors++; end

  // mutually exclusive flags: cannot output and drop, cannot drop both
  property p_flag_mutex;
    @(posedge clk) disable iff (!rst_n)
      !((out_valid && drop_pos) || (out_valid && drop_chg) || (drop_pos && drop_chg));
  endproperty
  assert property (p_flag_mutex)
    else begin $error("[%0t] illegal flag combination", $time); errors++; end

  // no X on outputs when out_valid asserted
  property p_no_x_on_out;
    @(posedge clk) disable iff (!rst_n)
      out_valid |-> (!$isunknown(out_time) && !$isunknown(out_pos) && !$isunknown(out_mag) && !$isunknown(match_overflow));
  endproperty
  assert property (p_no_x_on_out)
    else begin $error("[%0t] X on outputs during out_valid", $time); errors++; end

  // ============================================================
  // Optional functional coverage (comment out if needed)
  // ============================================================
  covergroup cg @(posedge clk);
    coverpoint out_valid;
    coverpoint drop_pos;
    coverpoint drop_chg;
    coverpoint match_overflow;
    cross out_valid, match_overflow;
  endgroup
  cg cov = new();

  // ============================================================
  // Directed tests
  // ============================================================

  task automatic test_basic_match_same_cycle();
    logic [TS_WIDTH-1:0] t;
    begin
      t = 52'h100;
      drive_both_pulse_same_cycle(t, 32'hAAAA_5555, t, 26'h01ABCDE, 1'b0);
      idle_cycles(10);
    end
  endtask

  task automatic test_skewed_match_pos_first();
    logic [TS_WIDTH-1:0] t;
    begin
      t = 52'h200;
      fork
        begin
          drive_pos_pulse(t, 32'h1111_2222);
        end
        begin
          idle_cycles(3);
          drive_chg_pulse(t, 26'h0001234, 1'b1);
        end
      join
      idle_cycles(20);
    end
  endtask

  task automatic test_skewed_match_chg_first();
    logic [TS_WIDTH-1:0] t;
    begin
      t = 52'h300;
      fork
        begin
          drive_chg_pulse(t, 26'h0007777, 1'b0);
        end
        begin
          idle_cycles(4);
          drive_pos_pulse(t, 32'h3333_4444);
        end
      join
      idle_cycles(20);
    end
  endtask

  task automatic test_drop_pos_older();
    begin
      drive_both_pulse_same_cycle(52'h0100, 32'hDEAD_BEEF,
                                 52'h0200, 26'h0001111, 1'b0);
      idle_cycles(10);
    end
  endtask

  task automatic test_drop_chg_older();
    begin
      drive_both_pulse_same_cycle(52'h0300, 32'hCAFE_F00D,
                                 52'h0250, 26'h0002222, 1'b0);
      idle_cycles(10);
    end
  endtask

  // ============================================================
  // Random tests
  // ============================================================

  // Random matching events with bounded skew between pos and chg
  task automatic test_random_matches(input int n_events, input int max_skew);
    int i;
    logic [TS_WIDTH-1:0] base_t;
    begin
      base_t = 52'h1000;

      for (i = 0; i < n_events; i++) begin
        int sp, sc;
        logic [TS_WIDTH-1:0] t;
        t  = base_t + i;
        sp = $urandom_range(0, max_skew);
        sc = $urandom_range(0, max_skew);

        fork
          begin
            idle_cycles(sp);
            drive_pos_pulse(t, $urandom());
          end
          begin
            idle_cycles(sc);
            drive_chg_pulse(t, $urandom(), $urandom_range(0,1));
          end
        join
      end

      idle_cycles(200);
    end
  endtask

  // Random mixture of match/mismatch + random ordering
  task automatic test_random_mix(input int n_items);
    int i;
    begin
      for (i = 0; i < n_items; i++) begin
        bit do_match;
        logic [TS_WIDTH-1:0] tp, tc;

        do_match = ($urandom_range(0,99) < 70); // 70% match
        tp = $urandom();
        tc = do_match ? tp : (tp + $urandom_range(1,5));

        case ($urandom_range(0,2))
          0: drive_pos_pulse(tp, $urandom());
          1: drive_chg_pulse(tc, $urandom(), $urandom_range(0,1));
          2: drive_both_pulse_same_cycle(tp, $urandom(), tc, $urandom(), $urandom_range(0,1));
        endcase

        idle_cycles($urandom_range(0,2));
      end

      idle_cycles(300);
    end
  endtask

  // FIFO full behavior: push > DEPTH on one side so new inputs are dropped
  task automatic test_fifo_full_pressure();
    int i;
    logic [TS_WIDTH-1:0] t0;
    begin
      t0 = 52'h4000;

      // Fill pos FIFO beyond depth
      for (i = 0; i < DEPTH + 8; i++) begin
        drive_pos_pulse(t0 + i, $urandom());
      end

      // Now provide charge for the same timestamps; only the first DEPTH should be present
      for (i = 0; i < DEPTH + 8; i++) begin
        drive_chg_pulse(t0 + i, $urandom(), 1'b0);
      end

      idle_cycles(400);
    end
  endtask

  // ============================================================
  // Final checks
  // ============================================================
  task automatic final_checks();
    begin
      // exp_q should be empty after drain time
      if (exp_q.size() != 0) begin
        $error("ERROR: exp_q not empty at end: %0d remaining", exp_q.size());
        errors++;
      end

      $display("---- TEST SUMMARY ----");
      $display("errors             = %0d", errors);
      $display("matches_model      = %0d", matches_model);
      $display("drops_pos_model    = %0d", drops_pos_model);
      $display("drops_chg_model    = %0d", drops_chg_model);
      $display("drop_new_pos_full  = %0d", drop_new_pos_full);
      $display("drop_new_chg_full  = %0d", drop_new_chg_full);

      if (errors == 0) $display("PASS");
      else             $display("FAIL");
    end
  endtask

  // ============================================================
  // Main
  // ============================================================
  initial begin
    do_reset();

    test_basic_match_same_cycle();
    test_skewed_match_pos_first();
    test_skewed_match_chg_first();
    test_drop_pos_older();
    test_drop_chg_older();

    test_random_matches(200, 8);
    test_random_mix(400);
    test_fifo_full_pressure();

    final_checks();
    $finish;
  end

endmodule


// asoc_acq_core.sv - Acquisition core (baseline / placeholder).
//
// In a real ASOC design this block would:
//   - capture 4-channel waveform data from the ASIC
//   - detect events / triggers
//   - compute timing (e.g., CFD) and amplitude
//   - optionally buffer waveform windows
//   - push event records and/or waveform data into the readout FIFO.
//
// This module provides:
//   (A) a simulation-friendly pattern generator when no sample stream is connected
//   (B) a single-channel sample->CFD->event-word path that can be replicated per channel
//
module asoc_acq_core #(
  parameter int SAMPLE_W = 14
)(
  input  logic        clk,
  input  logic        rst_n,

  // control
  input  logic        run,
  input  logic [31:0] run_id,

  // config (from FPGA regs)
  input  logic [31:0] acq_cfg0,
  input  logic [31:0] acq_cfg1,
  input  logic [31:0] cfd_cfg0,
  input  logic [31:0] cfd_cfg1,

  // sample input (optional; leave unconnected and use pattern gen)
  input  logic        s_valid,
  input  logic signed [SAMPLE_W-1:0] s_data,

  // FIFO output (32-bit words)
  output logic        fifo_wr_en,
  output logic [31:0] fifo_din,
  input  logic        fifo_full
);

  // Simple pattern generator sample stream when external stream absent.
  // If s_valid is tied low, we generate synthetic pulses periodically.
  logic        gen_valid;
  logic signed [SAMPLE_W-1:0] gen_data;
  logic [15:0] gen_ctr;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      gen_ctr  <= 16'd0;
      gen_valid<= 1'b0;
      gen_data <= '0;
    end else begin
      gen_valid <= 1'b0;
      if (run) begin
        gen_ctr <= gen_ctr + 1'd1;
        // crude pulse: every 256 cycles generate a short ramp
        if (gen_ctr[7:0] == 8'h00) begin
          gen_valid <= 1'b1;
          gen_data  <= $signed(14'd0);
        end else if (gen_ctr[7:0] == 8'h01) begin
          gen_valid <= 1'b1;
          gen_data  <= $signed(14'd800);
        end else if (gen_ctr[7:0] == 8'h02) begin
          gen_valid <= 1'b1;
          gen_data  <= $signed(14'd2000);
        end else if (gen_ctr[7:0] == 8'h03) begin
          gen_valid <= 1'b1;
          gen_data  <= $signed(14'd1200);
        end else if (gen_ctr[7:0] == 8'h04) begin
          gen_valid <= 1'b1;
          gen_data  <= $signed(14'd200);
        end
      end else begin
        gen_ctr <= 16'd0;
      end
    end
  end

  logic        use_ext;
  assign use_ext = s_valid; // heuristic; for bring-up tie s_valid low to use generator

  logic        samp_valid;
  logic signed [SAMPLE_W-1:0] samp_data;
  assign samp_valid = use_ext ? s_valid : gen_valid;
  assign samp_data  = use_ext ? s_data  : gen_data;

  // CFD config decode (example packing; you can redefine to match firmware)
  // cfd_cfg0: [15:0] frac_q1_15, [23:16] delay (not used here), [31:24] reserved
  logic [15:0] frac_q1_15;
  assign frac_q1_15 = cfd_cfg0[15:0];

  // cfd_cfg1: [15:0] threshold (signed), others flags
  logic signed [SAMPLE_W-1:0] thresh;
  assign thresh = $signed(cfd_cfg1[15:0]);

  logic cfd_evt_v;
  logic [31:0] cfd_time_q16;
  logic signed [SAMPLE_W-1:0] cfd_amp;

  cfd_engine #(.SAMPLE_W(SAMPLE_W), .DELAY(8)) u_cfd (
    .clk        (clk),
    .rst_n      (rst_n),
    .frac_q1_15 (frac_q1_15),
    .threshold  (thresh),
    .s_valid    (samp_valid),
    .s_data     (samp_data),
    .s_ready    (),
    .evt_valid  (cfd_evt_v),
    .evt_time_q16 (cfd_time_q16),
    .evt_amp    (cfd_amp),
    .evt_ready  (1'b1) // we gate with fifo_full below
  );

  // Event formatter: push 3 words per event
  //   W0: 0xE0VVCCCC  (event tag)
  //   W1: time_q16
  //   W2: {run_id[15:0], amp[15:0]}
  typedef enum logic [1:0] {EW_IDLE, EW_W0, EW_W1, EW_W2} ew_state_t;
  ew_state_t ew_st;

  logic [31:0] w0, w1, w2;
  always_comb begin
    w0 = 32'hE000_0000 | (run_id[7:0] << 16) | 16'h0001; // simple marker
    w1 = cfd_time_q16;
    w2 = {run_id[15:0], $unsigned(cfd_amp)};
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ew_st <= EW_IDLE;
      fifo_wr_en <= 1'b0;
      fifo_din   <= '0;
    end else begin
      fifo_wr_en <= 1'b0;
      if (!run) begin
        ew_st <= EW_IDLE;
      end else begin
        unique case (ew_st)
          EW_IDLE: begin
            if (cfd_evt_v && !fifo_full) ew_st <= EW_W0;
          end
          EW_W0: begin
            if (!fifo_full) begin
              fifo_wr_en <= 1'b1;
              fifo_din   <= w0;
              ew_st      <= EW_W1;
            end
          end
          EW_W1: begin
            if (!fifo_full) begin
              fifo_wr_en <= 1'b1;
              fifo_din   <= w1;
              ew_st      <= EW_W2;
            end
          end
          EW_W2: begin
            if (!fifo_full) begin
              fifo_wr_en <= 1'b1;
              fifo_din   <= w2;
              ew_st      <= EW_IDLE;
            end
          end
        endcase
      end
    end
  end

endmodule

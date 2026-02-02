// apb_fpga_ctrl.sv - Implements firmware-visible FPGA register map (`fpga_ctrl.h`).
// Includes a readout FIFO. `FIFO_DATA` pops one word per read.
//
// Registers (offsets):
//  0x0000 ID           RO  ASCII 'ASOC'
//  0x0004 VERSION      RO  [31:16]=major [15:0]=minor
//  0x0008 CTRL         RW  bit0=run, bit1=reset_asoc (pulse), bit2=soft_reset (pulse)
//  0x000C STATUS       RO  bit0=run, bit1=asoc_locked, bit2=fifo_overflow
//  0x0010 IRQ_ENABLE   RW
//  0x0014 IRQ_STATUS   W1C
//  0x0018 RUN_ID       RW
//  0x0020 ACQ_CFG0     RW
//  0x0024 ACQ_CFG1     RW
//  0x0030 CFD_CFG0     RW
//  0x0034 CFD_CFG1     RW
//  0x0040 FIFO_LEVEL   RO
//  0x0044 FIFO_DATA    RO (pop)
module apb_fpga_ctrl #(
  parameter int ADDR_W = 16,
  parameter int DATA_W = 32,
  parameter int FIFO_DEPTH = 1024,
  parameter int VER_MAJOR = 1,
  parameter int VER_MINOR = 0
)(
  input  logic               PCLK,
  input  logic               PRESETn,
  input  logic [ADDR_W-1:0]  PADDR,
  input  logic               PSEL,
  input  logic               PENABLE,
  input  logic               PWRITE,
  input  logic [DATA_W-1:0]  PWDATA,
  output logic [DATA_W-1:0]  PRDATA,
  output logic               PREADY,
  output logic               PSLVERR,

  // status inputs
  input  logic               asoc_locked,

  // outputs to rest of design
  output logic               run,
  output logic               reset_asoc_pulse,
  output logic               soft_reset_pulse,

  // exported configuration/state
  output logic [31:0]        run_id_o,
  output logic [31:0]        acq_cfg0_o,
  output logic [31:0]        acq_cfg1_o,
  output logic [31:0]        cfd_cfg0_o,
  output logic [31:0]        cfd_cfg1_o,

  output logic               irq,


// Export to other blocks
assign run_id_o  = run_id;
assign acq_cfg0_o = acq_cfg0;
assign acq_cfg1_o = acq_cfg1;
assign cfd_cfg0_o = cfd_cfg0;
assign cfd_cfg1_o = cfd_cfg1;

  // FIFO write side (from acquisition core)
  input  logic               fifo_wr_en_i,
  input  logic [31:0]        fifo_din_i,
  output logic               fifo_full_o
);

  assign PSLVERR = 1'b0;

  wire setup  = PSEL && !PENABLE;
  wire access = PSEL && PENABLE;
  wire wr     = access && PWRITE;
  wire rd     = access && !PWRITE;

  // internal regs
  logic [31:0] irq_en;
  logic [31:0] irq_stat;
  logic [31:0] run_id;
  logic [31:0] acq_cfg0, acq_cfg1;
  logic [31:0] cfd_cfg0, cfd_cfg1;

  // FIFO
  logic fifo_rd_en;
  logic [31:0] fifo_dout;
  logic fifo_empty;
  logic [$clog2(FIFO_DEPTH+1)-1:0] fifo_level;
  logic fifo_overflow;

  sync_fifo #(.WIDTH(32), .DEPTH(FIFO_DEPTH)) u_fifo (
    .clk   (PCLK),
    .rst_n (PRESETn),
    .wr_en (fifo_wr_en_i),
    .din   (fifo_din_i),
    .full  (fifo_full_o),
    .rd_en (fifo_rd_en),
    .dout  (fifo_dout),
    .empty (fifo_empty),
    .level (fifo_level)
  );

  // overflow latch
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) fifo_overflow <= 1'b0;
    else if (fifo_wr_en_i && fifo_full_o) fifo_overflow <= 1'b1;
    else if (wr && PADDR[11:0]==12'h014 && (PWDATA[2])) fifo_overflow <= 1'b0; // clear via irq_status bit2
  end

  // Pop FIFO: issue rd_en during SETUP of FIFO_DATA read so data is ready in ACCESS.
  always_comb begin
    fifo_rd_en = 1'b0;
    if (setup && !PWRITE && (PADDR[11:0] == 12'h044) && !fifo_empty) begin
      fifo_rd_en = 1'b1;
    end
  end

  // PREADY: always ready; FIFO read latency is handled by asserting rd_en in setup.
  assign PREADY = 1'b1;

  // CTRL pulses
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      run <= 1'b0;
      reset_asoc_pulse <= 1'b0;
      soft_reset_pulse <= 1'b0;
      irq_en <= 32'h0;
      irq_stat <= 32'h0;
      run_id <= 32'h0;
      acq_cfg0 <= 32'h0;
      acq_cfg1 <= 32'h0;
      cfd_cfg0 <= 32'h0000_4000; // default frac ~0.5
      cfd_cfg1 <= 32'h0000_0100; // default threshold
    end else begin
      reset_asoc_pulse <= 1'b0;
      soft_reset_pulse <= 1'b0;

      // set irq sources
      if (fifo_overflow) irq_stat[2] <= 1'b1;

      if (wr) begin
        unique case (PADDR[11:0])
          12'h008: begin
            run <= PWDATA[0];
            if (PWDATA[1]) reset_asoc_pulse <= 1'b1;
            if (PWDATA[2]) soft_reset_pulse <= 1'b1;
          end
          12'h010: irq_en   <= PWDATA;
          12'h014: begin
            // W1C
            irq_stat <= irq_stat & ~PWDATA;
          end
          12'h018: run_id   <= PWDATA;
          12'h020: acq_cfg0 <= PWDATA;
          12'h024: acq_cfg1 <= PWDATA;
          12'h030: cfd_cfg0 <= PWDATA;
          12'h034: cfd_cfg1 <= PWDATA;
          default: ;
        endcase
      end
    end
  end

  // IRQ output: any enabled + pending
  assign irq = |(irq_en & irq_stat);

  // Read mux
  always_comb begin
    PRDATA = 32'h0;
    unique case (PADDR[11:0])
      12'h000: PRDATA = 32'h4153_4F43; // 'ASOC'
      12'h004: PRDATA = {16'(VER_MAJOR), 16'(VER_MINOR)};
      12'h008: PRDATA = {29'h0, 1'b0, 1'b0, run}; // pulses read as 0
      12'h00C: PRDATA = {29'h0, fifo_overflow, asoc_locked, run};
      12'h010: PRDATA = irq_en;
      12'h014: PRDATA = irq_stat;
      12'h018: PRDATA = run_id;
      12'h020: PRDATA = acq_cfg0;
      12'h024: PRDATA = acq_cfg1;
      12'h030: PRDATA = cfd_cfg0;
      12'h034: PRDATA = cfd_cfg1;
      12'h040: PRDATA = {{(32-$bits(fifo_level)){1'b0}}, fifo_level};
      12'h044: PRDATA = fifo_dout; // already captured by FIFO on setup
      default: PRDATA = 32'h0;
    endcase
  end

endmodule

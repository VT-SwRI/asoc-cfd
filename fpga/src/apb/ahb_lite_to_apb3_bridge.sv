// ahb_lite_to_apb3_bridge.sv - Minimal single-transfer AHB-Lite -> APB3 bridge.
// Supports non-burst, single-beat reads/writes. Not optimized.
// Use vendor cores if available.
//
// AHB-Lite: address/control in address phase, data in data phase.
// APB3: setup then access.
//
// This bridge accepts AHB transfers and performs corresponding APB transfers.
module ahb_lite_to_apb3_bridge #(
  parameter int ADDR_W = 16
)(
  input  logic          HCLK,
  input  logic          HRESETn,

  // AHB-Lite slave interface
  input  logic [31:0]   HADDR,
  input  logic [1:0]    HTRANS,
  input  logic          HWRITE,
  input  logic [2:0]    HSIZE,
  input  logic [31:0]   HWDATA,
  input  logic          HSEL,
  input  logic          HREADY,
  output logic [31:0]   HRDATA,
  output logic          HREADYOUT,
  output logic          HRESP,

  // APB3 master interface
  output logic [ADDR_W-1:0] PADDR,
  output logic          PSEL,
  output logic          PENABLE,
  output logic          PWRITE,
  output logic [31:0]   PWDATA,
  input  logic [31:0]   PRDATA,
  input  logic          PREADY,
  input  logic          PSLVERR
);

  typedef enum logic [1:0] {S_IDLE, S_SETUP, S_ACCESS} state_t;
  state_t st, st_n;

  logic ahb_xfer;
  assign ahb_xfer = HSEL && HREADY && (HTRANS[1]); // NONSEQ or SEQ

  // Latch AHB request
  logic [ADDR_W-1:0] addr_r;
  logic write_r;
  logic [31:0] wdata_r;

  always_ff @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      addr_r  <= '0;
      write_r <= 1'b0;
      wdata_r <= '0;
    end else if (ahb_xfer && st==S_IDLE) begin
      addr_r  <= HADDR[ADDR_W-1:0];
      write_r <= HWRITE;
      wdata_r <= HWDATA;
    end
  end

  // APB outputs
  always_comb begin
    PADDR   = addr_r;
    PWRITE  = write_r;
    PWDATA  = wdata_r;
    PSEL    = (st == S_SETUP) || (st == S_ACCESS);
    PENABLE = (st == S_ACCESS);
  end

  // Next-state
  always_comb begin
    st_n = st;
    unique case (st)
      S_IDLE:   if (ahb_xfer) st_n = S_SETUP;
      S_SETUP:  st_n = S_ACCESS;
      S_ACCESS: if (PREADY) st_n = S_IDLE;
    endcase
  end

  always_ff @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) st <= S_IDLE;
    else st <= st_n;
  end

  // AHB response
  // Stall AHB while APB in progress.
  always_comb begin
    HREADYOUT = (st == S_IDLE);
    HRDATA    = PRDATA;
    HRESP     = PSLVERR; // simplistic: map error to HRESP
  end

endmodule

// apb_decoder.sv - Simple 1-to-N APB3 decoder/interconnect.
// One initiator, N targets. Selection is address-based.
//
// This is intentionally simple and assumes only one target is addressed per transfer.
module apb_decoder #(
  parameter int ADDR_W = 16,
  parameter int DATA_W = 32,
  parameter int N      = 3,
  parameter logic [ADDR_W-1:0] BASE [N] = '{16'h0000, 16'h1000, 16'h2000},
  parameter logic [ADDR_W-1:0] MASK [N] = '{16'hF000, 16'hF000, 16'hF000}
)(
  input  logic                 PCLK,
  input  logic                 PRESETn,

  // Initiator side
  input  logic [ADDR_W-1:0]    i_PADDR,
  input  logic                 i_PSEL,
  input  logic                 i_PENABLE,
  input  logic                 i_PWRITE,
  input  logic [DATA_W-1:0]    i_PWDATA,
  output logic [DATA_W-1:0]    i_PRDATA,
  output logic                 i_PREADY,
  output logic                 i_PSLVERR,

  // Target side arrays
  output logic [ADDR_W-1:0]    t_PADDR   [N],
  output logic                 t_PSEL    [N],
  output logic                 t_PENABLE [N],
  output logic                 t_PWRITE  [N],
  output logic [DATA_W-1:0]    t_PWDATA  [N],
  input  logic [DATA_W-1:0]    t_PRDATA  [N],
  input  logic                 t_PREADY  [N],
  input  logic                 t_PSLVERR [N]
);

  logic [N-1:0] sel_onehot;

  genvar k;
  generate
    for (k=0; k<N; k++) begin : g_t
      assign t_PADDR[k]   = i_PADDR;
      assign t_PENABLE[k] = i_PENABLE;
      assign t_PWRITE[k]  = i_PWRITE;
      assign t_PWDATA[k]  = i_PWDATA;
      assign sel_onehot[k]= i_PSEL && ((i_PADDR & MASK[k]) == (BASE[k] & MASK[k]));
      assign t_PSEL[k]    = sel_onehot[k];
    end
  endgenerate

  // Mux responses. If none selected, return safe defaults.
  always_comb begin
    i_PRDATA  = '0;
    i_PREADY  = 1'b1;
    i_PSLVERR = 1'b0;
    for (int i=0; i<N; i++) begin
      if (sel_onehot[i]) begin
        i_PRDATA  = t_PRDATA[i];
        i_PREADY  = t_PREADY[i];
        i_PSLVERR = t_PSLVERR[i];
      end
    end
  end

endmodule

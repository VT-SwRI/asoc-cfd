// apb3_if.sv - Minimal APB3 interface wrapper.
// APB3: PSEL asserted in SETUP, PENABLE asserted in ACCESS. Transfer completes when PREADY==1.
interface apb3_if #(
  parameter int ADDR_W = 16,
  parameter int DATA_W = 32
)(
  input  logic PCLK,
  input  logic PRESETn
);
  logic [ADDR_W-1:0] PADDR;
  logic              PSEL;
  logic              PENABLE;
  logic              PWRITE;
  logic [DATA_W-1:0] PWDATA;
  logic [DATA_W-1:0] PRDATA;
  logic              PREADY;
  logic              PSLVERR;

  // Convenience signals
  function automatic logic setup_phase();
    return PSEL && !PENABLE;
  endfunction

  function automatic logic access_phase();
    return PSEL && PENABLE;
  endfunction

  function automatic logic write_access();
    return PSEL && PENABLE && PWRITE;
  endfunction

  function automatic logic read_access();
    return PSEL && PENABLE && !PWRITE;
  endfunction

  modport target (
    input  PADDR, PSEL, PENABLE, PWRITE, PWDATA,
    output PRDATA, PREADY, PSLVERR
  );

  modport initiator (
    output PADDR, PSEL, PENABLE, PWRITE, PWDATA,
    input  PRDATA, PREADY, PSLVERR
  );
endinterface

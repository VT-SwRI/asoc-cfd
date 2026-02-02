// asoc_fpga_top.sv - Top-level tying APB peripherals + acquisition core.
// Exposes a single APB3 target interface.
//
// If your system already has a vendor APB fabric (e.g., Microchip CoreAPB3),
// you can either:
//   (A) Use this file as a single APB target and map it into one slot, OR
//   (B) Instantiate each peripheral as a separate APB target and skip the internal decoder.
module asoc_fpga_top #(
  parameter int ADDR_W = 16,
  parameter int FIFO_DEPTH = 1024,
  parameter int HAS_UART = 1
)(
  input  logic              PCLK,
  input  logic              PRESETn,
  input  logic [ADDR_W-1:0] PADDR,
  input  logic              PSEL,
  input  logic              PENABLE,
  input  logic              PWRITE,
  input  logic [31:0]       PWDATA,
  output logic [31:0]       PRDATA,
  output logic              PREADY,
  output logic              PSLVERR,

  // IRQ line to CPU
  output logic              IRQ,

  // ASIC control/status
  input  logic              asoc_locked,
  output logic              asoc_reset_pulse,

  // SPI pins to ASoC register interface
  output logic              asoc_spi_sck,
  output logic              asoc_spi_mosi,
  input  logic              asoc_spi_miso,
  output logic              asoc_spi_cs_n,

  // Optional UART pins
  input  logic              uart_rx,
  output logic              uart_tx
);

  // Address decode: 0x0000 ctrl, 0x1000 spi, 0x2000 uart
  localparam int N = 3;
  localparam logic [ADDR_W-1:0] BASE [N] = '{16'h0000, 16'h1000, 16'h2000};
  localparam logic [ADDR_W-1:0] MASK [N] = '{16'hF000, 16'hF000, 16'hF000};

  logic [ADDR_W-1:0] t_PADDR   [N];
  logic              t_PSEL    [N];
  logic              t_PENABLE [N];
  logic              t_PWRITE  [N];
  logic [31:0]       t_PWDATA  [N];
  logic [31:0]       t_PRDATA  [N];
  logic              t_PREADY  [N];
  logic              t_PSLVERR [N];

  apb_decoder #(.ADDR_W(ADDR_W), .DATA_W(32), .N(N), .BASE(BASE), .MASK(MASK)) u_dec (
    .PCLK(PCLK), .PRESETn(PRESETn),
    .i_PADDR(PADDR), .i_PSEL(PSEL), .i_PENABLE(PENABLE), .i_PWRITE(PWRITE), .i_PWDATA(PWDATA),
    .i_PRDATA(PRDATA), .i_PREADY(PREADY), .i_PSLVERR(PSLVERR),
    .t_PADDR(t_PADDR), .t_PSEL(t_PSEL), .t_PENABLE(t_PENABLE), .t_PWRITE(t_PWRITE), .t_PWDATA(t_PWDATA),
    .t_PRDATA(t_PRDATA), .t_PREADY(t_PREADY), .t_PSLVERR(t_PSLVERR)
  );

  // FPGA ctrl + FIFO + acquisition core
  logic run;
  logic soft_reset_pulse;
  logic irq_ctrl;
  logic [31:0] run_id;
  logic [31:0] acq_cfg0, acq_cfg1;
  logic [31:0] cfd_cfg0, cfd_cfg1;

  logic fifo_wr_en;
  logic [31:0] fifo_din;
  logic fifo_full;

  apb_fpga_ctrl #(.ADDR_W(ADDR_W), .FIFO_DEPTH(FIFO_DEPTH), .VER_MAJOR(1), .VER_MINOR(0)) u_ctrl (
    .PCLK(PCLK), .PRESETn(PRESETn),
    .PADDR(t_PADDR[0]), .PSEL(t_PSEL[0]), .PENABLE(t_PENABLE[0]), .PWRITE(t_PWRITE[0]), .PWDATA(t_PWDATA[0]),
    .PRDATA(t_PRDATA[0]), .PREADY(t_PREADY[0]), .PSLVERR(t_PSLVERR[0]),
    .asoc_locked(asoc_locked),
    .run(run),
    .reset_asoc_pulse(asoc_reset_pulse),
    .soft_reset_pulse(soft_reset_pulse),
    .run_id_o(run_id),
    .acq_cfg0_o(acq_cfg0),
    .acq_cfg1_o(acq_cfg1),
    .cfd_cfg0_o(cfd_cfg0),
    .cfd_cfg1_o(cfd_cfg1),
    .irq(irq_ctrl),
    .fifo_wr_en_i(fifo_wr_en),
    .fifo_din_i(fifo_din),
    .fifo_full_o(fifo_full)
  );

  // Acquisition core (placeholder)
  asoc_acq_core u_acq (
    .clk(PCLK),
    .rst_n(PRESETn),
    .run(run),
    .run_id(run_id),
    .acq_cfg0(acq_cfg0),
    .acq_cfg1(acq_cfg1),
    .cfd_cfg0(cfd_cfg0),
    .cfd_cfg1(cfd_cfg1),
    .s_valid(1'b0),
    .s_data('0),
    .fifo_wr_en(fifo_wr_en),
    .fifo_din(fifo_din),
    .fifo_full(fifo_full)
  );

  // SPI portal
  logic irq_spi;
  apb_asoc_spi_portal #(.ADDR_W(ADDR_W)) u_spi_portal (
    .PCLK(PCLK), .PRESETn(PRESETn),
    .PADDR(t_PADDR[1]), .PSEL(t_PSEL[1]), .PENABLE(t_PENABLE[1]), .PWRITE(t_PWRITE[1]), .PWDATA(t_PWDATA[1]),
    .PRDATA(t_PRDATA[1]), .PREADY(t_PREADY[1]), .PSLVERR(t_PSLVERR[1]),
    .irq(irq_spi),
    .spi_sck(asoc_spi_sck),
    .spi_mosi(asoc_spi_mosi),
    .spi_miso(asoc_spi_miso),
    .spi_cs_n(asoc_spi_cs_n)
  );

  // UART (optional)
  generate
    if (HAS_UART) begin : g_uart
      apb_uart_simple u_uart (
        .PCLK(PCLK), .PRESETn(PRESETn),
        .PADDR(t_PADDR[2]), .PSEL(t_PSEL[2]), .PENABLE(t_PENABLE[2]),
        .PWRITE(t_PWRITE[2]), .PWDATA(t_PWDATA[2]),
        .PRDATA(t_PRDATA[2]), .PREADY(t_PREADY[2]), .PSLVERR(t_PSLVERR[2]),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
      );
    end else begin : g_uart_off
      assign t_PRDATA[2] = 32'h0;
      assign t_PREADY[2] = 1'b1;
      assign t_PSLVERR[2]= 1'b0;
      assign uart_tx = 1'b1;
    end
  endgenerate

  // IRQ OR
  assign IRQ = irq_ctrl | irq_spi;

endmodule

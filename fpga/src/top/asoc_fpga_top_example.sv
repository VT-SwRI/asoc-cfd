// asoc_fpga_top_example.sv - Compatibility wrapper for the original repository template.
// Instantiate `asoc_fpga_top` behind APB3, exposing ASIC SPI pins and IRQ.
//
// Replace pin names/IO standards per your A3PE starter kit constraints.
module asoc_fpga_top_example (
  input  wire        clk_sys,
  input  wire        rst_sys_n,

  // APB3 bus pins (from your bus fabric / CoreAPB3)
  input  wire [15:0] PADDR,
  input  wire        PSEL,
  input  wire        PENABLE,
  input  wire        PWRITE,
  input  wire [31:0] PWDATA,
  output wire [31:0] PRDATA,
  output wire        PREADY,
  output wire        PSLVERR,

  output wire        IRQ,

  // ASoC SPI portal
  output wire        asoc_spi_sck,
  output wire        asoc_spi_mosi,
  input  wire        asoc_spi_miso,
  output wire        asoc_spi_cs_n,

  // Optional UART pins
  input  wire        uart_rx,
  output wire        uart_tx,

  // status
  input  wire        asoc_locked,
  output wire        asoc_reset_pulse
);

  asoc_fpga_top #(.ADDR_W(16), .FIFO_DEPTH(1024), .HAS_UART(1)) u_top (
    .PCLK(clk_sys),
    .PRESETn(rst_sys_n),
    .PADDR(PADDR),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR),
    .IRQ(IRQ),
    .asoc_locked(asoc_locked),
    .asoc_reset_pulse(asoc_reset_pulse),
    .asoc_spi_sck(asoc_spi_sck),
    .asoc_spi_mosi(asoc_spi_mosi),
    .asoc_spi_miso(asoc_spi_miso),
    .asoc_spi_cs_n(asoc_spi_cs_n),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx)
  );

endmodule

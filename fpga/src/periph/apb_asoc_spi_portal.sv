// apb_asoc_spi_portal.sv - APB3 peripheral wrapping asoc_spi_master.
// Register map (offsets):
//  0x00 SPI_CFG    [0]=EN, [1]=START, [2]=IS_WRITE, [6:3]=LEN (1..4), [15:8]=CLK_DIV, [16]=CPOL, [17]=CPHA
//  0x04 SPI_ADDR   [15:0] register address
//  0x08 SPI_WDATA  payload data (LSB-first bytes)
//  0x0C SPI_RDATA  readback payload
//  0x10 SPI_STATUS [0]=BUSY, [1]=DONE (sticky), [2]=ERR (sticky)
//  0x14 IRQ_EN     [0]=DONE_IRQ_EN
//  0x18 IRQ_STATUS [0]=DONE (W1C)
module apb_asoc_spi_portal #(
  parameter int ADDR_W = 16,
  parameter int DATA_W = 32
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

  output logic               irq,

  // SPI pins
  output logic               spi_sck,
  output logic               spi_mosi,
  input  logic               spi_miso,
  output logic               spi_cs_n
);

  assign PREADY  = 1'b1;
  assign PSLVERR = 1'b0;

  // APB helpers
  wire setup  = PSEL && !PENABLE;
  wire access = PSEL && PENABLE;
  wire wr     = access && PWRITE;
  wire rd     = access && !PWRITE;

  // registers
  logic        en, start_pulse, is_write;
  logic [3:0]  len;
  logic [7:0]  clk_div;
  logic        cpol, cpha;
  logic [15:0] addr;
  logic [31:0] wdata, rdata;
  logic        done_sticky, err_sticky;
  logic        irq_en;
  logic        irq_stat;

  // start pulse on APB write
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      en <= 1'b0; is_write<=1'b0; len<=4'd4; clk_div<=8'd4; cpol<=1'b0; cpha<=1'b0;
      start_pulse <= 1'b0;
      addr <= 16'h0; wdata<=32'h0;
      done_sticky <= 1'b0; err_sticky<=1'b0;
      irq_en <= 1'b0; irq_stat<=1'b0;
    end else begin
      start_pulse <= 1'b0;

      if (wr) begin
        unique case (PADDR[7:0])
          8'h00: begin
            en       <= PWDATA[0];
            start_pulse <= PWDATA[1]; // writing 1 triggers
            is_write <= PWDATA[2];
            len      <= PWDATA[6:3];
            clk_div  <= PWDATA[15:8];
            cpol     <= PWDATA[16];
            cpha     <= PWDATA[17];
          end
          8'h04: addr  <= PWDATA[15:0];
          8'h08: wdata <= PWDATA;
          8'h14: irq_en <= PWDATA[0];
          8'h18: begin
            // W1C
            if (PWDATA[0]) irq_stat <= 1'b0;
          end
          default: ;
        endcase
      end

      // latch done/err from SPI
      if (spi_done) begin
        done_sticky <= 1'b1;
        irq_stat    <= 1'b1;
      end
      if (spi_err) err_sticky <= 1'b1;

      // clear sticky done on read of status (optional)
      if (rd && PADDR[7:0]==8'h10) done_sticky <= 1'b0;
    end
  end

  // SPI master instance
  logic spi_busy, spi_done, spi_err;
  asoc_spi_master u_spi (
    .clk        (PCLK),
    .rst_n      (PRESETn),
    .start      (start_pulse && en),
    .is_write   (is_write),
    .addr       (addr),
    .wdata      (wdata),
    .payload_len(len[2:0]),
    .clk_div    (clk_div),
    .cpol       (cpol),
    .cpha       (cpha),
    .busy       (spi_busy),
    .done       (spi_done),
    .error      (spi_err),
    .rdata      (rdata),
    .sck        (spi_sck),
    .mosi       (spi_mosi),
    .miso       (spi_miso),
    .cs_n       (spi_cs_n)
  );

  // IRQ
  assign irq = irq_en && irq_stat;

  // Read mux
  always_comb begin
    PRDATA = 32'h0;
    unique case (PADDR[7:0])
      8'h00: PRDATA = {14'h0, cpha, cpol, clk_div, len, is_write, 1'b0 /*START*/, en};
      8'h04: PRDATA = {16'h0, addr};
      8'h08: PRDATA = wdata;
      8'h0C: PRDATA = rdata;
      8'h10: PRDATA = {29'h0, err_sticky, done_sticky, spi_busy};
      8'h14: PRDATA = {31'h0, irq_en};
      8'h18: PRDATA = {31'h0, irq_stat};
      default: PRDATA = 32'h0;
    endcase
  end

endmodule

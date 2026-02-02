`timescale 1ns/1ps
module apb_smoke_tb;
  logic clk=0;
  always #5 clk=~clk; // 100MHz

  logic rst_n=0;

  // APB
  logic [15:0] PADDR;
  logic PSEL, PENABLE, PWRITE;
  logic [31:0] PWDATA;
  wire  [31:0] PRDATA;
  wire PREADY, PSLVERR;
  wire IRQ;

  // SPI
  wire sck, mosi, cs_n;
  logic miso=0;

  // UART
  logic uart_rx=1;
  wire uart_tx;

  logic asoc_locked=1'b1;
  wire asoc_reset_pulse;

  asoc_fpga_top_example dut (
    .clk_sys(clk),
    .rst_sys_n(rst_n),
    .PADDR(PADDR),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR),
    .IRQ(IRQ),
    .asoc_spi_sck(sck),
    .asoc_spi_mosi(mosi),
    .asoc_spi_miso(miso),
    .asoc_spi_cs_n(cs_n),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .asoc_locked(asoc_locked),
    .asoc_reset_pulse(asoc_reset_pulse)
  );

  task apb_write(input [15:0] addr, input [31:0] data);
    begin
      @(negedge clk);
      PADDR <= addr;
      PWDATA<= data;
      PWRITE<= 1;
      PSEL  <= 1;
      PENABLE<=0;
      @(negedge clk);
      PENABLE<=1;
      // wait ready (always 1 here)
      @(negedge clk);
      PSEL<=0; PENABLE<=0; PWRITE<=0;
    end
  endtask

  task apb_read(input [15:0] addr, output [31:0] data);
    begin
      @(negedge clk);
      PADDR <= addr;
      PWRITE<= 0;
      PSEL  <= 1;
      PENABLE<=0;
      @(negedge clk);
      PENABLE<=1;
      @(negedge clk);
      data = PRDATA;
      PSEL<=0; PENABLE<=0;
    end
  endtask

  initial begin
    PADDR=0;PSEL=0;PENABLE=0;PWRITE=0;PWDATA=0;
    #100;
    rst_n=1;
    #50;

    // Read ID
    automatic [31:0] r;
    apb_read(16'h0000, r);
    $display("ID=%h", r);

    // Enable run
    apb_write(16'h0008, 32'h1);

    // Read FIFO level
    repeat(20) begin
      apb_read(16'h0040, r);
      $display("FIFO_LEVEL=%0d", r);
      #20;
    end

    $finish;
  end
endmodule

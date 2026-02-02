// apb_uart_simple.sv - Minimal APB3 UART (8N1) for debug.
//
// This is *not* a full 16550. It's a tiny UART suitable for CLI bring-up.
// Register map (offsets):
//  0x00 TXDATA  WO  write byte to transmit
//  0x04 RXDATA  RO  read received byte
//  0x08 STATUS  RO  [0]=tx_ready, [1]=rx_valid
//  0x0C BAUDDIV RW  divider (clk/(baud*16)) - 1
module apb_uart_simple #(
  parameter int ADDR_W = 16,
  parameter int CLK_HZ = 50_000_000
)(
  input  logic               PCLK,
  input  logic               PRESETn,
  input  logic [ADDR_W-1:0]  PADDR,
  input  logic               PSEL,
  input  logic               PENABLE,
  input  logic               PWRITE,
  input  logic [31:0]        PWDATA,
  output logic [31:0]        PRDATA,
  output logic               PREADY,
  output logic               PSLVERR,

  input  logic               uart_rx,
  output logic               uart_tx
);

  assign PREADY  = 1'b1;
  assign PSLVERR = 1'b0;

  wire access = PSEL && PENABLE;
  wire wr = access && PWRITE;
  wire rd = access && !PWRITE;

  // baud generator (16x oversampling)
  logic [15:0] bauddiv;
  logic [15:0] baudcnt;
  logic tick16;

  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      bauddiv <= 16'd271; // ~115200 at 50MHz (50e6/(115200*16)-1 ≈ 26) -> adjust in real use
      baudcnt <= 16'd0;
      tick16  <= 1'b0;
    end else begin
      tick16 <= 1'b0;
      if (baudcnt == 0) begin
        baudcnt <= bauddiv;
        tick16 <= 1'b1;
      end else begin
        baudcnt <= baudcnt - 1'd1;
      end
      if (wr && PADDR[7:0]==8'h0C) bauddiv <= PWDATA[15:0];
    end
  end

  // TX
  logic [9:0] tx_shift;
  logic [3:0] tx_bit;
  logic [3:0] tx_tick;
  logic tx_busy;

  assign uart_tx = tx_shift[0];

  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      tx_shift <= 10'h3FF;
      tx_bit <= 4'd0;
      tx_tick <= 4'd0;
      tx_busy <= 1'b0;
    end else begin
      if (!tx_busy) begin
        if (wr && PADDR[7:0]==8'h00) begin
          // frame: start(0), 8 data bits LSB-first, stop(1)
          tx_shift <= {1'b1, PWDATA[7:0], 1'b0};
          tx_bit <= 4'd0;
          tx_tick <= 4'd0;
          tx_busy <= 1'b1;
        end
      end else if (tick16) begin
        if (tx_tick == 4'd15) begin
          tx_tick <= 4'd0;
          tx_shift <= {1'b1, tx_shift[9:1]};
          if (tx_bit == 4'd9) begin
            tx_busy <= 1'b0;
            tx_shift <= 10'h3FF;
          end else begin
            tx_bit <= tx_bit + 1'd1;
          end
        end else begin
          tx_tick <= tx_tick + 1'd1;
        end
      end
    end
  end

  // RX (simple, no parity, mid-bit sampling)
  logic [3:0] rx_tick;
  logic [3:0] rx_bit;
  logic [7:0] rx_data;
  logic rx_busy;
  logic rx_valid;

  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      rx_tick <= 4'd0;
      rx_bit <= 4'd0;
      rx_data <= 8'd0;
      rx_busy <= 1'b0;
      rx_valid <= 1'b0;
    end else begin
      if (rd && PADDR[7:0]==8'h04) rx_valid <= 1'b0; // clear on read
      if (!rx_busy) begin
        if (!uart_rx) begin // start bit detect
          rx_busy <= 1'b1;
          rx_tick <= 4'd0;
          rx_bit <= 4'd0;
        end
      end else if (tick16) begin
        rx_tick <= rx_tick + 1'd1;
        // sample at tick=8 (mid bit) for each bit
        if (rx_tick == 4'd7) begin
          if (rx_bit < 4'd8) rx_data <= {uart_rx, rx_data[7:1]};
          rx_bit <= rx_bit + 1'd1;
        end
        if (rx_bit == 4'd9 && rx_tick == 4'd15) begin
          rx_busy <= 1'b0;
          rx_valid <= 1'b1;
        end
      end
    end
  end

  // Read mux
  always_comb begin
    PRDATA = 32'h0;
    unique case (PADDR[7:0])
      8'h04: PRDATA = {24'h0, rx_data};
      8'h08: PRDATA = {30'h0, rx_valid, ~tx_busy};
      8'h0C: PRDATA = {16'h0, bauddiv};
      default: PRDATA = 32'h0;
    endcase
  end

endmodule

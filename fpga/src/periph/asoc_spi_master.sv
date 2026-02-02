// asoc_spi_master.sv - Simple SPI master (mode 0/1/2/3 configurable).
// Byte-oriented transaction to match firmware's "SPI register portal" pattern:
//
//   WRITE: [0x80 | addr_hi] [addr_lo] [payload bytes...]
//   READ : [0x00 | addr_hi] [addr_lo] then read back [payload bytes...]
//
// Payload length is 1..4 bytes, returned in rdata (LSB-first by byte).
module asoc_spi_master #(
  parameter int MAX_PAYLOAD_BYTES = 4
)(
  input  logic        clk,
  input  logic        rst_n,

  // control
  input  logic        start,
  input  logic        is_write,     // 1=write, 0=read
  input  logic [15:0] addr,
  input  logic [31:0] wdata,
  input  logic [2:0]  payload_len,  // 1..4
  input  logic [7:0]  clk_div,      // half-period divider (>=1)
  input  logic        cpol,
  input  logic        cpha,

  output logic        busy,
  output logic        done,
  output logic        error,
  output logic [31:0] rdata,

  // SPI pins
  output logic        sck,
  output logic        mosi,
  input  logic        miso,
  output logic        cs_n
);

  typedef enum logic [2:0] {IDLE, ASSERT_CS, SHIFT, DEASSERT_CS, FINISH} st_t;
  st_t st;

  // transaction assembly
  logic [7:0] tx_bytes [0:1+MAX_PAYLOAD_BYTES]; // 2 + payload
  logic [7:0] rx_bytes [0:1+MAX_PAYLOAD_BYTES];

  logic [2:0] len_b;
  logic [3:0] total_bytes;
  logic [9:0] total_bits;

  // shift state
  logic [9:0] bit_idx;
  logic [7:0] cur_tx;
  logic [2:0] cur_bit;
  logic [7:0] rx_shift;

  // clock divider
  logic [7:0] div_cnt;
  logic sck_i;
  logic sck_toggle;

  // helpers
  function automatic [7:0] addr0(input logic is_wr, input logic [15:0] a);
    addr0 = {is_wr, a[14:8]}; // bit7 = is_wr, bits[6:0]=addr_hi[6:0]
  endfunction

  // Note: if you need full 16-bit addr_hi, change format; this mirrors common 0x80|addr_hi usage.
  // Here we use addr[15] as part of lower bits by dropping it; update as needed.

  // Build tx bytes at start
  always_comb begin
    len_b = (payload_len == 0) ? 3'd1 : payload_len;
    total_bytes = 4'(2 + len_b); // 2 header + payload
    total_bits  = total_bytes * 8;
    // Header
    tx_bytes[0] = 8'h00;
    tx_bytes[0] = (is_write ? 8'h80 : 8'h00) | addr[15:8]; // simplest: keep full addr_hi
    tx_bytes[1] = addr[7:0];
    // Payload
    for (int i=0;i<MAX_PAYLOAD_BYTES;i++) begin
      if (i < len_b) begin
        tx_bytes[2+i] = wdata[8*i +: 8]; // LSB-first byte order
      end else begin
        tx_bytes[2+i] = 8'h00;
      end
    end
  end

  // SPI outputs (single driver)
always_comb begin
  busy  = (st != IDLE);
  done  = (st == FINISH);
  error = 1'b0;

  // CS asserted during transaction phases
  cs_n  = !((st==ASSERT_CS) || (st==SHIFT) || (st==DEASSERT_CS));

  // SCK idles low (or high if CPOL=1). We generate sck_i internally starting at 0.
  sck   = cpol ? ~sck_i : sck_i;

  // MOSI driven MSB-first for each byte
  mosi  = cur_tx[7-cur_bit];
end

// clock toggle

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      div_cnt <= 8'd0;
      sck_i   <= 1'b0;
      sck_toggle <= 1'b0;
    end else begin
      sck_toggle <= 1'b0;
      if (st == SHIFT) begin
        if (div_cnt == 0) begin
          div_cnt <= (clk_div == 0) ? 8'd1 : clk_div;
          sck_i <= ~sck_i;
          sck_toggle <= 1'b1;
        end else begin
          div_cnt <= div_cnt - 1'd1;
        end
      end else begin
        sck_i <= 1'b0;
        div_cnt <= (clk_div == 0) ? 8'd1 : clk_div;
      end
    end
  end

  // main FSM
  logic [3:0] byte_idx;
  logic sample_edge, shift_edge;

  // For CPHA:
  // - CPHA=0: change data on falling, sample on rising
  // - CPHA=1: change data on rising, sample on falling
  always_comb begin
    sample_edge = sck_toggle && (cpha ? (sck_i==1'b0) : (sck_i==1'b1));
    shift_edge  = sck_toggle && (cpha ? (sck_i==1'b1) : (sck_i==1'b0));
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= IDLE;
      bit_idx <= '0;
      byte_idx<= '0;
      cur_tx  <= 8'h00;
      cur_bit <= 3'd0;
      rx_shift<= 8'h00;
      for (int k=0;k<MAX_PAYLOAD_BYTES+2;k++) rx_bytes[k] <= 8'h00;
    end else begin
      unique case (st)
        IDLE: begin
          bit_idx <= '0;
          byte_idx<= '0;
          cur_bit <= 3'd0;
          if (start) begin
            st <= ASSERT_CS;
          end
        end
        ASSERT_CS: begin
          // Load first byte
          cur_tx <= tx_bytes[0];
          cur_bit<= 3'd0;
          rx_shift <= 8'h00;
          st <= SHIFT;
        end
        SHIFT: begin
          if (shift_edge) begin
            // Advance bit/byte
            if (cur_bit == 3'd7) begin
              // finished byte
              // store received byte
              rx_bytes[byte_idx] <= rx_shift;
              rx_shift <= 8'h00;

              if (byte_idx + 1 >= total_bytes) begin
                st <= DEASSERT_CS;
              end else begin
                byte_idx <= byte_idx + 1'd1;
                cur_tx   <= tx_bytes[byte_idx + 1'd1];
                cur_bit  <= 3'd0;
              end
            end else begin
              cur_bit <= cur_bit + 1'd1;
            end
          end
          if (sample_edge) begin
            rx_shift <= {rx_shift[6:0], miso};
          end
        end
        DEASSERT_CS: begin
          st <= FINISH;
        end
        FINISH: begin
          st <= IDLE;
        end
        default: st <= IDLE;
      endcase
    end
  end
  // Pack rdata from last payload bytes received.
  // For READ: rx bytes include echoes for first 2 header bytes; payload bytes follow.
  // For WRITE: response payload may be don't-care; we still capture.
  always_comb begin
    rdata = 32'h0;
    for (int i=0;i<MAX_PAYLOAD_BYTES;i++) begin
      if (i < len_b) begin
        rdata[8*i +: 8] = rx_bytes[2+i]; // bytes after header
      end
    end
  end

endmodule

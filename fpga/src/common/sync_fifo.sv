// sync_fifo.sv - Simple synchronous FIFO with 1-cycle read latency.
// - Write: accepted when wr_en && !full
// - Read : consumed when rd_en && !empty; data appears on dout next cycle
module sync_fifo #(
  parameter int WIDTH = 32,
  parameter int DEPTH = 1024
)(
  input  logic             clk,
  input  logic             rst_n,

  input  logic             wr_en,
  input  logic [WIDTH-1:0] din,
  output logic             full,

  input  logic             rd_en,
  output logic [WIDTH-1:0] dout,
  output logic             empty,

  output logic [$clog2(DEPTH+1)-1:0] level
);

  localparam int AW = $clog2(DEPTH);
  logic [WIDTH-1:0] mem [DEPTH];
  logic [AW-1:0] wptr, rptr;
  logic [AW:0]   count;

  assign full  = (count == DEPTH);
  assign empty = (count == 0);
  assign level = count[$clog2(DEPTH+1)-1:0];

  // Write
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr  <= '0;
    end else if (wr_en && !full) begin
      mem[wptr] <= din;
      wptr <= (wptr == DEPTH-1) ? '0 : (wptr + 1'b1);
    end
  end

  // Read pointer and registered dout (sync read)
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rptr <= '0;
      dout <= '0;
    end else if (rd_en && !empty) begin
      dout <= mem[rptr];
      rptr <= (rptr == DEPTH-1) ? '0 : (rptr + 1'b1);
    end
  end

  // Count
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      count <= '0;
    end else begin
      unique case ({(wr_en && !full),(rd_en && !empty)})
        2'b10: count <= count + 1'b1;
        2'b01: count <= count - 1'b1;
        default: count <= count;
      endcase
    end
  end

endmodule

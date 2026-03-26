///////////////////////////////////////////////////////////////////////////////////////////////////
// Author: Zack Kreitzer
//
// File: async_fifo.v
// File history:
//      1: 2/4/26: asynchronous FIFO buffer for use in event decoder modules
//
// Description: Asynchronous FIFO for use in event decoder modules
// Assumes active low resets on both ends
//
// Targeted device: ProASIC3 A3PN250
//
///////////////////////////////////////////////////////////////////////////////////////////////////

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
)(
    // write domain
    input  wire                  wr_clk,
    input  wire                  wr_rst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    output wire                  full,

    // read domain
    input  wire                  rd_clk,
    input  wire                  rd_rst_n,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] dout,
    output wire                  empty
);

    // use clog for addressing in FIFO
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    localparam ADDR_WIDTH = clog2(DEPTH);

    // ------------------------------------------------------------
    // FIFO storage
    // ------------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // ------------------------------------------------------------
    // Binary and Gray pointers
    // Extra MSB used for full/empty detection
    // ------------------------------------------------------------
    reg [ADDR_WIDTH:0] wr_ptr_bin;
    reg [ADDR_WIDTH:0] wr_ptr_gray;
    reg [ADDR_WIDTH:0] rd_ptr_bin;
    reg [ADDR_WIDTH:0] rd_ptr_gray;

    // ------------------------------------------------------------
    // Pointer synchronizers
    // ------------------------------------------------------------
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;

    // ------------------------------------------------------------
    // Binary to Gray conversion
    // ------------------------------------------------------------
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        begin
            bin2gray = (bin >> 1) ^ bin;
        end
    endfunction

    // ------------------------------------------------------------
    // WRITE DOMAIN
    // ------------------------------------------------------------
    wire [ADDR_WIDTH:0] wr_ptr_bin_next;
    wire [ADDR_WIDTH:0] wr_ptr_gray_next;

    assign wr_ptr_bin_next  = wr_ptr_bin + (wr_en && !full);
    assign wr_ptr_gray_next = bin2gray(wr_ptr_bin_next);

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= {ADDR_WIDTH+1{1'b0}};
            wr_ptr_gray <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;

            if (wr_en && !full)
                mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= din;
        end
    end

    // ------------------------------------------------------------
    // READ DOMAIN
    // ------------------------------------------------------------
    wire [ADDR_WIDTH:0] rd_ptr_bin_next;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next;

    assign rd_ptr_bin_next  = rd_ptr_bin + (rd_en && !empty);
    assign rd_ptr_gray_next = bin2gray(rd_ptr_bin_next);

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= {ADDR_WIDTH+1{1'b0}};
            rd_ptr_gray <= {ADDR_WIDTH+1{1'b0}};
            dout        <= {DATA_WIDTH{1'b0}};
        end else begin
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;

            if (rd_en && !empty)
                dout <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
        end
    end

    // ------------------------------------------------------------
    // Synchronize READ pointer into WRITE clock domain
    // ------------------------------------------------------------
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync1 <= {ADDR_WIDTH+1{1'b0}};
            rd_ptr_gray_sync2 <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // ------------------------------------------------------------
    // Synchronize WRITE pointer into READ clock domain
    // ------------------------------------------------------------
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_sync1 <= {ADDR_WIDTH+1{1'b0}};
            wr_ptr_gray_sync2 <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // ------------------------------------------------------------
    // EMPTY detection (read domain)
    // ------------------------------------------------------------
    assign empty = (rd_ptr_gray_next == wr_ptr_gray_sync2);

    // ------------------------------------------------------------
    // FULL detection (write domain)
    // ------------------------------------------------------------
    assign full = (wr_ptr_gray_next ==
                  {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
                    rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});

endmodule
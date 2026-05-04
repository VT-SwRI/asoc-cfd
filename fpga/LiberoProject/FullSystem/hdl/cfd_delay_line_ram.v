///////////////////////////////////////////////////////////////////////////////////////////////////  
// Company: SwRI/VT
//
// File: cfd_delay_line_ram.v  
// File history:
//  
//
// Description:   
// 
// Simple circular buffer RAM for the CFD delay line. A write-first bypass forwards new data
// when reading and writing the same address on the same cycle, but this shouldn't come up  
// due to delays of 0 always defaulting to 1 in the CFD frontend.
//  
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: VT MDE S26-23  
//
///////////////////////////////////////////////////////////////////////////////////////////////////

module cfd_delay_line_ram #(
    parameter integer DATA_W       = 16,  
    parameter integer DELAY_RAM_AW = 7,     // max delay of 127 samples  
    parameter integer DEPTH        = (1 << DELAY_RAM_AW) 
)(  
    input  wire                    clk,
    input  wire                    we,   
    input  wire [DELAY_RAM_AW-1:0] wr_addr,
    input  wire [DELAY_RAM_AW-1:0] rd_addr,
    input  wire [DATA_W-1:0]       din,  
    output reg  [DATA_W-1:0]       dout
);

    // specify synthesis style to avoid warnings
    (* syn_ramstyle = "rw_check" *) reg [DATA_W-1:0] mem [0:DEPTH-1];


    always @(posedge clk) begin
        if (we)     
            mem[wr_addr] <= din;

        // write-first bypass  
        if (we && (rd_addr == wr_addr))
            dout <= din;
        else   
            dout <= mem[rd_addr];
    end
 

endmodule 
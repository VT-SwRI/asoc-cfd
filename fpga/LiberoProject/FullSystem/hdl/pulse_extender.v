///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: pulse_extender.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

`timescale 1ns/1ps

module pulse_extender
#(
    parameter integer HOLD_CYCLES = 40000000
)
(
    input  wire i_clk,
    input  wire i_rst,
    input  wire i_trig,
    output reg  o_hold
);

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2 = 0;
            while (v > 0) begin
                v = v >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam integer CNT_W = clog2(HOLD_CYCLES + 1);

    reg [CNT_W-1:0] r_count;
    reg             r_trig_d;

    wire w_rise;
    assign w_rise = i_trig & ~r_trig_d;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_count  <= {CNT_W{1'b0}};
            r_trig_d <= 1'b0;
            o_hold   <= 1'b0;
        end else begin
            r_trig_d <= i_trig;

            if (w_rise) begin
                r_count <= HOLD_CYCLES - 1;
                o_hold  <= 1'b1;
            end else if (o_hold) begin
                if (r_count == 0) begin
                    o_hold <= 1'b0;
                end else begin
                    r_count <= r_count - 1'b1;
                end
            end
        end
    end

endmodule

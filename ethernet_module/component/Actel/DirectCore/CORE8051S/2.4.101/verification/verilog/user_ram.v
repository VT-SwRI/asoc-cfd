//-----------------------------------------------------------------------------
// Copyright 2006 Actel Corporation.  All rights reserved.
// IP Engineering
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// File:            user_ram.v
//
// Description:     Synch. transparent RAM
//
//
// Rev:             1.2  Dec06
//
// Notes:
//
//-----------------------------------------------------------------------------
module USER_RAM (wclk, waddr, wr, din, rclk, raddr, rd, dout);

    parameter WIDTH = 8;	// data width
    parameter DEPTH = 256;	// RAM depth
    parameter ASIZE  = 8;	// address width

    // RAM write signals
    input wclk;				// write clock input
    input[ASIZE - 1:0] waddr;
    input wr;				// write enable
    input[WIDTH - 1:0] din;
    // RAM read signals
    input rclk;				// read clock input
    input[ASIZE - 1:0] raddr;
    input rd;				// read enable
    output[WIDTH - 1:0] dout;

    reg[WIDTH - 1:0] dout;
    reg[WIDTH - 1:0] store[0:DEPTH - 1];

    //-----------------------------------------------------------------------
    // main
    //-----------------------------------------------------------------------

    //-------------------------------------------------------------------
    // RAM writes
    //-------------------------------------------------------------------
    always @(posedge wclk)
    begin
        if (wr)
            store[waddr] <= din ;
    end

    //-------------------------------------------------------------------
    // RAM reads
    //-------------------------------------------------------------------
    always @(posedge rclk)
    begin
        if (rd)
            dout <= store[raddr];
    end

endmodule

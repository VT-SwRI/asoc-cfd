//-----------------------------------------------------------------------------
// Copyright 2006 Actel Corporation.  All rights reserved.
// IP Engineering
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// File:            extclock.vhd
//
// Description:     External clock generator
//
//
// Rev:             1.2  Dec06
//
// Notes:
//
//-----------------------------------------------------------------------------

`timescale 1 ns / 100 ps

module EXTERNAL_CLOCK_GENERATOR (clk);

  parameter PERIOD = 100; // Clock pulse period
  parameter DUTY  = 50;
  output    clk;
  reg       clk;

  //------------------------------------------------------------------
  always
  begin : main
  //------------------------------------------------------------------
    parameter HALF_PERIOD = PERIOD * DUTY / 100;
    //--------------------------------------
    // Clock generator
    //--------------------------------------
    forever
    begin
      clk <= 1'b0 ;
      #HALF_PERIOD;
      clk <= 1'b1 ;
      #(PERIOD - HALF_PERIOD);
    end
  end

endmodule // module EXTERNAL_CLOCK_GENERATOR

//*******************************************************************--

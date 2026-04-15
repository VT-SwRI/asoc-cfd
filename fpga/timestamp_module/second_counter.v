///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: second_counter.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::ProASIC3> <Die::A3P400> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module second_counter (
  input  logic        clk,
  input  logic        reset,
  input  logic        pps,          // Increment on PPS
  input  logic        load,         // Load new value
  input  logic [31:0] set_time,     // Value to load
  output logic [31:0] seconds       // Current seconds count
);

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      seconds <= 32'b0;
    end else if (load) begin
      seconds <= set_time;
    end else if (pps) begin
      seconds <= seconds + 1;
    end
  end

endmodule

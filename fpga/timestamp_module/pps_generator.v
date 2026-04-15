///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: pps_generator.v
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
module pps_generator #(
  parameter CLK_FREQ = 40_000_000  //clk speed
)(
  input  logic clk,
  input  logic reset,
  input  logic external_pps,      // Optional external PPS
  input  logic use_external_pps,  // Select internal or external
  output logic pps                // Pulse per second output
);

  logic [31:0] counter;
  logic internal_pps;

  // Internal PPS generation
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      counter      <= 32'b0;
      internal_pps <= 1'b0;
    end else begin
      if (counter >= CLK_FREQ - 1) begin
        counter      <= 32'b0;
        internal_pps <= 1'b1;
      end else begin
        counter      <= counter + 1;
        internal_pps <= 1'b0;
      end
    end
  end

  // Select internal or external PPS
  assign pps = use_external_pps ? external_pps : internal_pps;

endmodule

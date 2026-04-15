///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: microsecond_counter.v
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

module microsecond_counter #(
  parameter CLK_FREQ = 40_000_000  
)(
  input  logic        clk,
  input  logic        reset,
  input  logic        pps,          // Resets counter on PPS
  output logic [19:0] microseconds  // 0 to 999,999
);

  // Calculate ticks per microsecond
  // For 100 MHz: 100 ticks = 1 microsecond
  localparam int TICKS_PER_US = CLK_FREQ / 1_000_000;

  logic [6:0]  tick_counter;  // Counts clock ticks within a microsecond
  logic [19:0] us_counter;    // Counts microseconds

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      tick_counter <= 7'b0;
      us_counter   <= 20'b0;
    end else if (pps) begin
      // PPS resets the microsecond counter for synchronization
      tick_counter <= 7'b0;
      us_counter   <= 20'b0;
    end else begin
      if (tick_counter >= TICKS_PER_US - 1) begin
        tick_counter <= 7'b0;
        if (us_counter >= 20'd999_999)
          us_counter <= 20'b0;
        else
          us_counter <= us_counter + 1;
      end else begin
        tick_counter <= tick_counter + 1;
      end
    end
  end

  assign microseconds = us_counter;

endmodule

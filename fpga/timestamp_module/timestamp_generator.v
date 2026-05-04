///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: timestamp_generator.v
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

module timestamp_generator #(
  parameter CLK_FREQ = 40_000_000
)(
  input  logic        clk,
  input  logic        reset,
  
  // Control inputs (from APB)
  input  logic [31:0] set_time,
  input  logic        set_time_valid,   // Pulse when APB writes set_time
  input  logic        use_external_pps, // Select PPS source
  
  // External PPS input (optional, e.g., from GPS)
  input  logic        external_pps,
  
  // Timestamp output
  output logic [51:0] timestamp,        // {seconds[31:0], microseconds[19:0]}
  output logic [31:0] seconds,
  output logic [19:0] microseconds
);

  // Internal signals
  logic        pps;
  logic        load;

  // PPS Generator
  pps_generator #(
    .CLK_FREQ(CLK_FREQ)
  ) u_pps_gen (
    .clk            (clk),
    .reset          (reset),
    .external_pps   (external_pps),
    .use_external_pps(use_external_pps),
    .pps            (pps)
  );

  // Microsecond Counter
  microsecond_counter #(
    .CLK_FREQ(CLK_FREQ)
  ) u_us_counter (
    .clk          (clk),
    .reset        (reset),
    .pps          (pps),
    .microseconds (microseconds)
  );

  // FSM for load control
  timestamp_fsm u_fsm (
    .clk            (clk),
    .reset          (reset),
    .set_time       (set_time),
    .set_time_valid (set_time_valid),
    .load           (load)
  );

  // Second Counter
  second_counter u_sec_counter (
    .clk      (clk),
    .reset    (reset),
    .pps      (pps),
    .load     (load),
    .set_time (set_time),
    .seconds  (seconds)
  );

  // Combine into 52-bit timestamp
  assign timestamp = {seconds, microseconds};

endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: timestamp_fsm.v
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

module timestamp_fsm (
  input  logic        clk,
  input  logic        reset,
  input  logic [31:0] set_time,
  input  logic        set_time_valid,  // Pulse when new time is written
  output logic        load
);

  // Simple approach: generate load pulse when set_time_valid is asserted
  // This comes from the APB write to the set_time register

  typedef enum logic [1:0] {
    IDLE,
    LOAD,
    WAIT
  } state_t;

  state_t state;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
      load  <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          load <= 1'b0;
          if (set_time_valid) begin
            state <= LOAD;
          end
        end

        LOAD: begin
          load  <= 1'b1;  // Assert load for one cycle
          state <= WAIT;
        end

        WAIT: begin
          load <= 1'b0;
          if (!set_time_valid) begin
            state <= IDLE;  // Wait for valid to deassert
          end
        end
      endcase
    end
  end

endmodule


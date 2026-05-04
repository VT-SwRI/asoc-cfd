///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: SwRI/VT
//
// File: mux_gain_test.v
//
// Description:
//   2:1 mux for the post-DSP / post-pattern-gen event stream. Selects between
//   the DSP pipeline output and the pattern generator output based on `sel`:
//     sel = 0 -> DSP outputs (out_*_dsp)
//     sel = 1 -> Pattern generator outputs (out_*_test)
//
//   Purely combinational. clk and rst are present in the port list for
//   instantiation symmetry with other event-stream blocks but are unused.
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
//
///////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module mux_gain_test #(
    parameter integer POS_WIDTH = 32,
    parameter integer MAG_WIDTH = 16
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   sel,

    // DSP-side event inputs
    input  wire [63:0]            out_tag_dsp,
    input  wire                   out_dv_dsp,
    input  wire [POS_WIDTH-1:0]   out_x_dsp,
    input  wire [POS_WIDTH-1:0]   out_y_dsp,
    input  wire [MAG_WIDTH-1:0]   out_mag_dsp,

    // Pattern-generator-side event inputs
    input  wire [63:0]            out_tag_test,
    input  wire                   out_dv_test,
    input  wire [POS_WIDTH-1:0]   out_x_test,
    input  wire [POS_WIDTH-1:0]   out_y_test,
    input  wire [MAG_WIDTH-1:0]   out_mag_test,

    // Selected event output
    output wire [63:0]            out_tag,
    output wire                   out_dv,
    output wire [POS_WIDTH-1:0]   out_x,
    output wire [POS_WIDTH-1:0]   out_y,
    output wire [MAG_WIDTH-1:0]   out_mag
);

    assign out_tag = sel ? out_tag_test : out_tag_dsp;
    assign out_x   = sel ? out_x_test   : out_x_dsp;
    assign out_y   = sel ? out_y_test   : out_y_dsp;
    assign out_mag = sel ? out_mag_test : out_mag_dsp;
    assign out_dv  = sel ? out_dv_test  : out_dv_dsp;

endmodule
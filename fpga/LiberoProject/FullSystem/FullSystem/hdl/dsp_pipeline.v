///////////////////////////////////////////////////////////////////////////////////////////////////  
// Company: SwRI/VT
//
// File: dsp_pipeline.v
// File history:
//
// 
// Description: 
//
// Top-level DSP pipeline for an MCP detector with XDL annodes. Accepts raw ADC data,  
// computes event position and peak magnitude, and outputs the event data.
//
// Event protocol / assumptions:
//   - An event begins when adc_valid goes high and ends when it goes low.  
//   - Events are 64 to 1024 samples long (per channel). Shorter events produce no output.
//   - All 4 channels carry the same number of samples per event.
//   - Events are contiguous and are separated by 1+ idle cycles (adc_valid low).  
//   - tag_in must be stable when adc_valid rises. Tags must be unique and increasing.
//
// Input format:
//   - adc_x1/x2/y1/y2: 12-bit unsigned raw ADC samples (UQ12.0)
//   - att_q0_13:       14-bit unsigned attenuation fraction (UQ1.13)
//   - delay_val:       7-bit unsigned delay in samples (1-127)
//   - threshold:       16-bit signed threshold in preprocessed units (SQ12.3)
//   - zc_neg_samples:  8-bit unsigned minimum consecutive negative bipolar samples (0-255)
//   - kx, ky:          20-bit unsigned propagation constants (UQ1.19)
//   - tag_in:          64-bit event timestamp tag (1 microsecond per count)
//
// Output format:
//   - out_x, out_y:     32-bit signed position in microns (SQ31.0)
//   - out_mag:          16-bit signed sum of 4 channel peaks (SQ15.0, truncated from SQ12.3)
//   - out_tag:          64-bit timestamp tag of the matched event (1 microsecond per count)
//   - event_missed:     pulse when a valid event could not be processed (CFD fail or dropped)
//   - pos_rejected:     pulse when position falls outside the configured window
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: VT MDE S26-23
//   
///////////////////////////////////////////////////////////////////////////////////////////////////  

module dsp_pipeline #(
    parameter integer DELAY_RAM_AW      = 7,
    parameter integer MAX_EVENT_SAMPLES = 1024,  
    parameter integer IDX_W             = 10,
    parameter integer FRAC_BITS         = 10,  
    parameter integer K_WIDTH   = 20,
    parameter integer K_FRAC    = 19,
    parameter integer POS_WIDTH = 32,  
    parameter integer WINDOW_X  = 51000,
    parameter integer WINDOW_Y  = 51000,
    parameter integer MAG_WIDTH = 16
)(  
    input  wire        clk,
    input  wire        rst,
  
    // raw ADC inputs (active when adc_valid is high)
    input  wire        adc_valid,
    input  wire [11:0] adc_x1,
    input  wire [11:0] adc_x2,
    input  wire [11:0] adc_y1,  
    input  wire [11:0] adc_y2,

    // runtime CFD configuration (must be stable before adc_valid rises)  
    input  wire [13:0]                 att_q0_13,
    input  wire [DELAY_RAM_AW-1:0]     delay_val,
    input  wire signed [15:0]          threshold,
    input  wire [7:0]                  zc_neg_samples,
 
    // propagation constants (UQ1.19, must be stable before adc_valid rises)  
    input  wire [K_WIDTH-1:0]          kx,
    input  wire [K_WIDTH-1:0]          ky,

    // event tag (must be stable when adc_valid rises)
    input  wire [63:0]                 tag_in,
  
    // combined event output (from event builder)
    output wire                        out_valid,
    output wire [63:0]                 out_tag,
    output wire signed [POS_WIDTH-1:0] out_x,
    output wire signed [POS_WIDTH-1:0] out_y,
    output wire signed [MAG_WIDTH-1:0] out_mag,
  
    // status flags (active one cycle each)
    output wire                        event_missed,   // CFD failed or event dropped
    output wire                        pos_rejected    // position outside window  
);

    // preprocessor outputs
    wire                pp_valid;
    wire signed [15:0]  pp_x1, pp_x2, pp_y1, pp_y2;     
    wire [63:0]         pp_tag;

    // CFD outputs
    wire                cfd_ev_valid, cfd_ev_fail, cfd_ev_dropped;
    wire [IDX_W-1:0]    cfd_tpx1_int,  cfd_tpx2_int,  cfd_tpy1_int,  cfd_tpy2_int;     
    wire [FRAC_BITS-1:0] cfd_tpx1_frac, cfd_tpx2_frac, cfd_tpy1_frac, cfd_tpy2_frac;
    wire [63:0]         cfd_tag;

    // position calculator outputs
    wire signed [POS_WIDTH-1:0] pos_x_w, pos_y_w;
    wire                        pos_valid_w, pos_rejected_w;  
    wire [63:0]                 pos_tag_w;
  
    // peak detector outputs
    wire                        peak_valid;  
    wire signed [MAG_WIDTH-1:0] peak_sum;
    wire [63:0]                 peak_tag;

    // combined status flags 
    assign event_missed = cfd_ev_fail | cfd_ev_dropped;  
    assign pos_rejected = pos_rejected_w;

    // preprocessor
    adc_preprocess_4ch u_preprocess (
        .clk      (clk),
        .rst      (rst),   
        .in_valid (adc_valid),
        .x1_raw   (adc_x1),
        .x2_raw   (adc_x2),
        .y1_raw   (adc_y1),
        .y2_raw   (adc_y2),
        .tag_in   (tag_in),
        .tag_out  (pp_tag),
        .out_valid(pp_valid),
        .x1_out   (pp_x1),
        .x2_out   (pp_x2),
        .y1_out   (pp_y1),
        .y2_out   (pp_y2)
    );

    // 4-channel CFD  
    cfd_4ch #(
        .DELAY_RAM_AW     (DELAY_RAM_AW),
        .MAX_EVENT_SAMPLES(MAX_EVENT_SAMPLES),
        .IDX_W            (IDX_W),
        .FRAC_BITS        (FRAC_BITS)
    ) u_cfd (
        .clk           (clk),
        .rst           (rst),
        .sample_valid  (pp_valid),
        .x1_in         (pp_x1),
        .x2_in         (pp_x2),
        .y1_in         (pp_y1),
        .y2_in         (pp_y2),
        .att_q0_13     (att_q0_13),
        .delay_val     (delay_val),   
        .threshold     (threshold),
        .zc_neg_samples(zc_neg_samples),
        .tag_in        (pp_tag),
        .tpx1_int      (cfd_tpx1_int),
        .tpx1_frac     (cfd_tpx1_frac),
        .tpx2_int      (cfd_tpx2_int), 
        .tpx2_frac     (cfd_tpx2_frac),
        .tpy1_int      (cfd_tpy1_int),
        .tpy1_frac     (cfd_tpy1_frac),
        .tpy2_int      (cfd_tpy2_int),  
        .tpy2_frac     (cfd_tpy2_frac),
        .event_valid   (cfd_ev_valid),
        .event_fail    (cfd_ev_fail),
        .event_dropped (cfd_ev_dropped),
        .tag_out       (cfd_tag)
    );

    // position calculator
    position_calc #(
        .IDX_W     (IDX_W),
        .FRAC_BITS (FRAC_BITS),
        .K_WIDTH   (K_WIDTH), 
        .K_FRAC    (K_FRAC),
        .POS_WIDTH (POS_WIDTH),
        .WINDOW_X  (WINDOW_X),
        .WINDOW_Y  (WINDOW_Y)    
    ) u_pos_calc (
        .clk         (clk),
        .rst         (rst),
        .event_valid (cfd_ev_valid),
        .tx1_int     (cfd_tpx1_int),   
        .tx1_frac    (cfd_tpx1_frac),
        .tx2_int     (cfd_tpx2_int),
        .tx2_frac    (cfd_tpx2_frac),
        .ty1_int     (cfd_tpy1_int),
        .ty1_frac    (cfd_tpy1_frac),       
        .ty2_int     (cfd_tpy2_int),
        .ty2_frac    (cfd_tpy2_frac),
        .kx          (kx),
        .ky          (ky),
        .tag_in      (cfd_tag),
        .x_pos       (pos_x_w),  
        .y_pos       (pos_y_w),
        .pos_valid   (pos_valid_w),
        .pos_rejected(pos_rejected_w),  
        .tag_out     (pos_tag_w)
    );
              
    // peak detector
    peak_detector_4ch #(
        .ADC_WIDTH (16),   
        .TS_WIDTH  (64),
        .OUT_WIDTH (MAG_WIDTH)
    ) u_peak (
        .clk          (clk),
        .rst          (rst),
        .in_valid     (pp_valid),
        .adc0         (pp_x1),
        .adc1         (pp_x2),
        .adc2         (pp_y1),     
        .adc3         (pp_y2),
        .in_timestamp (pp_tag),
        .out_valid    (peak_valid),   
        .out_sum      (peak_sum),
        .out_timestamp(peak_tag)
    );

    // event builder: matches position and peak results by tag
    // orphaned magnitude entries from failed/rejected events are drained    
    // by the older-tag-drop mechanism or evicted by force-push
    event_builder #(   
        .TAG_WIDTH  (64),
        .POS_WIDTH  (POS_WIDTH),
        .MAG_WIDTH  (MAG_WIDTH),
        .DEPTH_LOG2 (2)
    ) u_event_builder (
        .clk       (clk),
        .rst       (rst),    
        .pos_valid (pos_valid_w),
        .pos_tag   (pos_tag_w),
        .pos_x     (pos_x_w),
        .pos_y     (pos_y_w),  
        .mag_valid (peak_valid),
        .mag_tag   (peak_tag),
        .mag_val   (peak_sum),
        .out_valid (out_valid),
        .out_tag   (out_tag),    
        .out_x     (out_x),   
        .out_y     (out_y),
        .out_mag   (out_mag),
        .drop_pos  (),          // unconnected, internal diagnostic
        .drop_mag  (),          // unconnected, internal diagnostic
        .mag_force_pop()        // unconnected, internal diagnostic
    );   

endmodule
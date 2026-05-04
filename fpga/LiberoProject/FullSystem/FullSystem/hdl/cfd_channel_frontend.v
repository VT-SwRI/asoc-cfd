///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: SwRI/VT
//
// File: cfd_channel_frontend.v
// File history:
//  
//
// Description:
// 
// Single-channel CFD frontend. Computes the bipolar signal (delayed - attenuated) and detects
// the first qualifying zero crossing per event. The delayed and attenuated paths are each
// 4 cycles deep so they stay aligned
//
// A zero crossing is accepted only when the pipeline has filled (6 cycles), the threshold has 
// been exceeded at least once, enough consecutive negative samples have been seen, and
// no previous crossing was already accepted for this event. This is done to avoid detecting early 
// zero crossings from stale data from previous events or due to noise causing small zero crossings
// before a real pulse has occured.
//
// During the first delay_val samples of each event, the delay RAM contains stale data from the
// previous event. Rather than discarding these samples entirely, the delayed path is forced to
// zero so that the bipolar signal equals -attenuated during this period. This keeps the sample
// count and index tracking consistent without injecting stale data into the bipolar signal.
//   
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: VT MDE S26-23
//  
///////////////////////////////////////////////////////////////////////////////////////////////////  
 
module cfd_channel_frontend #(   
    parameter integer DELAY_RAM_AW      = 7,     // max delay of 127 samples
    parameter integer MAX_EVENT_SAMPLES = 1024,  // matches defined maximum event legth
    parameter integer IDX_W             = 10,
    parameter integer FRAC_BITS         = 10
)(                
    input  wire                    clk,
    input  wire                    rst,  
    input  wire                    sample_valid,
    input  wire                    event_start,  
    input  wire signed [15:0]      sample_in,

    // runtime configuration (latched at the start of each event)
    input  wire [13:0]             att_q0_13,  
    input  wire [DELAY_RAM_AW-1:0] delay_val,
    input  wire signed [15:0]      threshold,
    input  wire [7:0]              zc_neg_samples,   

    // per-event outputs (stable from first ZC until next event_start)
    output reg                     hit_found,
    output reg [15:0]              ca_out,       // bip value at ZC (non-negative)
    output reg signed [16:0]       cb_out,       // bip value before ZC (negative)  
    output reg [IDX_W-1:0]         idx_cb_out,   // sample index of cb
  
    // debug outputs
    output reg  signed [16:0]      bip,
    output wire                    zc   
);

    // latch configuration at event_start so it can't change mid-event
    // if delay is set to 0 it defaults to 1 in order to avoid simultaneous read/write on the RAM  
    reg [DELAY_RAM_AW-1:0] delay_reg;
    reg [13:0]             att_reg;    
    reg signed [15:0]      thresh_reg;
    reg [7:0]              zc_neg_reg;
   
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            delay_reg  <= {{(DELAY_RAM_AW-1){1'b0}}, 1'b1};
            att_reg    <= 14'd0;
            thresh_reg <= 16'sd0;
            zc_neg_reg <= 8'd2;
        end else if (event_start) begin
            delay_reg <= (delay_val == {DELAY_RAM_AW{1'b0}})
                         ? {{(DELAY_RAM_AW-1){1'b0}}, 1'b1}
                         : delay_val;
            att_reg    <= att_q0_13;
            thresh_reg <= threshold;
            zc_neg_reg <= zc_neg_samples;
        end
    end
            
    // delay line RAM
    reg  [DELAY_RAM_AW-1:0] wr_ptr;
    wire [DELAY_RAM_AW-1:0] rd_ptr = wr_ptr - delay_reg;
    wire [15:0] delayed_u;

    cfd_delay_line_ram #(
        .DATA_W      (16),
        .DELAY_RAM_AW(DELAY_RAM_AW),
        .DEPTH       (1 << DELAY_RAM_AW)
    ) u_delay (
        .clk    (clk),
        .we     (sample_valid),
        .wr_addr(wr_ptr),
        .rd_addr(rd_ptr),      
        .din    (sample_in),
        .dout   (delayed_u)
    );

    // sample index (resets at event_start, wraps at MAX_EVENT_SAMPLES)
    reg [IDX_W-1:0] idx_curr;

    always @(posedge clk or posedge rst) begin
        if (rst) begin   
            wr_ptr   <= {DELAY_RAM_AW{1'b0}};
            idx_curr <= {IDX_W{1'b0}};
        end else if (sample_valid) begin    
            wr_ptr <= wr_ptr + {{(DELAY_RAM_AW-1){1'b0}}, 1'b1};

            if (event_start)
                idx_curr <= {IDX_W{1'b0}};
            else if (idx_curr == (MAX_EVENT_SAMPLES - 1))
                idx_curr <= {IDX_W{1'b0}};
            else    
                idx_curr <= idx_curr + {{(IDX_W-1){1'b0}}, 1'b1};
        end
    end

    // delay line fill tracking: counts samples written to the RAM during this event.
    // until delay_reg samples have been written, the read pointer references stale data
    // from the previous event, so the delayed output is forced to zero instead.
    // the counter compares against delay_reg - 1 and the result is registered, so
    // delay_filled goes high one cycle after the count reaches the threshold. This
    // aligns exactly with the RAM's 1-cycle read latency: the read initiated on the
    // cycle the count hits is the first valid one, and its result appears in delayed_u
    // on the same cycle delay_filled goes high.
    reg [DELAY_RAM_AW-1:0] delay_fill_cnt;
    reg                    delay_filled;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            delay_fill_cnt <= {DELAY_RAM_AW{1'b0}};
            delay_filled   <= 1'b0;
        end else if (event_start) begin
            delay_fill_cnt <= {DELAY_RAM_AW{1'b0}};
            delay_filled   <= 1'b0;
        end else if (sample_valid && !delay_filled) begin
            if (delay_fill_cnt == delay_reg - 1'b1)
                delay_filled <= 1'b1;
            else
                delay_fill_cnt <= delay_fill_cnt + 1'b1;
        end
    end

    // delayed path pipeline (1 RAM + 3 regs = 4 cycles, matching attenuated path)
    // before the delay line is filled, force the delayed value to zero so the bipolar
    // signal becomes just -attenuated rather than using stale data
    wire [15:0] delayed_gated = delay_filled ? delayed_u : 16'd0;

    reg [15:0] delayed_d1, delayed_d2, delayed_d3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            delayed_d1 <= 16'd0;
            delayed_d2 <= 16'd0;
            delayed_d3 <= 16'd0;
        end else if (sample_valid) begin
            delayed_d1 <= delayed_gated;     
            delayed_d2 <= delayed_d1;
            delayed_d3 <= delayed_d2;
        end
    end
       
    // attenuated path: sample_in * att_reg via 3-stage pipelined multiplier 
    // extra output register (att_samp_q) breaks timing into the subtractor
    // total: 3 (IP) + 1 (reg) = 4 cycles, matching delayed path  
    wire [15:0] mult_dataA = sample_in[15:0];   
    wire [13:0] mult_dataB = att_reg[13:0];
    wire [29:0] prod_w;
     
    mult_16x14_3p mult_att (   
        .Clock(clk),  
        .DataA(mult_dataA),  
        .DataB(mult_dataB),         
        .Mult (prod_w)   
    );

    // extract signed attenuated sample from product bits [29:13]  
    reg signed [16:0] att_samp_q;  

    always @(posedge clk or posedge rst) begin  
        if (rst)        
            att_samp_q <= 17'sd0; 
        else if (sample_valid)    
            att_samp_q <= $signed(prod_w[29:13]); 
    end  

    wire signed [16:0] delayed_signed = $signed({delayed_d3[15], delayed_d3});  

    // index pipeline (3 stages to align with bipolar output)   
    // total: idx_curr(1) + pipe0/1/2(3) + idx_bip(1) = 5 stages, matching the data path
    reg [IDX_W-1:0] idx_pipe0, idx_pipe1, idx_pipe2;  

    always @(posedge clk or posedge rst) begin  
        if (rst) begin
            idx_pipe0 <= {IDX_W{1'b0}};     
            idx_pipe1 <= {IDX_W{1'b0}};     
            idx_pipe2 <= {IDX_W{1'b0}};
        end else if (sample_valid) begin   
            idx_pipe0 <= idx_curr;
            idx_pipe1 <= idx_pipe0;  
            idx_pipe2 <= idx_pipe1;
        end
    end

    // bipolar signal and one-sample history
    reg signed [16:0] bip_d;
    reg [IDX_W-1:0]   idx_bip, idx_bip_d;
    reg [7:0]         neg_cnt;  // consecutive negative bipolar samples    
 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bip       <= 17'sd0;
            bip_d     <= 17'sd0;  
            idx_bip   <= {IDX_W{1'b0}};
            idx_bip_d <= {IDX_W{1'b0}};
            neg_cnt   <= 8'd0;  
        end else if (sample_valid) begin
            bip   <= delayed_signed - att_samp_q;
            bip_d <= bip;
   
            idx_bip   <= idx_pipe2;
            idx_bip_d <= idx_bip;  

            // track consecutive negative bipolar samples
            if (event_start)
                neg_cnt <= 8'd0;            
            else if (zc_neg_reg == 8'd0) 
                neg_cnt <= 8'd1;    // no consecutive-negative requirement 
            else if (bip[16]) 
                neg_cnt <= (neg_cnt < 8'd255) ? neg_cnt + 8'd1 : neg_cnt;
            else
                neg_cnt <= 8'd0;
        end
    end

    // zero-crossing detection: bip_d < 0 and bip >= 0 and bip_d != 0  
    wire zc_raw = bip_d[16] && !bip[16] && (bip_d != 17'sd0); 
    assign zc   = zc_raw && ((zc_neg_reg == 8'd0) || (neg_cnt >= zc_neg_reg));

    // threshold arming: zero crossings are ignored until sample_in exceeds threshold
    // This is armed on the undelayed input so it triggers before the bipolar ZC arrives
    reg thresh_armed;
   
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            thresh_armed <= 1'b0;
        end else begin   
            if (event_start)
                thresh_armed <= 1'b0;
            else if (sample_valid && !thresh_armed && (sample_in > thresh_reg))
                thresh_armed <= 1'b1;
        end   
    end

    // pipeline fill blanking: the first 6 bipolar samples use stale pipeline data
    localparam [2:0] FILL_CYCLES = 3'd6;
    reg [2:0] fill_cnt;

    always @(posedge clk or posedge rst) begin  
        if (rst)
            fill_cnt <= 3'd0;
        else if (event_start)  
            fill_cnt <= 3'd0;
        else if (sample_valid && (fill_cnt < FILL_CYCLES))
            fill_cnt <= fill_cnt + 3'd1;
    end   

    wire pipeline_valid = (fill_cnt == FILL_CYCLES);

    // capture the first valid zero crossing per event
    // all five conditions must hold: armed, threshold exceeded, pipeline filled,
    // valid sample present, and zero crossing detected 
    reg hit_armed;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hit_found  <= 1'b0;
            hit_armed  <= 1'b0;
            ca_out     <= 16'd0;
            cb_out     <= 17'sd0;  
            idx_cb_out <= {IDX_W{1'b0}};
        end else begin
            if (event_start) begin
                hit_found <= 1'b0;
                hit_armed <= 1'b1;   
            end
            
            if (hit_armed && thresh_armed && pipeline_valid && sample_valid && zc) begin
                hit_found  <= 1'b1;
                hit_armed  <= 1'b0;  
                ca_out     <= bip[15:0];   // non-negative at ZC
                cb_out     <= bip_d;       // negative before ZC
                idx_cb_out <= idx_bip_d;
            end
        end
    end   
 
endmodule
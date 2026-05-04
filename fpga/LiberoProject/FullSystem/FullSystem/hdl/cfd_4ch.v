///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: SwRI/VT
//   
// File: cfd_4ch.v
// File history:
//      
//   
// Description:     
//
// Four-channel constant fraction discriminator. Receives preprocessed ADC samples on 4 
// channels, detects the first zero crossing on each via cfd_channel_frontend instances, then
// computes fractional timestamps using linear interpolation and a shared serial divider.   
//
// Event protocol:
//   1. sample_valid goes high   -> frontends arm, new event begins.
//   2. sample_valid stays high  -> samples stream in every clock cycle. 
//   3. sample_valid goes low    -> event ends, results captured if FSM is idle.
//   4. If all 4 channels found a crossing, the divider computes frac = (-Cb)/(Ca-Cb) for
//      each channel sequentially, then pulses event_valid with the 4 timestamps.
//      If any channel missed, event_fail pulses instead.
//      If the FSM was still busy from a prior event, event_dropped pulses.
//
// Latency: 46 cycles from event_end to event_valid (1 check + 4*(1 start + 10 div) + 1 pub).
//  
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: VT MDE S26-23  
//
///////////////////////////////////////////////////////////////////////////////////////////////////
    
module cfd_4ch #(
    parameter integer DELAY_RAM_AW      = 7,  
    parameter integer MAX_EVENT_SAMPLES = 1024,
    parameter integer IDX_W             = 10,  
    parameter integer FRAC_BITS         = 10
)(
    input  wire                  clk,
    input  wire                  rst,
  
    input  wire                  sample_valid,
    input  wire signed [15:0]    x1_in,  
    input  wire signed [15:0]    x2_in,
    input  wire signed [15:0]    y1_in,     
    input  wire signed [15:0]    y2_in,

    // runtime configuration (must be stable before sample_valid rises)
    input  wire [13:0]                  att_q0_13,
    input  wire [DELAY_RAM_AW-1:0]      delay_val,   
    input  wire signed [15:0]           threshold,
    input  wire [7:0]                   zc_neg_samples,   
  
    // event timestamp tag (registered on event_start, output with result) 
    input  wire [63:0]           tag_in,  

    // timestamps, all valid on the event_valid pulse
    output reg  [IDX_W-1:0]      tpx1_int,
    output reg  [FRAC_BITS-1:0]  tpx1_frac,    
    output reg  [IDX_W-1:0]      tpx2_int,   
    output reg  [FRAC_BITS-1:0]  tpx2_frac,  
    output reg  [IDX_W-1:0]      tpy1_int,
    output reg  [FRAC_BITS-1:0]  tpy1_frac,
    output reg  [IDX_W-1:0]      tpy2_int,
    output reg  [FRAC_BITS-1:0]  tpy2_frac,

    output reg                   event_valid,
    output reg                   event_fail,
    output reg                   event_dropped,  
    output reg  [63:0]           tag_out
);
  
    localparam [2:0] S_WAIT      = 3'd0,
                     S_CHECK     = 3'd1,  
                     S_DIV_START = 3'd2,
                     S_DIV_WAIT  = 3'd3,
                     S_OUTPUT   = 3'd4;  

    reg [2:0] state;   
    reg [1:0] ch_cnt;
  
    // delayed sample_valid, used for event boundary detection  
    reg sv_d;
  
    always @(posedge clk or posedge rst) begin
        if (rst)
            sv_d <= 1'b0;
        else
            sv_d <= sample_valid;  
    end

    wire event_start = sample_valid & ~sv_d;
    wire event_end   = sv_d & ~sample_valid;
      
    // tag register, captured every event_start regardless of FSM state
    reg [63:0] tag_live;
    
    always @(posedge clk or posedge rst) begin     
        if (rst)
            tag_live <= 64'd0;
        else if (event_start)
            tag_live <= tag_in;
    end  

    // four single-channel CFD frontends
    wire               fe_hit [0:3];
    wire [15:0]        fe_ca  [0:3];
    wire signed [16:0] fe_cb  [0:3];
    wire [IDX_W-1:0]   fe_idx [0:3];  
    wire signed [16:0] fe_bip [0:3];
    wire               fe_zc  [0:3];
        
    cfd_channel_frontend #(
        .DELAY_RAM_AW     (DELAY_RAM_AW),
        .MAX_EVENT_SAMPLES(MAX_EVENT_SAMPLES),  
        .IDX_W            (IDX_W),
        .FRAC_BITS        (FRAC_BITS) 
    ) fe_x1 (
        .clk           (clk), 
        .rst           (rst), 
        .sample_valid  (sample_valid),
        .event_start   (event_start),
        .sample_in     (x1_in),  
        .att_q0_13     (att_q0_13),
        .delay_val     (delay_val),
        .threshold     (threshold),
        .zc_neg_samples(zc_neg_samples),  
        .hit_found     (fe_hit[0]),
        .ca_out        (fe_ca[0]),
        .cb_out        (fe_cb[0]),
        .idx_cb_out    (fe_idx[0]),  
        .bip           (fe_bip[0]),    
        .zc            (fe_zc[0])      
    );

    cfd_channel_frontend #(
        .DELAY_RAM_AW     (DELAY_RAM_AW),
        .MAX_EVENT_SAMPLES(MAX_EVENT_SAMPLES),  
        .IDX_W            (IDX_W),
        .FRAC_BITS        (FRAC_BITS)
    ) fe_x2 ( 
        .clk           (clk),
        .rst           (rst),
        .sample_valid  (sample_valid),     
        .event_start   (event_start),
        .sample_in     (x2_in),     
        .att_q0_13     (att_q0_13),
        .delay_val     (delay_val),
        .threshold     (threshold),
        .zc_neg_samples(zc_neg_samples),
        .hit_found     (fe_hit[1]),
        .ca_out        (fe_ca[1]),
        .cb_out        (fe_cb[1]),  
        .idx_cb_out    (fe_idx[1]),
        .bip           (fe_bip[1]),
        .zc            (fe_zc[1]) 
    );
  
    cfd_channel_frontend #(
        .DELAY_RAM_AW     (DELAY_RAM_AW),
        .MAX_EVENT_SAMPLES(MAX_EVENT_SAMPLES),
        .IDX_W            (IDX_W),
        .FRAC_BITS        (FRAC_BITS)
    ) fe_y1 (
        .clk           (clk),
        .rst           (rst),
        .sample_valid  (sample_valid),
        .event_start   (event_start),
        .sample_in     (y1_in),
        .att_q0_13     (att_q0_13),
        .delay_val     (delay_val),
        .threshold     (threshold),   
        .zc_neg_samples(zc_neg_samples),
        .hit_found     (fe_hit[2]),
        .ca_out        (fe_ca[2]),
        .cb_out        (fe_cb[2]),
        .idx_cb_out    (fe_idx[2]),
        .bip           (fe_bip[2]),
        .zc            (fe_zc[2])
    );

    cfd_channel_frontend #(
        .DELAY_RAM_AW     (DELAY_RAM_AW),
        .MAX_EVENT_SAMPLES(MAX_EVENT_SAMPLES),
        .IDX_W            (IDX_W),
        .FRAC_BITS        (FRAC_BITS)
    ) fe_y2 (
        .clk           (clk),
        .rst           (rst),
        .sample_valid  (sample_valid),
        .event_start   (event_start),
        .sample_in     (y2_in), 
        .att_q0_13     (att_q0_13),
        .delay_val     (delay_val),
        .threshold     (threshold),
        .zc_neg_samples(zc_neg_samples),
        .hit_found     (fe_hit[3]),   
        .ca_out        (fe_ca[3]),
        .cb_out        (fe_cb[3]),
        .idx_cb_out    (fe_idx[3]),
        .bip           (fe_bip[3]),
        .zc            (fe_zc[3])
    );
  
    // Holding registers: capture frontend results on event_end when FSM is idle.   
    // If FSM is busy, registers are not overwritten and event_dropped fires instead.  
    // Due to minimum event length (64 cycles) events should not be dropped due to this
    // in normal operation
    reg [15:0]        hold_ca  [0:3];
    reg signed [16:0] hold_cb  [0:3];
    reg [IDX_W-1:0]   hold_idx [0:3];
    reg               hold_all_hit;
    reg [63:0]        hold_tag;
 
    integer ch;
  
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (ch = 0; ch < 4; ch = ch + 1) begin
                hold_ca[ch]  <= 16'd0;
                hold_cb[ch]  <= 17'sd0;
                hold_idx[ch] <= {IDX_W{1'b0}};
            end
            hold_all_hit <= 1'b0;
            hold_tag     <= 64'd0;
        end else if (event_end && (state == S_WAIT)) begin
            for (ch = 0; ch < 4; ch = ch + 1) begin
                hold_ca[ch]  <= fe_ca[ch];
                hold_cb[ch]  <= fe_cb[ch];   
                hold_idx[ch] <= fe_idx[ch];
            end
            hold_all_hit <= fe_hit[0] & fe_hit[1] & fe_hit[2] & fe_hit[3];
            hold_tag     <= tag_live;
        end
    end

    // channel mux for divider input  
    reg [15:0]        sel_ca;
    reg signed [16:0] sel_cb;
    reg [IDX_W-1:0]   sel_idx;

    always @(*) begin  
        case (ch_cnt)
            2'd0:    begin sel_ca = hold_ca[0]; sel_cb = hold_cb[0]; sel_idx = hold_idx[0]; end
            2'd1:    begin sel_ca = hold_ca[1]; sel_cb = hold_cb[1]; sel_idx = hold_idx[1]; end 
            2'd2:    begin sel_ca = hold_ca[2]; sel_cb = hold_cb[2]; sel_idx = hold_idx[2]; end     
            default: begin sel_ca = hold_ca[3]; sel_cb = hold_cb[3]; sel_idx = hold_idx[3]; end
        endcase
    end 

    // divider operands: frac = (-Cb) / (Ca - Cb)  
    wire signed [16:0] ca_wide   = {1'b0, sel_ca};
    wire [16:0]        div_num_w = sel_cb[16] ? $unsigned(-sel_cb) : 17'd0;
    wire [16:0]        div_den_w = $unsigned(ca_wide - sel_cb);

    // shared serial divider
    reg                  div_start;
    wire                 div_busy;
    wire                 div_done;
    wire [FRAC_BITS-1:0] div_q;

    serial_frac_div #(
        .W        (17),
        .FRAC_BITS(FRAC_BITS)  
    ) u_div (   
        .clk  (clk),
        .rst  (rst),
        .start(div_start),
        .num  (div_num_w),
        .den  (div_den_w),
        .busy (div_busy),
        .done (div_done),
        .q    (div_q)
    );

    // main state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= S_WAIT;
            ch_cnt        <= 2'd0;
            div_start     <= 1'b0;  
            event_valid   <= 1'b0;
            event_fail    <= 1'b0;
            event_dropped <= 1'b0;
            tag_out       <= 64'd0;
            tpx1_int  <= {IDX_W{1'b0}};
            tpx1_frac <= {FRAC_BITS{1'b0}};
            tpx2_int  <= {IDX_W{1'b0}};    
            tpx2_frac <= {FRAC_BITS{1'b0}};    
            tpy1_int  <= {IDX_W{1'b0}};  
            tpy1_frac <= {FRAC_BITS{1'b0}};       
            tpy2_int  <= {IDX_W{1'b0}};
            tpy2_frac <= {FRAC_BITS{1'b0}};
        end else begin
            event_valid   <= 1'b0;
            event_fail    <= 1'b0;
            event_dropped <= 1'b0;
            div_start     <= 1'b0;

            // event dropped if a new event ends while we're still busy
            if (event_end && (state != S_WAIT)) begin
                event_dropped <= 1'b1;   
                tag_out       <= tag_live;
            end

            case (state)
                S_WAIT: begin
                    if (event_end)   
                        state <= S_CHECK;
                end

                S_CHECK: begin
                    if (hold_all_hit) begin 
                        state  <= S_DIV_START;
                        ch_cnt <= 2'd0;
                    end else begin
                        state <= S_OUTPUT;
                    end
                end 
  
                S_DIV_START: begin 
                    div_start <= 1'b1;  
                    state     <= S_DIV_WAIT;
                end

                S_DIV_WAIT: begin
                    if (div_done) begin
                        // capture timestamp for this channel
                        case (ch_cnt)
                            2'd0: begin tpx1_int <= sel_idx; tpx1_frac <= div_q; end
                            2'd1: begin tpx2_int <= sel_idx; tpx2_frac <= div_q; end
                            2'd2: begin tpy1_int <= sel_idx; tpy1_frac <= div_q; end
                            2'd3: begin tpy2_int <= sel_idx; tpy2_frac <= div_q; end  
                            default: ;
                        endcase

                        if (ch_cnt == 2'd3)
                            state <= S_OUTPUT;
                        else begin
                            ch_cnt <= ch_cnt + 2'd1;
                            state  <= S_DIV_START;
                        end
                    end
                end

                S_OUTPUT: begin
                    tag_out <= hold_tag;

                    if (hold_all_hit)   
                        event_valid <= 1'b1;
                    else
                        event_fail <= 1'b1;
                
                    state <= S_WAIT; 
                end

                default: state <= S_WAIT;
            endcase 
        end
    end

endmodule

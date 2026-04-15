// =============================================================================
// ASOC v3 – ADC Channel Behavioral Model
// -----------------------------------------------------------------------------
// Models one of the 4 high-speed ADC channels.
//
//  • Accepts 4 time-interleaved real-valued analog inputs (RFin[3:0]).
//  • Quantises each sample to ADC_BITS (12-bit default).
//  • Writes samples into a 16k-deep sample buffer (ping-pong protected).
//  • Raises done_flag when CAPTURE_DEPTH samples have been collected.
//  • Buffer is read back word-by-word via rd_addr / rd_data ports (used by
//    the LVDS serialiser / readout controller).
//
// Sampling rate (behavioural):  one sample every rising edge of adc_clk.
// The 4 interleaved sub-inputs are applied on consecutive adc_clk cycles
// before the host sends the next Acquire pulse.
// =============================================================================

`timescale 1ns/1ps

module asoc_v3_adc_channel #(
    parameter ADC_BITS      = 12,             // resolution
    parameter BUFFER_DEPTH  = 16384,          // 16k samples per channel
    parameter ADDR_W        = 14,             // log2(BUFFER_DEPTH)
    parameter VREF_POS      = 1.0,            // positive full-scale (V)
    parameter VREF_NEG      = -1.0            // negative full-scale (V)
)(
    // Clocks & resets
    input  wire                 adc_clk,      // high-speed sampling clock
    input  wire                 sys_clk,      // slower system / readout clock
    input  wire                 rst_n,        // active-low synchronous reset

    // Analog inputs (4 time-interleaved sub-channels, real in simulation)
    input  real                 rfin_0,       // sub-channel A
    input  real                 rfin_1,       // sub-channel B
    input  real                 rfin_2,       // sub-channel C
    input  real                 rfin_3,       // sub-channel D

    // Control
    input  wire                 acquire,      // rising-edge starts capture
    output reg                  data_ready,   // high when buffer full

    // Readout port (sys_clk domain)
    input  wire [ADDR_W-1:0]   rd_addr,
    output reg  [ADC_BITS-1:0] rd_data,

    // Status
    output reg  [ADDR_W-1:0]   sample_count
);

    // -------------------------------------------------------------------------
    // Internal sample buffer  (reg array – behavioural RAM)
    // -------------------------------------------------------------------------
    reg [ADC_BITS-1:0] sample_buf [0:BUFFER_DEPTH-1];

    // Write pointer, acquisition state
    reg [ADDR_W-1:0]   wr_ptr;
    reg [1:0]          sub_ch_sel;   // selects which of 4 sub-channels
    reg                acquiring;
    reg                acquire_prev;

    // -------------------------------------------------------------------------
    // Helper: quantise a real voltage to ADC_BITS two's-complement integer
    // -------------------------------------------------------------------------
    function automatic [ADC_BITS-1:0] quantise;
        input real vin;
        real       clamped, normalised;
        integer    raw;
        begin
            // Clamp to full-scale
            if (vin > VREF_POS)      clamped = VREF_POS;
            else if (vin < VREF_NEG) clamped = VREF_NEG;
            else                     clamped = vin;

            // Map [-1,+1] V → [-(2^(N-1)), +(2^(N-1)-1)]
            normalised = (clamped - VREF_NEG) / (VREF_POS - VREF_NEG);
            raw        = $rtoi(normalised * ((1 << ADC_BITS) - 1)) - (1 << (ADC_BITS-1));

            // Wrap into ADC_BITS two's complement
            quantise = raw[ADC_BITS-1:0];
        end
    endfunction

    // -------------------------------------------------------------------------
    // Select current sub-channel analog value
    // -------------------------------------------------------------------------
    real cur_sample;
    always @(*) begin
        case (sub_ch_sel)
            2'd0: cur_sample = rfin_0;
            2'd1: cur_sample = rfin_1;
            2'd2: cur_sample = rfin_2;
            2'd3: cur_sample = rfin_3;
        endcase
    end

    // -------------------------------------------------------------------------
    // Acquisition FSM  (adc_clk domain)
    // -------------------------------------------------------------------------
    always @(posedge adc_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr       <= {ADDR_W{1'b0}};
            sub_ch_sel   <= 2'd0;
            acquiring    <= 1'b0;
            acquire_prev <= 1'b0;
            data_ready   <= 1'b0;
            sample_count <= {ADDR_W{1'b0}};
        end else begin
            acquire_prev <= acquire;

            // Rising edge of acquire → start new capture
            if (acquire && !acquire_prev) begin
                wr_ptr     <= {ADDR_W{1'b0}};
                sub_ch_sel <= 2'd0;
                acquiring  <= 1'b1;
                data_ready <= 1'b0;
            end

            if (acquiring) begin
                // Write quantised sample into buffer
                sample_buf[wr_ptr] <= quantise(cur_sample);

                sub_ch_sel <= sub_ch_sel + 2'd1;

                if (wr_ptr == BUFFER_DEPTH - 1) begin
                    // Buffer full
                    acquiring    <= 1'b0;
                    data_ready   <= 1'b1;
                    sample_count <= BUFFER_DEPTH[ADDR_W-1:0];
                    wr_ptr       <= {ADDR_W{1'b0}};
                end else begin
                    wr_ptr <= wr_ptr + 1'b1;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Synchronous read port  (sys_clk domain)
    // -------------------------------------------------------------------------
    always @(posedge sys_clk) begin
        rd_data <= sample_buf[rd_addr];
    end

endmodule

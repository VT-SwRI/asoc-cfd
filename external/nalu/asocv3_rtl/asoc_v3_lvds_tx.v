// =============================================================================
// ASOC v3 – LVDS Transmitter / Serialiser
// -----------------------------------------------------------------------------
// Reads back digitised samples from one ADC channel's buffer and serialises
// them onto a pair of single-ended wires that represent an LVDS pair
// (TxOut_p / TxOut_n) together with the associated clock (TxClkOut_p/n).
//
// Protocol:
//   • One 12-bit ADC word is serialised MSB-first per burst.
//   • The companion clock toggles at the serial bit rate.
//   • A 4-bit header (4'hA = start-of-frame marker) is prepended to each word,
//     giving 16 serial bits per sample word (header + 12 data bits).
//   • After all BUFFER_DEPTH words are sent, the serialiser de-asserts tx_active.
//
// Clock domain:
//   • ser_clk  – serial clock (target ≥12× adc_clk / BUFFER_DEPTH throughput).
//   • sys_clk  – control / buffer-read clock.
// =============================================================================

`timescale 1ns/1ps

module asoc_v3_lvds_tx #(
    parameter ADC_BITS     = 12,
    parameter BUFFER_DEPTH = 16384,
    parameter ADDR_W       = 14,
    parameter FRAME_BITS   = 16              // 4-bit header + 12-bit data
)(
    input  wire                 sys_clk,
    input  wire                 ser_clk,     // high-speed serial clock
    input  wire                 rst_n,

    // Trigger
    input  wire                 data_ready,  // from ADC channel
    output reg                  tx_active,

    // Buffer read port (into ADC channel)
    output reg  [ADDR_W-1:0]   rd_addr,
    input  wire [ADC_BITS-1:0] rd_data,

    // Physical outputs (single-ended representing differential pair)
    output reg                  tx_p,        // TxOut_p
    output reg                  tx_n,        // TxOut_n
    output reg                  clk_p,       // TxClkOut_p
    output reg                  clk_n        // TxClkOut_n
);

    // -------------------------------------------------------------------------
    // State machine
    // -------------------------------------------------------------------------
    localparam ST_IDLE   = 2'd0;
    localparam ST_LATCH  = 2'd1;   // fetch word from buffer
    localparam ST_SEND   = 2'd2;   // shift out frame
    localparam ST_DONE   = 2'd3;

    reg [1:0]             state;
    reg [ADDR_W-1:0]      word_cnt;
    reg [FRAME_BITS-1:0]  shift_reg;
    reg [$clog2(FRAME_BITS)-1:0] bit_cnt;
    reg                   dr_prev;

    // SOF header
    localparam [3:0] SOF = 4'hA;

    // -------------------------------------------------------------------------
    // LVDS clock generation: toggle clk_p on every ser_clk edge
    // -------------------------------------------------------------------------
    always @(posedge ser_clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_p <= 1'b0;
            clk_n <= 1'b1;
        end else if (tx_active) begin
            clk_p <= ~clk_p;
            clk_n <=  clk_p;   // complement of previous value
        end
    end

    // -------------------------------------------------------------------------
    // Readout FSM  (ser_clk domain)
    // -------------------------------------------------------------------------
    always @(posedge ser_clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= ST_IDLE;
            word_cnt  <= {ADDR_W{1'b0}};
            bit_cnt   <= {$clog2(FRAME_BITS){1'b0}};
            shift_reg <= {FRAME_BITS{1'b0}};
            rd_addr   <= {ADDR_W{1'b0}};
            tx_p      <= 1'b0;
            tx_n      <= 1'b1;
            tx_active <= 1'b0;
            dr_prev   <= 1'b0;
        end else begin
            dr_prev <= data_ready;

            case (state)
                // ----------------------------------------------------------
                ST_IDLE: begin
                    tx_active <= 1'b0;
                    tx_p      <= 1'b0;
                    tx_n      <= 1'b1;
                    // Rising edge of data_ready → start readout
                    if (data_ready && !dr_prev) begin
                        word_cnt  <= {ADDR_W{1'b0}};
                        rd_addr   <= {ADDR_W{1'b0}};
                        tx_active <= 1'b1;
                        state     <= ST_LATCH;
                    end
                end

                // ----------------------------------------------------------
                // Latch one sample word (allow one clock for buffer read)
                ST_LATCH: begin
                    rd_addr   <= word_cnt;
                    state     <= ST_SEND;
                    // Pre-load frame: [SOF | ADC word]
                    shift_reg <= {SOF, rd_data};
                    bit_cnt   <= FRAME_BITS - 1;
                end

                // ----------------------------------------------------------
                // Shift out FRAME_BITS bits MSB-first
                ST_SEND: begin
                    tx_p      <= shift_reg[FRAME_BITS-1];
                    tx_n      <= ~shift_reg[FRAME_BITS-1];
                    shift_reg <= {shift_reg[FRAME_BITS-2:0], 1'b0};

                    if (bit_cnt == 0) begin
                        // End of word
                        if (word_cnt == BUFFER_DEPTH - 1) begin
                            state <= ST_DONE;
                        end else begin
                            word_cnt <= word_cnt + 1'b1;
                            state    <= ST_LATCH;
                        end
                    end else begin
                        bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                // ----------------------------------------------------------
                ST_DONE: begin
                    tx_active <= 1'b0;
                    tx_p      <= 1'b0;
                    tx_n      <= 1'b1;
                    clk_p     <= 1'b0;
                    clk_n     <= 1'b1;
                    state     <= ST_IDLE;
                end
            endcase
        end
    end

endmodule

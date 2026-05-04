`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// uart_config_fsm.v
//
// FSM that accepts a 149-bit packed word (already assembled by the UART
// module) and latches it into individual DSP-pipeline configuration registers.
//
// Packed bit layout (bit 148 is MSB, received first):
//
//  Bits        Width  Field
//  ---------   -----  --------------------------------------------------
//  [148:135]    14    Attenuation    ? Q0.13 signed
//  [134:128]     7    Delay          ? Unsigned integer (1?127)
//  [127:112]    16    Threshold      ? SQ12.3 signed
//  [111:104]     8    ZC Neg Samples ? Unsigned integer
//  [103: 84]    20    Kx             ? UQ1.19 unsigned
//  [ 83: 64]    20    Ky             ? UQ1.19 unsigned
//  [ 63:  0]    64    Timestamp      ? 64-bit unsigned
//  ---------   -----  --------------------------------------------------
//                149 bits total
//
// Operation:
//   1. IDLE   ? waits for rx_valid (indicates the 149-bit word is ready)
//   2. LATCH  ? slices the packed word into individual registers
//   3. DONE   ? asserts cfg_valid for one cycle, then returns to IDLE
//
//////////////////////////////////////////////////////////////////////////////

module uart_config_fsm (
    input  wire          clk,
    input  wire          rst,

    // Packed input from UART assembler
    input  wire [150:0]  rx_packed,
    input  wire          rx_valid,    // single-cycle pulse: rx_packed is valid

    // DSP parameter outputs
    output reg  [13:0]   attenuation,    // Q0.13 signed
    output reg  [ 6:0]   delay,          // unsigned, 1?127
    output reg  [15:0]   threshold,      // SQ12.3 signed
    output reg  [ 7:0]   zc_neg_samples, // unsigned
    output reg  [19:0]   kx,             // UQ1.19 unsigned
    output reg  [19:0]   ky,             // UQ1.19 unsigned
    output reg  [63:0]   timestamp,      // 64-bit unsigned
    output reg           sel,
    output reg           start_stop,
    output reg           cfg_valid
);

    // -----------------------------------------------------------------------
    // State encoding
    // -----------------------------------------------------------------------
    localparam [1:0] S_IDLE  = 2'b00,
                     S_LATCH = 2'b01,
                     S_DONE  = 2'b10;

    reg [1:0] state, state_next;

    // -----------------------------------------------------------------------
    // State register
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= S_IDLE;
        else
            state <= state_next;
    end

    // -----------------------------------------------------------------------
    // Next-state logic
    // -----------------------------------------------------------------------
    always @(*) begin
        state_next = state;
        case (state)
            S_IDLE:  if (rx_valid) state_next = S_LATCH;
            S_LATCH: state_next = S_DONE;
            S_DONE:  state_next = S_IDLE;
            default: state_next = S_IDLE;
        endcase
    end

    // -----------------------------------------------------------------------
    // Output / datapath logic
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sel            <= 1'b0;
            start_stop     <= 1'b0;
            attenuation    <= 14'd0;
            delay          <=  7'd0;
            threshold      <= 16'd0;
            zc_neg_samples <=  8'd0;
            kx             <= 20'd0;
            ky             <= 20'd0;
            timestamp      <= 64'd0;
            cfg_valid      <=  1'b0;
        end else begin
            cfg_valid <= 1'b0;  // default: deassert

            case (state)
                S_LATCH: begin
                    start_stop     <= rx_packed[150];                    
                    sel            <= rx_packed[149];
                    attenuation    <= rx_packed[148:135];
                    delay          <= rx_packed[134:128];
                    threshold      <= rx_packed[127:112];
                    zc_neg_samples <= rx_packed[111:104];
                    kx             <= rx_packed[103: 84];
                    ky             <= rx_packed[ 83: 64];
                    timestamp      <= rx_packed[ 63:  0];
                end

                S_DONE: begin
                    cfg_valid <= 1'b1;
                end

                default: ;  // S_IDLE ? hold values
            endcase
        end
    end

endmodule
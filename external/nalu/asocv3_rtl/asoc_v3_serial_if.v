// =============================================================================
// ASOC v3 – Serial Configuration & Readout Interface
// -----------------------------------------------------------------------------
// Models the 4-wire daisy-chain serial bus (SdA_B..SdD_B, pins 19-22).
//
// Protocol (simplified SPI-like, MSB-first):
//   • SdA_B = SCLK  (serial clock, input)
//   • SdB_B = MOSI  (master→chip, input during config writes)
//   • SdC_B = MISO  (chip→master, output during readback)
//   • SdD_B = CS_N  (chip-select, active low, input)
//
// Register map (8-bit address → 16-bit data):
//   0x00  CTRL      : bit[0]=soft_acquire, bit[1]=readout_mode,
//                     bit[3:2]=ch_select (0-3)
//   0x01  STATUS    : bit[0]=data_ready (RO), bit[1]=acquiring (RO)
//   0x02  RD_ADDR_L : lower 8 bits of sample read address
//   0x03  RD_ADDR_H : upper 6 bits of sample read address
//   0x04  RD_DATA   : 12-bit sample data from selected channel (RO)
//   0x05  SAMPLE_CNT: number of captured samples (RO)
//   0x06  THRESH_L  : capture depth threshold, low byte (RW)
//   0x07  THRESH_H  : capture depth threshold, high byte (RW)
//
// Frame structure (32 bits total):
//   [31]    = R/W̄  (1=read, 0=write)
//   [30:23] = 8-bit register address
//   [22:7]  = 16-bit write data (don't-care for reads)
//   [6:0]   = padding/reserved
// =============================================================================

`timescale 1ns/1ps

module asoc_v3_serial_if #(
    parameter ADC_BITS = 12,
    parameter ADDR_W   = 14
)(
    input  wire                  sys_clk,
    input  wire                  rst_n,

    // Physical pins (SdX_B)
    input  wire                  sclk,      // SdA_B
    input  wire                  mosi,      // SdB_B
    output reg                   miso,      // SdC_B
    input  wire                  cs_n,      // SdD_B

    // Internal control outputs
    output reg                   soft_acquire,
    output reg  [1:0]            ch_select,
    output reg  [ADDR_W-1:0]    rd_addr,
    input  wire [ADC_BITS-1:0]  rd_data,     // from selected ADC channel

    // Status inputs
    input  wire [3:0]            data_ready,  // one bit per channel
    input  wire [ADDR_W-1:0]    sample_count,

    // Decoded outputs for test visibility
    output reg  [7:0]            reg_addr_out,
    output reg  [15:0]           reg_data_out,
    output reg                   reg_wr_out
);

    // -------------------------------------------------------------------------
    // Register file
    // -------------------------------------------------------------------------
    reg [15:0] regfile [0:15];

    // Named aliases into regfile
    wire [15:0] ctrl_reg      = regfile[8'h00];
    // regfile[0x01] is STATUS (read-only, assembled on the fly)
    // regfile[0x02..03] = rd_addr
    // regfile[0x04] = rd_data (RO)
    // regfile[0x05] = sample_count (RO)
    // regfile[0x06..07] = threshold

    // -------------------------------------------------------------------------
    // SPI shift register (32-bit frames)
    // -------------------------------------------------------------------------
    reg [31:0] shift_reg;
    reg [5:0]  bit_cnt;
    reg        sclk_prev;
    reg        frame_done;

    // Decode pipeline registers
    reg        do_decode;
    reg        dec_rw;
    reg [7:0]  dec_addr;
    reg [15:0] dec_wr_data;

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg   <= 32'h0;
            bit_cnt     <= 6'd0;
            sclk_prev   <= 1'b0;
            frame_done  <= 1'b0;
            miso        <= 1'b0;
            soft_acquire <= 1'b0;
            ch_select   <= 2'b00;
            rd_addr     <= {ADDR_W{1'b0}};
            reg_wr_out   <= 1'b0;
            reg_addr_out <= 8'h0;
            reg_data_out <= 16'h0;
            do_decode    <= 1'b0;
            dec_rw       <= 1'b0;
            dec_addr     <= 8'h0;
            dec_wr_data  <= 16'h0;
        end else begin
            frame_done <= 1'b0;
            reg_wr_out <= 1'b0;
            sclk_prev  <= sclk;

            if (!cs_n) begin
                // Rising edge of SCLK → shift in MOSI
                if (sclk && !sclk_prev) begin
                    shift_reg <= {shift_reg[30:0], mosi};
                    bit_cnt   <= bit_cnt + 1'b1;

                    if (bit_cnt == 6'd31)
                        frame_done <= 1'b1;
                end

                // Falling edge → drive MISO (MSB of shift register)
                if (!sclk && sclk_prev)
                    miso <= shift_reg[31];

            end else begin
                bit_cnt <= 6'd0;
            end

            // ---------------------------------------------------------------
            // Decode completed frame
            // ---------------------------------------------------------------
            if (frame_done) begin
                dec_rw      <= shift_reg[31];
                dec_addr    <= shift_reg[30:23];
                dec_wr_data <= shift_reg[22:7];
                do_decode   <= 1'b1;
            end

            // Execute decoded frame one cycle later (regs now valid)
            if (do_decode) begin
                do_decode    <= 1'b0;
                reg_addr_out <= dec_addr;
                reg_data_out <= dec_wr_data;
                reg_wr_out   <= ~dec_rw;

                if (!dec_rw) begin
                    // Write cycle
                    regfile[dec_addr[3:0]] <= dec_wr_data;

                    case (dec_addr)
                        8'h00: begin
                            soft_acquire <= dec_wr_data[0];
                            ch_select    <= dec_wr_data[3:2];
                        end
                        8'h02: rd_addr[7:0]           <= dec_wr_data[7:0];
                        8'h03: rd_addr[ADDR_W-1:8]    <= dec_wr_data[ADDR_W-9:0];
                        default: ;
                    endcase
                end else begin
                    // Read cycle – preload shift register for next frame output
                    case (dec_addr)
                        8'h00: shift_reg[31:16] <= regfile[4'h0];
                        8'h01: shift_reg[31:16] <= {11'b0, data_ready};
                        8'h02: shift_reg[31:16] <= {8'h0, rd_addr[7:0]};
                        8'h03: shift_reg[31:16] <= {2'h0, rd_addr[ADDR_W-1:8]};
                        8'h04: shift_reg[31:16] <= {4'h0, rd_data};
                        8'h05: shift_reg[31:16] <= {2'h0, sample_count};
                        default: shift_reg[31:16] <= regfile[dec_addr[3:0]];
                    endcase
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Initialise register file at power-on
    // -------------------------------------------------------------------------
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1)
            regfile[i] = 16'h0000;
        regfile[8'h06] = 16'hFFFF;   // default capture depth = max
        regfile[8'h07] = 16'h003F;
    end

endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: uart_packet_parser.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 


`timescale 1ns/1ps

module uart_packet_parser #(
    parameter integer MAX_SAMPLES = 1024,
    parameter integer MIN_SAMPLES = 1
)(
    input  wire        i_clk,
    input  wire        i_rst,

    input  wire [7:0]  i_rx_byte,
    input  wire        i_rx_dv,

    output reg         o_busy,
    output reg         o_proto_err,

    output reg         o_wr_en,
    output reg [15:0]  o_wr_addr,
    output reg [11:0]  o_wr_x1,
    output reg [11:0]  o_wr_x2,
    output reg [11:0]  o_wr_y1,
    output reg [11:0]  o_wr_y2,

    output reg [15:0]  o_sample_count,
    output reg         o_event_commit
);

    localparam [7:0] HEADER_BYTE = 8'hAA;
    localparam [7:0] FOOTER_BYTE = 8'h55;

    localparam [2:0]
        S_IDLE        = 3'd0,
        S_CNT_HI      = 3'd1,
        S_CNT_LO      = 3'd2,
        S_RX_SAMPLE   = 3'd3,
        S_WAIT_FOOTER = 3'd4;

    reg [2:0]  r_state;
    reg [15:0] r_sample_count;
    reg [15:0] r_samples_written;
    reg [2:0]  r_byte_idx;

    reg [3:0]  r_x1_hi, r_x2_hi, r_y1_hi, r_y2_hi;
    reg [7:0]  r_x1_lo, r_x2_lo, r_y1_lo;

    wire [15:0] w_count_candidate = {o_sample_count[15:8], i_rx_byte};

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            r_state           <= S_IDLE;
            r_sample_count    <= 16'd0;
            r_samples_written <= 16'd0;
            r_byte_idx        <= 3'd0;

            r_x1_hi <= 4'd0; r_x2_hi <= 4'd0; r_y1_hi <= 4'd0; r_y2_hi <= 4'd0;
            r_x1_lo <= 8'd0; r_x2_lo <= 8'd0; r_y1_lo <= 8'd0;

            o_busy         <= 1'b0;
            o_proto_err    <= 1'b0;
            o_wr_en        <= 1'b0;
            o_wr_addr      <= 16'd0;
            o_wr_x1        <= 12'd0;
            o_wr_x2        <= 12'd0;
            o_wr_y1        <= 12'd0;
            o_wr_y2        <= 12'd0;
            o_sample_count <= 16'd0;
            o_event_commit <= 1'b0;
        end else begin
            o_proto_err    <= 1'b0;
            o_wr_en        <= 1'b0;
            o_event_commit <= 1'b0;

            case (r_state)
                S_IDLE: begin
                    o_busy <= 1'b0;

                    if (i_rx_dv && (i_rx_byte == HEADER_BYTE)) begin
                        o_busy            <= 1'b1;
                        o_sample_count    <= 16'd0;
                        r_sample_count    <= 16'd0;
                        r_samples_written <= 16'd0;
                        r_byte_idx        <= 3'd0;
                        r_state           <= S_CNT_HI;
                    end
                end

                S_CNT_HI: begin
                    if (i_rx_dv) begin
                        o_sample_count[15:8] <= i_rx_byte;
                        r_state              <= S_CNT_LO;
                    end
                end

                S_CNT_LO: begin
                    if (i_rx_dv) begin
                        o_sample_count[7:0] <= i_rx_byte;
                        r_sample_count      <= w_count_candidate;
                        r_samples_written   <= 16'd0;
                        r_byte_idx          <= 3'd0;

                        if ((w_count_candidate < MIN_SAMPLES[15:0]) ||
                            (w_count_candidate > MAX_SAMPLES[15:0])) begin
                            o_proto_err <= 1'b1;
                            o_busy      <= 1'b0;
                            r_state     <= S_IDLE;
                        end else begin
                            r_state <= S_RX_SAMPLE;
                        end
                    end
                end

                S_RX_SAMPLE: begin
                    if (i_rx_dv) begin
                        case (r_byte_idx)
                            3'd0: begin
                                r_x1_hi    <= i_rx_byte[3:0];
                                r_byte_idx <= 3'd1;
                            end

                            3'd1: begin
                                r_x1_lo    <= i_rx_byte;
                                r_byte_idx <= 3'd2;
                            end

                            3'd2: begin
                                r_x2_hi    <= i_rx_byte[3:0];
                                r_byte_idx <= 3'd3;
                            end

                            3'd3: begin
                                r_x2_lo    <= i_rx_byte;
                                r_byte_idx <= 3'd4;
                            end

                            3'd4: begin
                                r_y1_hi    <= i_rx_byte[3:0];
                                r_byte_idx <= 3'd5;
                            end

                            3'd5: begin
                                r_y1_lo    <= i_rx_byte;
                                r_byte_idx <= 3'd6;
                            end

                            3'd6: begin
                                r_y2_hi    <= i_rx_byte[3:0];
                                r_byte_idx <= 3'd7;
                            end

                            3'd7: begin
                                o_wr_en   <= 1'b1;
                                o_wr_addr <= r_samples_written;
                                o_wr_x1   <= {r_x1_hi, r_x1_lo};
                                o_wr_x2   <= {r_x2_hi, r_x2_lo};
                                o_wr_y1   <= {r_y1_hi, r_y1_lo};
                                o_wr_y2   <= {r_y2_hi, i_rx_byte};

                                if (r_samples_written == (r_sample_count - 16'd1)) begin
                                    r_byte_idx <= 3'd0;
                                    r_state    <= S_WAIT_FOOTER;
                                end else begin
                                    r_samples_written <= r_samples_written + 16'd1;
                                    r_byte_idx        <= 3'd0;
                                end
                            end

                            default: begin
                                r_byte_idx <= 3'd0;
                            end
                        endcase
                    end
                end

                S_WAIT_FOOTER: begin
                    if (i_rx_dv) begin
                        o_busy <= 1'b0;

                        if (i_rx_byte == FOOTER_BYTE) begin
                            o_event_commit <= 1'b1;
                        end else begin
                            o_proto_err <= 1'b1;
                        end

                        r_state <= S_IDLE;
                    end
                end

                default: begin
                    r_state <= S_IDLE;
                    o_busy  <= 1'b0;
                end
            endcase
        end
    end

endmodule

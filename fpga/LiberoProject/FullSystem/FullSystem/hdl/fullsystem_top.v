///////////////////////////////////////////////////////////////////////////////////////////////////
//
// File: fullsystem_top.v
//
// Description:
//   Top-level integration for the entire detector readout system. Replaces
//   the earlier input-only top (input_top.v) by adding the host UART link,
//   parameter configuration FSM, pattern generator, source mux, bridge FSM,
//   and timestamp generator.
//
//   Three external UART pins:
//     i_uart_data_rx -> packet_parser -> event_buffer -> dsp_pipeline
//                                                              |
//                                                              v
//     i_uart_host_rx -> host_uart RX -> uart_config_fsm  -> dsp params,
//                                                           sel, start_stop,
//                                                           and timestamp seed
//                                                              |
//                                                              v
//                                          mux (sel) <- pattern_generator
//                                                  |
//                                                  v
//                                          bridge_fsm -> host_uart TX -> o_uart_host_tx
//
//   Acquisition is gated by start_stop: it enables both the event_buffer
//   replay (acquire input) and the pattern generator (enable input). Whichever
//   source the GUI selects via `sel` then flows through the mux to the host.
//
//   The 64-bit microsecond timestamp is seeded by the GUI on cfg_valid and
//   then increments locally; the DSP and pattern generator both attach the
//   running value to their event tags.
//
// LED assignments (LEDs 1-7 are pulse-extended for ~1 s @ 40 MHz):
//   LED1 = event_commit  (parser committed an event)
//   LED2 = adc_valid     (event buffer replaying)
//   LED3 = mux_out_dv    (system produced an event output)
//   LED4 = event_missed  (CFD failed on one or more channels)
//   LED5 = pos_rejected  (position outside window)
//   LED6 = cfg_valid     (GUI sent new configuration)
//   LED7 = proto_err     (packet parser protocol error)
//   LED8 = i_rst         (reset asserted; direct, no extender)
//
// Required source files:
//   uart_rx.v, uart_tx.v, uart_packet_parser.v, event_buffer.v,
//   timestamp_generator.v, dsp_pipeline.v, adc_preprocess_4ch.v, cfd_4ch.v,
//   cfd_channel_frontend.v, cfd_delay_line_ram.v, peak_detector_4ch.v,
//   position_calculator.v, serial_frac_div.v, event_builder.v,
//   pattern_generator.v (module pattern_generator), mux_gain_test.v,
//   bridge_fsm.v, uart_config_fsm.v, host_uart.sv (renamed from uart.sv),
//   pulse_extender.v
//
// Required IP:
//   mult_16x14_3p  (SmartGen 16x14 unsigned multiplier, 3-stage pipeline)
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
//
///////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module fullsystem_top #(
    parameter integer CLKS_PER_BIT = 43,    // shared by both UARTs
    parameter integer MAX_SAMPLES  = 1024,
    parameter integer CLK_FREQ_HZ  = 40_000_000
)(
    input  wire i_clk,
    (* syn_noclockbuf = 1 *)
    input  wire i_rst,                       // active-high

    // Data UART: streams ADC test vectors into the packet parser
    input  wire i_uart_data_rx,

    // Host UART: bidirectional GUI link
    input  wire i_uart_host_rx,
    output wire o_uart_host_tx,

    // LEDs
    output wire o_led1,
    output wire o_led2,
    output wire o_led3,
    output wire o_led4,
    output wire o_led5,
    output wire o_led6,
    output wire o_led7,
    output wire o_led8
);

    // =========================================================
    // Configuration registers (driven by uart_config_fsm)
    // =========================================================
    wire [13:0] w_cfg_attenuation;
    wire [6:0]  w_cfg_delay;
    wire [15:0] w_cfg_threshold;
    wire [7:0]  w_cfg_zc_neg_samples;
    wire [19:0] w_cfg_kx;
    wire [19:0] w_cfg_ky;
    wire [63:0] w_cfg_timestamp;
    wire        w_cfg_sel;
    wire        w_cfg_start_stop;
    wire        w_cfg_valid;

    // =========================================================
    // Data UART RX -> packet parser
    // =========================================================
    wire       w_data_rx_dv;
    wire [7:0] w_data_rx_byte;

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_data_rx (
        .i_clk       (i_clk),
        .i_rst       (i_rst),
        .i_rx_serial (i_uart_data_rx),
        .o_rx_dv     (w_data_rx_dv),
        .o_rx_byte   (w_data_rx_byte)
    );

    wire        w_wr_en;
    wire [15:0] w_wr_addr;
    wire [11:0] w_wr_x1, w_wr_x2, w_wr_y1, w_wr_y2;
    wire [15:0] w_sample_count;
    wire        w_event_commit;
    wire        w_parser_busy;
    wire        w_proto_err;

    uart_packet_parser #(
        .MAX_SAMPLES (MAX_SAMPLES),
        .MIN_SAMPLES (1)
    ) u_packet_parser (
        .i_clk          (i_clk),
        .i_rst          (i_rst),
        .i_rx_byte      (w_data_rx_byte),
        .i_rx_dv        (w_data_rx_dv),
        .o_busy         (w_parser_busy),
        .o_proto_err    (w_proto_err),
        .o_wr_en        (w_wr_en),
        .o_wr_addr      (w_wr_addr),
        .o_wr_x1        (w_wr_x1),
        .o_wr_x2        (w_wr_x2),
        .o_wr_y1        (w_wr_y1),
        .o_wr_y2        (w_wr_y2),
        .o_sample_count (w_sample_count),
        .o_event_commit (w_event_commit)
    );

    // =========================================================
    // Event buffer (gated by start_stop via acquire)
    // =========================================================
    wire        w_adc_valid;
    wire [11:0] w_adc_x1, w_adc_x2, w_adc_y1, w_adc_y2;
    wire        w_buf_busy;

    event_buffer #(
        .MAX_SAMPLES (MAX_SAMPLES),
        .IDLE_GAP    (4)
    ) u_event_buffer (
        .i_clk          (i_clk),
        .i_rst          (i_rst),
        .acquire        (w_cfg_start_stop),
        .i_wr_en        (w_wr_en),
        .i_wr_addr      (w_wr_addr),
        .i_wr_x1        (w_wr_x1),
        .i_wr_x2        (w_wr_x2),
        .i_wr_y1        (w_wr_y1),
        .i_wr_y2        (w_wr_y2),
        .i_sample_count (w_sample_count),
        .i_event_commit (w_event_commit),
        .o_adc_valid    (w_adc_valid),
        .o_adc_x1       (w_adc_x1),
        .o_adc_x2       (w_adc_x2),
        .o_adc_y1       (w_adc_y1),
        .o_adc_y2       (w_adc_y2),
        .o_busy         (w_buf_busy)
    );

    // =========================================================
    // Host UART (bidirectional GUI link)
    //
    // RX path produces a 151-bit packed config word.
    // TX path consumes a 144-bit event packet from bridge_fsm.
    // =========================================================
    wire [150:0] w_host_rx_data;
    wire         w_host_rx_dv;
    wire [143:0] w_bridge_out;
    wire         w_bridge_out_dv;

    host_uart #(
        .CLKS_PER_BIT    (CLKS_PER_BIT),
        .DATA_INPUT_SIZE (151)
    ) u_host_uart (
        .clk            (i_clk),
        .rst            (i_rst),
        .rx             (i_uart_host_rx),
        .tx             (o_uart_host_tx),
        .data_out       (w_host_rx_data),
        .data_out_valid (w_host_rx_dv),
        .data_in        (w_bridge_out),
        .data_in_valid  (w_bridge_out_dv)
    );

    // =========================================================
    // Configuration FSM (decodes 151-bit packed word)
    // =========================================================
    uart_config_fsm u_config_fsm (
        .clk            (i_clk),
        .rst            (i_rst),
        .rx_packed      (w_host_rx_data),
        .rx_valid       (w_host_rx_dv),
        .attenuation    (w_cfg_attenuation),
        .delay          (w_cfg_delay),
        .threshold      (w_cfg_threshold),
        .zc_neg_samples (w_cfg_zc_neg_samples),
        .kx             (w_cfg_kx),
        .ky             (w_cfg_ky),
        .timestamp      (w_cfg_timestamp),
        .sel            (w_cfg_sel),
        .start_stop     (w_cfg_start_stop),
        .cfg_valid      (w_cfg_valid)
    );

    // =========================================================
    // Timestamp generator (loaded from GUI on cfg_valid,
    // increments locally at 1 us)
    // =========================================================
    wire [63:0] w_timestamp;

    timestamp_generator #(
        .CLK_FREQ (CLK_FREQ_HZ)
    ) u_timestamp (
        .clk            (i_clk),
        .reset          (i_rst),
        .set_time       (w_cfg_timestamp),
        .set_time_valid (w_cfg_valid),
        .timestamp      (w_timestamp)
    );

    // =========================================================
    // DSP pipeline (one of two event sources)
    // =========================================================
    wire        w_dsp_out_valid;
    wire [63:0] w_dsp_out_tag;
    wire signed [31:0] w_dsp_out_x;
    wire signed [31:0] w_dsp_out_y;
    wire signed [15:0] w_dsp_out_mag;
    wire        w_event_missed;
    wire        w_pos_rejected;

    dsp_pipeline u_dsp_pipeline (
        .clk            (i_clk),
        .rst            (i_rst),
        .adc_valid      (w_adc_valid),
        .adc_x1         (w_adc_x1),
        .adc_x2         (w_adc_x2),
        .adc_y1         (w_adc_y1),
        .adc_y2         (w_adc_y2),
        .att_q0_13      (w_cfg_attenuation),
        .delay_val      (w_cfg_delay),
        .threshold      (w_cfg_threshold),
        .zc_neg_samples (w_cfg_zc_neg_samples),
        .kx             (w_cfg_kx),
        .ky             (w_cfg_ky),
        .tag_in         (w_timestamp),
        .out_valid      (w_dsp_out_valid),
        .out_tag        (w_dsp_out_tag),
        .out_x          (w_dsp_out_x),
        .out_y          (w_dsp_out_y),
        .out_mag        (w_dsp_out_mag),
        .event_missed   (w_event_missed),
        .pos_rejected   (w_pos_rejected)
    );

    // =========================================================
    // Pattern generator (alternative event source, gated by start_stop)
    //
    // Note: module name is `pattern_generator` (renamed from pattern_gen).
    // =========================================================
    wire        w_pat_out_valid;
    wire [63:0] w_pat_out_tag;
    wire signed [31:0] w_pat_out_x;
    wire signed [31:0] w_pat_out_y;
    wire signed [15:0] w_pat_out_mag;

    pattern_generator u_pattern_gen (
        .clk       (i_clk),
        .rst       (i_rst),
        .enable    (w_cfg_start_stop),
        .out_valid (w_pat_out_valid),
        .out_tag   (w_pat_out_tag),
        .out_x     (w_pat_out_x),
        .out_y     (w_pat_out_y),
        .out_mag   (w_pat_out_mag)
    );

    // =========================================================
    // Source mux: DSP (sel=0) vs pattern generator (sel=1)
    // =========================================================
    wire        w_mux_out_dv;
    wire [63:0] w_mux_out_tag;
    wire [31:0] w_mux_out_x;
    wire [31:0] w_mux_out_y;
    wire [15:0] w_mux_out_mag;

    mux_gain_test u_mux (
        .clk          (i_clk),
        .rst          (i_rst),
        .sel          (w_cfg_sel),
        .out_tag_dsp  (w_dsp_out_tag),
        .out_dv_dsp   (w_dsp_out_valid),
        .out_x_dsp    (w_dsp_out_x),
        .out_y_dsp    (w_dsp_out_y),
        .out_mag_dsp  (w_dsp_out_mag),
        .out_tag_test (w_pat_out_tag),
        .out_dv_test  (w_pat_out_valid),
        .out_x_test   (w_pat_out_x),
        .out_y_test   (w_pat_out_y),
        .out_mag_test (w_pat_out_mag),
        .out_tag      (w_mux_out_tag),
        .out_dv       (w_mux_out_dv),
        .out_x        (w_mux_out_x),
        .out_y        (w_mux_out_y),
        .out_mag      (w_mux_out_mag)
    );

    // =========================================================
    // Bridge FSM: packs mux output into 144-bit packet for the host UART.
    // Fire-and-forget: events arriving during a TX in progress are dropped.
    // =========================================================
    bridge_fsm u_bridge (
        .clk           (i_clk),
        .rst           (i_rst),
        .in_dv         (w_mux_out_dv),
        .in_tag        (w_mux_out_tag),
        .in_x          (w_mux_out_x),
        .in_y          (w_mux_out_y),
        .in_mag        (w_mux_out_mag),
        .event_dropped (w_event_missed),
        .pos_rejected  (w_pos_rejected),
        .out           (w_bridge_out),
        .out_dv        (w_bridge_out_dv),
        .cnt_dropped   (),
        .cnt_rejected  ()
    );

    // =========================================================
    // LED stretchers
    // =========================================================
    wire w_led_commit, w_led_adc_valid, w_led_out_valid;
    wire w_led_missed, w_led_rejected, w_led_cfg, w_led_proto_err;

    pulse_extender #(.HOLD_CYCLES(40_000_000)) u_led1 (
        .i_clk(i_clk), .i_rst(i_rst),
        .i_trig(w_event_commit), .o_hold(w_led_commit)
    );
    pulse_extender #(.HOLD_CYCLES(40_000_000)) u_led2 (
        .i_clk(i_clk), .i_rst(i_rst),
        .i_trig(w_adc_valid), .o_hold(w_led_adc_valid)
    );
    pulse_extender #(.HOLD_CYCLES(40_000_000)) u_led3 (
        .i_clk(i_clk), .i_rst(i_rst),
        .i_trig(w_mux_out_dv), .o_hold(w_led_out_valid)
    );
    pulse_extender #(.HOLD_CYCLES(40_000_000)) u_led4 (
        .i_clk(i_clk), .i_rst(i_rst),
        .i_trig(w_event_missed), .o_hold(w_led_missed)
    );
    pulse_extender #(.HOLD_CYCLES(40_000_000)) u_led5 (
        .i_clk(i_clk), .i_rst(i_rst),
        .i_trig(w_pos_rejected), .o_hold(w_led_rejected)
    );
    pulse_extender #(.HOLD_CYCLES(40_000_000)) u_led6 (
        .i_clk(i_clk), .i_rst(i_rst),
        .i_trig(w_cfg_valid), .o_hold(w_led_cfg)
    );
    pulse_extender #(.HOLD_CYCLES(40_000_000)) u_led7 (
        .i_clk(i_clk), .i_rst(i_rst),
        .i_trig(w_proto_err), .o_hold(w_led_proto_err)
    );

    assign o_led1 = w_led_commit;
    assign o_led2 = w_led_adc_valid;
    assign o_led3 = w_led_out_valid;
    assign o_led4 = w_led_missed;
    assign o_led5 = w_led_rejected;
    assign o_led6 = w_led_cfg;
    assign o_led7 = w_led_proto_err;
    assign o_led8 = i_rst;

endmodule
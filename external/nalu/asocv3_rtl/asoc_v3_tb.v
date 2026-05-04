// =============================================================================
// ASOC v3 – Testbench
// -----------------------------------------------------------------------------
// Exercises the full ASOC v3 behavioural RTL model:
//   1. Power-on reset
//   2. Sine-wave injection on all 16 RF inputs
//   3. Acquire trigger → buffer fill → data_ready assertion
//   4. LVDS stream verification (captures TxOut[0] and decodes samples)
//   5. Serial-interface register read-back (STATUS, RD_DATA)
//
// Run: iverilog -g2012 -o sim asoc_v3_tb.v asoc_v3.v asoc_v3_adc_channel.v \
//               asoc_v3_serial_if.v asoc_v3_lvds_tx.v && vvp sim
// (Or use Questa / VCS with default settings.)
// =============================================================================

`timescale 1ns/1ps

module asoc_v3_tb;

    // =========================================================================
    // Clock periods
    // =========================================================================
    // NOTE: for simulation speed, BUFFER_DEPTH in the DUT is overridden to 64.
    // The serial and ADC clocks are scaled accordingly.

    localparam real SYS_CLK_PERIOD  = 10.0;   // 100 MHz  → 10 ns
    localparam real ADC_CLK_PERIOD  = 1.0;    // 1 GHz    (scaled from 2.5 GHz)
    localparam real SER_CLK_PERIOD  = 0.5;    // 2 GHz    (fast enough to empty buffer)

    localparam ADC_BITS      = 12;
    localparam BUFFER_DEPTH  = 64;            // reduced for fast sim
    localparam ADDR_W        = 6;

    // =========================================================================
    // DUT port signals
    // =========================================================================
    // Power (tied to constants)
    wire vdd_2v5_p02 = 1'b1;
    wire vdd_2v5_p04 = 1'b1;
    wire vdd_2v5_p14 = 1'b1;
    wire vdd_2v5_p35 = 1'b1;
    wire vdd_2v5_p45 = 1'b1;
    wire vdd_2v5_p47 = 1'b1;
    wire vdd_1v2_p06 = 1'b1;
    wire vdd_1v2_p08 = 1'b1;
    wire vdd_1v2_p10 = 1'b1;
    wire vdd_1v2_p12 = 1'b1;
    wire vdd_1v2_p16 = 1'b1;
    wire vdd_1v2_p33 = 1'b1;
    wire vdd_1v2_p37 = 1'b1;
    wire vdd_1v2_p39 = 1'b1;
    wire vdd_1v2_p41 = 1'b1;
    wire vdd_1v2_p43 = 1'b1;
    wire vdda_b_p17  = 1'b1;
    wire vdda_a_p23  = 1'b1;
    wire vddp_b_p18  = 1'b1;
    wire vddp_a_p24  = 1'b1;

    // Analog inputs (real)
    real rfin_w0, rfin_w1, rfin_w2, rfin_w3;
    real rfin_w4, rfin_w5, rfin_w6, rfin_w7;
    real rfin_e0, rfin_e1, rfin_e2, rfin_e3;
    real rfin_e4, rfin_e5, rfin_e6, rfin_e7;

    // Digital control
    reg  sys_clk, adc_clk, ser_clk, rst_n, acquire;

    // Serial interface
    reg  sda_b;   // SCLK
    reg  sdb_b;   // MOSI
    wire sdc_b;   // MISO
    reg  sdd_b;   // CS_N

    // LVDS outputs
    wire txout0_p, txout0_n;
    wire txout1_p, txout1_n;
    wire txout2_p, txout2_n;
    wire txout3_p, txout3_n;
    wire txclkout0_p, txclkout0_n;
    wire txclkout1_p, txclkout1_n;
    wire txclkout2_p, txclkout2_n;
    wire txclkout3_p, txclkout3_n;

    wire [3:0] data_ready_out;

    // =========================================================================
    // DUT instantiation  (override buffer depth via parameter)
    // =========================================================================
    asoc_v3 #()   // top module uses sub-module parameters – override below
    dut (
        .vdd_2v5_p02(vdd_2v5_p02), .vdd_2v5_p04(vdd_2v5_p04),
        .vdd_2v5_p14(vdd_2v5_p14), .vdd_2v5_p35(vdd_2v5_p35),
        .vdd_2v5_p45(vdd_2v5_p45), .vdd_2v5_p47(vdd_2v5_p47),
        .vdd_1v2_p06(vdd_1v2_p06), .vdd_1v2_p08(vdd_1v2_p08),
        .vdd_1v2_p10(vdd_1v2_p10), .vdd_1v2_p12(vdd_1v2_p12),
        .vdd_1v2_p16(vdd_1v2_p16), .vdd_1v2_p33(vdd_1v2_p33),
        .vdd_1v2_p37(vdd_1v2_p37), .vdd_1v2_p39(vdd_1v2_p39),
        .vdd_1v2_p41(vdd_1v2_p41), .vdd_1v2_p43(vdd_1v2_p43),
        .vdda_b_p17(vdda_b_p17),   .vdda_a_p23(vdda_a_p23),
        .vddp_b_p18(vddp_b_p18),   .vddp_a_p24(vddp_a_p24),
        // Analog
        .rfin_w0(rfin_w0), .rfin_w1(rfin_w1),
        .rfin_w2(rfin_w2), .rfin_w3(rfin_w3),
        .rfin_w4(rfin_w4), .rfin_w5(rfin_w5),
        .rfin_w6(rfin_w6), .rfin_w7(rfin_w7),
        .rfin_e0(rfin_e0), .rfin_e1(rfin_e1),
        .rfin_e2(rfin_e2), .rfin_e3(rfin_e3),
        .rfin_e4(rfin_e4), .rfin_e5(rfin_e5),
        .rfin_e6(rfin_e6), .rfin_e7(rfin_e7),
        // Serial
        .sda_b(sda_b), .sdb_b(sdb_b), .sdc_b(sdc_b), .sdd_b(sdd_b),
        // Clocks / control
        .sys_clk(sys_clk), .adc_clk(adc_clk), .ser_clk(ser_clk),
        .rst_n(rst_n), .acquire(acquire),
        // LVDS outputs
        .txout0_p(txout0_p), .txout0_n(txout0_n),
        .txout1_p(txout1_p), .txout1_n(txout1_n),
        .txout2_p(txout2_p), .txout2_n(txout2_n),
        .txout3_p(txout3_p), .txout3_n(txout3_n),
        .txclkout0_p(txclkout0_p), .txclkout0_n(txclkout0_n),
        .txclkout1_p(txclkout1_p), .txclkout1_n(txclkout1_n),
        .txclkout2_p(txclkout2_p), .txclkout2_n(txclkout2_n),
        .txclkout3_p(txclkout3_p), .txclkout3_n(txclkout3_n),
        .data_ready_out(data_ready_out)
    );

    // =========================================================================
    // Clock generation
    // =========================================================================
    initial sys_clk = 0;
    always #(SYS_CLK_PERIOD/2.0) sys_clk = ~sys_clk;

    initial adc_clk = 0;
    always #(ADC_CLK_PERIOD/2.0) adc_clk = ~adc_clk;

    initial ser_clk = 0;
    always #(SER_CLK_PERIOD/2.0) ser_clk = ~ser_clk;

    // =========================================================================
    // Sine-wave generator for all RF inputs
    // Each channel gets a slightly different frequency and amplitude.
    // =========================================================================
    real sim_time_ns;
    real pi;
    real freq0, freq1, freq2, freq3;

    initial begin
        pi    = 3.14159265358979;
        freq0 = 0.1;   // GHz – 100 MHz test tone for channel 0
        freq1 = 0.15;
        freq2 = 0.2;
        freq3 = 0.25;
    end

    always @(posedge adc_clk) begin
        sim_time_ns = $realtime;
        // Channel 0  (W0/W1/E0/E1) – 100 MHz, 0.8 Vpp
        rfin_w0 <= 0.4 * $sin(2.0*pi*freq0*sim_time_ns);
        rfin_w1 <= 0.4 * $cos(2.0*pi*freq0*sim_time_ns);
        rfin_e0 <= 0.4 * $sin(2.0*pi*freq0*sim_time_ns + pi/4.0);
        rfin_e1 <= 0.4 * $cos(2.0*pi*freq0*sim_time_ns + pi/4.0);
        // Channel 1  (W2/W3/E2/E3) – 150 MHz
        rfin_w2 <= 0.5 * $sin(2.0*pi*freq1*sim_time_ns);
        rfin_w3 <= 0.5 * $cos(2.0*pi*freq1*sim_time_ns);
        rfin_e2 <= 0.5 * $sin(2.0*pi*freq1*sim_time_ns + pi/6.0);
        rfin_e3 <= 0.5 * $cos(2.0*pi*freq1*sim_time_ns + pi/6.0);
        // Channel 2  (W4/W5/E4/E5) – 200 MHz
        rfin_w4 <= 0.6 * $sin(2.0*pi*freq2*sim_time_ns);
        rfin_w5 <= 0.6 * $cos(2.0*pi*freq2*sim_time_ns);
        rfin_e4 <= 0.6 * $sin(2.0*pi*freq2*sim_time_ns + pi/8.0);
        rfin_e5 <= 0.6 * $cos(2.0*pi*freq2*sim_time_ns + pi/8.0);
        // Channel 3  (W6/W7/E6/E7) – 250 MHz
        rfin_w6 <= 0.7 * $sin(2.0*pi*freq3*sim_time_ns);
        rfin_w7 <= 0.7 * $cos(2.0*pi*freq3*sim_time_ns);
        rfin_e6 <= 0.7 * $sin(2.0*pi*freq3*sim_time_ns + pi/3.0);
        rfin_e7 <= 0.7 * $cos(2.0*pi*freq3*sim_time_ns + pi/3.0);
    end

    // =========================================================================
    // Serial-interface task  (sends a 32-bit SPI frame)
    // =========================================================================
    task spi_write;
        input [7:0]  addr;
        input [15:0] data;
        integer j;
        reg [31:0] frame;
        begin
            frame = {1'b0, addr, data, 7'b0};   // R/W=0, write
            sdd_b = 0;                            // assert CS_N low
            #(SYS_CLK_PERIOD);
            for (j = 31; j >= 0; j = j - 1) begin
                sdb_b = frame[j];
                sda_b = 0;
                #(SYS_CLK_PERIOD/2.0);
                sda_b = 1;
                #(SYS_CLK_PERIOD/2.0);
            end
            sda_b = 0;
            sdd_b = 1;                            // de-assert CS_N
            #(SYS_CLK_PERIOD*2);
        end
    endtask

    task spi_read;
        input  [7:0]  addr;
        output [15:0] rdata;
        integer j;
        reg [31:0] frame;
        reg [15:0] capture;
        begin
            frame   = {1'b1, addr, 23'h0};   // R/W=1, read
            capture = 16'h0;
            sdd_b   = 0;
            #(SYS_CLK_PERIOD);
            for (j = 31; j >= 0; j = j - 1) begin
                sdb_b    = frame[j];
                sda_b    = 0;
                #(SYS_CLK_PERIOD/2.0);
                sda_b    = 1;
                if (j >= 16 && j <= 31)
                    capture[j-16] = sdc_b;
                #(SYS_CLK_PERIOD/2.0);
            end
            sda_b = 0;
            sdd_b = 1;
            #(SYS_CLK_PERIOD*2);
            rdata = capture;
        end
    endtask

    // =========================================================================
    // LVDS capture task  – listens on TxOut0 and reconstructs sample words
    // =========================================================================
    integer lvds_errors;
    integer lvds_samples;

    task capture_lvds_ch0;
        input integer expected_samples;
        integer  s, b;
        reg [15:0] frame;
        reg [3:0]  header;
        reg [11:0] sample;
        integer    sign_ext;
        begin
            lvds_errors  = 0;
            lvds_samples = 0;

            // Wait for TX to go active (data_ready must be set first)
            wait(txout0_p || txout0_n);

            $display("  [LVDS CH0] Transmission started");

            for (s = 0; s < expected_samples; s = s + 1) begin
                // Wait for SOF header (4 bits) + 12 data bits = 16 bits
                // Sample on positive edge of companion clock
                frame = 16'h0;
                for (b = 15; b >= 0; b = b - 1) begin
                    @(posedge txclkout0_p);
                    frame[b] = txout0_p;
                end

                header = frame[15:12];
                sample = frame[11:0];

                if (header !== 4'hA) begin
                    $display("  [LVDS CH0] ERROR sample %0d: bad header 0x%01X (expected 0xA)",
                             s, header);
                    lvds_errors = lvds_errors + 1;
                end

                // Convert two's complement to signed integer for display
                if (sample[11])
                    sign_ext = $signed({1'b1, sample}) >>> 0;
                else
                    sign_ext = {20'h0, sample};

                if (s < 8)   // print first 8 samples
                    $display("  [LVDS CH0] Sample[%0d] raw=0x%03X  signed=%0d",
                             s, sample, $signed(sample));

                lvds_samples = lvds_samples + 1;
            end

            $display("  [LVDS CH0] %0d samples captured, %0d errors",
                     lvds_samples, lvds_errors);
        end
    endtask

    // =========================================================================
    // Main stimulus
    // =========================================================================
    reg [15:0] rd_val;
    integer    timeout;

    initial begin
        // Initialise
        rst_n   = 0;
        acquire = 0;
        sda_b   = 0;
        sdb_b   = 0;
        sdd_b   = 1;   // CS de-asserted

        $display("============================================================");
        $display(" ASOC v3 RTL Behavioural Simulation");
        $display("============================================================");

        // Hold reset for 10 sys_clk cycles
        repeat (10) @(posedge sys_clk);
        rst_n = 1;
        $display("[%0t ns] Reset released", $realtime);
        repeat (5) @(posedge sys_clk);

        // ------------------------------------------------------------------
        // TEST 1: Configure via serial interface
        // ------------------------------------------------------------------
        $display("\n--- TEST 1: Serial-interface register write/read ---");

        // Select channel 0 for readback (CTRL[3:2]=0, soft_acquire=0)
        spi_write(8'h00, 16'h0000);
        $display("[%0t ns] CTRL written: ch_select=0", $realtime);

        // Read back STATUS – should be 0 (no data_ready yet)
        spi_read(8'h01, rd_val);
        $display("[%0t ns] STATUS read = 0x%04X (expect 0x0000)", $realtime, rd_val);

        // ------------------------------------------------------------------
        // TEST 2: Trigger acquisition via external acquire pin
        // ------------------------------------------------------------------
        $display("\n--- TEST 2: Acquire trigger + buffer fill ---");
        $display("[%0t ns] Asserting ACQUIRE", $realtime);
        @(posedge adc_clk);
        acquire = 1;
        @(posedge adc_clk);
        acquire = 0;

        // Wait for data_ready from all 4 channels (timeout = 200000 ns)
        timeout = 0;
        while (data_ready_out !== 4'hF && timeout < 200000) begin
            #1;
            timeout = timeout + 1;
        end

        if (data_ready_out === 4'hF)
            $display("[%0t ns] data_ready_out=0xF – all channels captured OK", $realtime);
        else
            $display("[%0t ns] TIMEOUT waiting for data_ready!", $realtime);

        // ------------------------------------------------------------------
        // TEST 3: LVDS stream capture on channel 0
        // ------------------------------------------------------------------
        $display("\n--- TEST 3: LVDS streaming – channel 0 ---");
        capture_lvds_ch0(BUFFER_DEPTH);

        if (lvds_errors == 0)
            $display("  PASS: No LVDS framing errors");
        else
            $display("  FAIL: %0d LVDS framing errors", lvds_errors);

        // ------------------------------------------------------------------
        // TEST 4: Serial read-back of ADC data
        // ------------------------------------------------------------------
        $display("\n--- TEST 4: Serial readback – channel 0, addr 0..3 ---");

        // Set rd_addr = 0
        spi_write(8'h02, 16'h0000);   // RD_ADDR_L = 0
        spi_write(8'h03, 16'h0000);   // RD_ADDR_H = 0

        repeat (3) @(posedge sys_clk);
        spi_read(8'h04, rd_val);
        $display("[%0t ns] CH0 sample[0] via serial = 0x%03X (%0d signed)",
                 $realtime, rd_val[11:0], $signed(rd_val[11:0]));

        // Advance to address 1
        spi_write(8'h02, 16'h0001);
        repeat (3) @(posedge sys_clk);
        spi_read(8'h04, rd_val);
        $display("[%0t ns] CH0 sample[1] via serial = 0x%03X (%0d signed)",
                 $realtime, rd_val[11:0], $signed(rd_val[11:0]));

        // ------------------------------------------------------------------
        // TEST 5: Soft acquire via serial register
        // ------------------------------------------------------------------
        $display("\n--- TEST 5: Soft acquire via serial CTRL register ---");
        spi_write(8'h00, 16'h0001);   // soft_acquire=1
        #2;
        spi_write(8'h00, 16'h0000);   // soft_acquire=0

        timeout = 0;
        while (data_ready_out !== 4'hF && timeout < 200000) begin
            #1;
            timeout = timeout + 1;
        end

        if (data_ready_out === 4'hF)
            $display("[%0t ns] Soft acquire: all channels re-captured", $realtime);
        else
            $display("[%0t ns] TIMEOUT on soft acquire", $realtime);

        // ------------------------------------------------------------------
        // Done
        // ------------------------------------------------------------------
        $display("\n============================================================");
        $display(" Simulation complete.");
        $display("============================================================");

        $dumpflush;
        $finish;
    end

    // =========================================================================
    // Waveform dump
    // =========================================================================
    initial begin
        $dumpfile("asoc_v3_tb.vcd");
        $dumpvars(0, asoc_v3_tb);
    end

    // =========================================================================
    // Safety watchdog
    // =========================================================================
    initial begin
        #5_000_000;
        $display("WATCHDOG: simulation exceeded 5 ms – aborting");
        $finish;
    end

endmodule

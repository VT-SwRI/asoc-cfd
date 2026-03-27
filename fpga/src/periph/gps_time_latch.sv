// ============================================================================
// File        : gps_time_latch.sv
// Description : GPS Time Latch with Microsecond Tracking
//               Supports AMBA APB3, AHB-Lite, and AXI4-Lite bus interfaces.
//               Interface is selected via the BUS_TYPE parameter (default APB).
//
// Architecture
// ------------
//   gps_time_latch (top wrapper -- selects bridge via generate)
//     +-- gps_time_core    (GPS logic, microsecond counter, register file)
//     +-- gps_apb_bridge   (APB3 to internal register bus)
//     +-- gps_ahb_bridge   (AHB-Lite to internal register bus)
//     +-- gps_axi_bridge   (AXI4-Lite to internal register bus)
//
// Register Map  (14 registers, word-addressed, byte-address stride 4)
// -------------------------------------------------------------------
//  0x00  PEND_SEC_LO   RW  Pending GPS seconds [31:0]
//  0x04  PEND_SEC_HI   RW  Pending GPS seconds [47:32] in bits [15:0]
//  0x08  PEND_USEC     RW  Pending microsecond offset [19:0] (0-999999)
//  0x0C  ACT_SEC_LO    RO  Latched GPS seconds [31:0]  (updated on PPS)
//  0x10  ACT_SEC_HI    RO  Latched GPS seconds [47:32]
//  0x14  ACT_USEC      RO  Microsecond count at PPS edge (diagnostic; ideally 0)
//  0x18  CUR_SEC_LO    RO  Current running seconds [31:0]  -- reading this
//  0x1C  CUR_SEC_HI    RO  Current running seconds [47:32] -- atomically
//  0x20  CUR_USEC      RO  Current microseconds [19:0]     -- snapshots all 3
//  0x24  STATUS        RO  [0]=pps_pulse [1]=time_valid [2]=pps_locked
//                          [3]=running   [31:8]=last PPS period clocks (24b)
//  0x28  CONTROL       RW  [0]=time_load_en  [1]=clr_time_valid
//                          [2]=force_latch   [3]=auto_inc_en
//  0x2C  IRQ_STATUS    W1C [0]=pps_irq [1]=latch_irq [2]=pps_unlock_irq
//  0x30  IRQ_ENABLE    RW  Bit-per-IRQ enable mask
//  0x34  PPS_PERIOD    RO  Last measured PPS period in clock cycles [31:0]
//
// Snapshot note: Reading CUR_SEC_LO captures a coherent snapshot of all three
// current-time registers preventing torn reads across second boundaries.
//
// Microsecond counter
// -------------------
//  A prescale counter divides the system clock by CLK_FREQ_HZ/1_000_000 to
//  produce a 1-us tick.  usec_val counts 0..999_999 and resets on every PPS
//  rising edge.  run_sec is seeded from active_time on the first latch and
//  increments by one on every subsequent PPS when auto_inc_en is set.
//
// Parameters
// ----------
//  BUS_TYPE       : "APB" | "AHB" | "AXI"  (default "APB")
//  CLK_FREQ_HZ    : System clock in Hz      (default 100_000_000)
//  PPS_TOL_PPM    : PPS period tolerance    (default 100 ppm)
//  PPS_GLITCH_NS  : Glitch reject threshold (default 50 ns)
//
// ============================================================================

`timescale 1ns/1ps
`default_nettype none

// ============================================================================
//  gps_time_core
//  Pure GPS logic: PPS sync, glitch filter, microsecond counter, register file.
//  All bridge modules instantiate this sub-module via a simple 8-bit reg bus.
// ============================================================================
module gps_time_core #(
    parameter int unsigned CLK_FREQ_HZ   = 100_000_000,
    parameter int unsigned PPS_TOL_PPM   = 100,
    parameter int unsigned PPS_GLITCH_NS = 50
)(
    input  logic        clk,
    input  logic        rst_n,      ///< Active-low synchronous reset
    input  logic        pps_in,     ///< 1-PPS from GPS receiver (asynchronous)
    // Internal register bus
    input  logic [7:0]  reg_addr,   ///< Byte address; bits [7:2] are word index
    input  logic [31:0] reg_wdata,
    input  logic        reg_wen,    ///< Single-cycle write strobe
    input  logic        reg_ren,    ///< Single-cycle read strobe
    output logic [31:0] reg_rdata,
    output logic        reg_rvalid, ///< Read data valid (1 cycle after reg_ren)
    output logic        reg_err,    ///< Unmapped address error
    output logic        irq         ///< Active-high level interrupt output
);

    // =========================================================================
    // Derived local parameters
    // =========================================================================
    localparam int unsigned PPS_NOM      = CLK_FREQ_HZ;
    localparam int unsigned PPS_TOL_CYC  = (PPS_NOM * PPS_TOL_PPM) / 1_000_000;
    localparam int unsigned CLK_PER_US   = CLK_FREQ_HZ / 1_000_000;
    localparam int unsigned GLITCH_CYC   = (CLK_FREQ_HZ / 1_000_000_000) * PPS_GLITCH_NS + 1;

    // Register address constants
    localparam logic [7:0] A_PEND_SEC_LO = 8'h00;
    localparam logic [7:0] A_PEND_SEC_HI = 8'h04;
    localparam logic [7:0] A_PEND_USEC   = 8'h08;
    localparam logic [7:0] A_ACT_SEC_LO  = 8'h0C;
    localparam logic [7:0] A_ACT_SEC_HI  = 8'h10;
    localparam logic [7:0] A_ACT_USEC    = 8'h14;
    localparam logic [7:0] A_CUR_SEC_LO  = 8'h18;
    localparam logic [7:0] A_CUR_SEC_HI  = 8'h1C;
    localparam logic [7:0] A_CUR_USEC    = 8'h20;
    localparam logic [7:0] A_STATUS      = 8'h24;
    localparam logic [7:0] A_CONTROL     = 8'h28;
    localparam logic [7:0] A_IRQ_STATUS  = 8'h2C;
    localparam logic [7:0] A_IRQ_ENABLE  = 8'h30;
    localparam logic [7:0] A_PPS_PERIOD  = 8'h34;

    // =========================================================================
    // Internal signal declarations
    // =========================================================================

    // PPS path
    logic [1:0] pps_sync;
    logic       pps_clean;
    logic [$clog2(GLITCH_CYC+2)-1:0] glitch_cnt;
    logic       pps_filt, pps_filt_prev, pps_rising;

    // PPS period measurement
    logic [31:0] period_cnt, period_latch;
    logic        pps_locked;

    // Microsecond counter
    logic [$clog2(CLK_PER_US+1)-1:0] us_pre;
    logic [19:0] usec_val;
    logic        us_tick;

    // GPS time registers
    logic [47:0] pend_sec;
    logic [19:0] pend_usec;
    logic [47:0] act_sec;
    logic [19:0] act_usec;
    logic [47:0] run_sec;
    logic [19:0] run_usec;
    logic        time_valid, running;

    // Atomic snapshot
    logic [47:0] snap_sec;
    logic [19:0] snap_usec;

    // Control
    logic time_load_en, auto_inc_en, force_latch, do_latch;

    // Interrupts
    logic pps_irq, latch_irq, pps_unlock_irq;
    logic pps_irq_en, latch_irq_en, pps_unlock_irq_en;

    // Read pipeline
    logic [31:0] rdata_r;
    logic        rvalid_r, rerr_r;

    // =========================================================================
    // PPS 2-FF Synchroniser
    // =========================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) pps_sync <= 2'b00;
        else        pps_sync <= {pps_sync[0], pps_in};
    end
    assign pps_clean = pps_sync[1];

    // =========================================================================
    // Glitch Filter
    // pps_filt asserts only after pps_clean has been stable-high for
    // GLITCH_CYC consecutive clock cycles, rejecting noise and false pulses.
    // =========================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            glitch_cnt <= '0;
            pps_filt   <= 1'b0;
        end else if (!pps_clean) begin
            glitch_cnt <= '0;
            pps_filt   <= 1'b0;
        end else begin
            if (glitch_cnt < GLITCH_CYC[$bits(glitch_cnt)-1:0])
                glitch_cnt <= glitch_cnt + 1'b1;
            if (glitch_cnt == (GLITCH_CYC[$bits(glitch_cnt)-1:0] - 1'b1))
                pps_filt <= 1'b1;
        end
    end

    // Edge detection on glitch-filtered signal
    always_ff @(posedge clk) begin
        if (!rst_n) pps_filt_prev <= 1'b0;
        else        pps_filt_prev <= pps_filt;
    end
    assign pps_rising = pps_filt & ~pps_filt_prev;

    // =========================================================================
    // PPS Period Measurement
    // Counts clock cycles between edges; asserts pps_locked when within
    // [NOM - TOL_CYC, NOM + TOL_CYC].
    // =========================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            period_cnt   <= 32'd0;
            period_latch <= 32'd0;
            pps_locked   <= 1'b0;
        end else if (pps_rising) begin
            period_latch <= period_cnt;
            period_cnt   <= 32'd1;
            pps_locked   <= (period_cnt >= (PPS_NOM - PPS_TOL_CYC)) &&
                            (period_cnt <= (PPS_NOM + PPS_TOL_CYC));
        end else begin
            if (period_cnt != 32'hFFFF_FFFF)
                period_cnt <= period_cnt + 1'b1;
        end
    end

    // =========================================================================
    // Microsecond Prescaler and Counter
    // us_pre divides the system clock by CLK_PER_US.
    // usec_val counts 0..999_999 and hard-resets to 0 on each PPS edge.
    // =========================================================================
    always_ff @(posedge clk) begin
        if (!rst_n)       us_pre <= '0;
        else if (pps_rising) us_pre <= '0;
        else if (us_pre == (CLK_PER_US[$bits(us_pre)-1:0] - 1'b1))
                          us_pre <= '0;
        else              us_pre <= us_pre + 1'b1;
    end
    assign us_tick = (us_pre == '0) && !pps_rising;

    always_ff @(posedge clk) begin
        if (!rst_n)        usec_val <= 20'd0;
        else if (pps_rising) usec_val <= 20'd0;
        else if (us_tick)
            usec_val <= (usec_val == 20'd999_999) ? 20'd0 : usec_val + 1'b1;
    end

    // run_usec: mirrors usec_val once time is valid
    always_ff @(posedge clk) begin
        if (!rst_n)        run_usec <= 20'd0;
        else if (pps_rising) run_usec <= 20'd0;
        else if (us_tick && time_valid)
            run_usec <= (run_usec == 20'd999_999) ? 20'd0 : run_usec + 1'b1;
    end

    // =========================================================================
    // Latch Trigger
    // do_latch fires on (PPS rising edge AND time_load_en) OR force_latch.
    // =========================================================================
    assign do_latch = (pps_rising & time_load_en) | force_latch;

    // =========================================================================
    // GPS Time Latch and Running Second Counter
    // =========================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            act_sec    <= 48'd0;
            act_usec   <= 20'd0;
            run_sec    <= 48'd0;
            time_valid <= 1'b0;
            running    <= 1'b0;
        end else begin
            // Atomic latch: pending -> active and seed running counter
            if (do_latch) begin
                act_sec    <= pend_sec;
                act_usec   <= usec_val;   // Capture usec at latch instant (ideally ~0 for PPS)
                run_sec    <= pend_sec;
                time_valid <= 1'b1;
                running    <= 1'b0;
            end
            // Auto-increment running seconds on each subsequent PPS
            if (pps_rising && time_valid && auto_inc_en && !do_latch) begin
                run_sec <= run_sec + 48'd1;
                running <= 1'b1;
            end
            // SW clear of time_valid; do_latch takes priority (sets it again)
            if (reg_wen && (reg_addr == A_CONTROL) && reg_wdata[1] && !do_latch)
                time_valid <= 1'b0;
        end
    end

    // =========================================================================
    // Atomic Snapshot for Coherent CUR_SEC Reads
    // When CUR_SEC_LO is read, all three current values are captured together.
    // Subsequent reads of CUR_SEC_HI and CUR_USEC return from the snapshot.
    // =========================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            snap_sec  <= 48'd0;
            snap_usec <= 20'd0;
        end else if (reg_ren && (reg_addr == A_CUR_SEC_LO)) begin
            snap_sec  <= run_sec;
            snap_usec <= run_usec;
        end
    end

    // =========================================================================
    // Interrupt Flags  (Write-1-to-Clear)
    // =========================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pps_irq        <= 1'b0;
            latch_irq      <= 1'b0;
            pps_unlock_irq <= 1'b0;
        end else begin
            if (pps_rising)                            pps_irq        <= 1'b1;
            if (do_latch)                              latch_irq      <= 1'b1;
            if (pps_rising && time_valid && !pps_locked) pps_unlock_irq <= 1'b1;
            if (reg_wen && (reg_addr == A_IRQ_STATUS)) begin
                if (reg_wdata[0]) pps_irq        <= 1'b0;
                if (reg_wdata[1]) latch_irq      <= 1'b0;
                if (reg_wdata[2]) pps_unlock_irq <= 1'b0;
            end
        end
    end
    assign irq = (pps_irq        & pps_irq_en)        |
                 (latch_irq      & latch_irq_en)       |
                 (pps_unlock_irq & pps_unlock_irq_en);

    // =========================================================================
    // Register Write Interface
    // =========================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pend_sec          <= 48'd0;
            pend_usec         <= 20'd0;
            time_load_en      <= 1'b0;
            auto_inc_en       <= 1'b0;
            force_latch       <= 1'b0;
            pps_irq_en        <= 1'b0;
            latch_irq_en      <= 1'b0;
            pps_unlock_irq_en <= 1'b0;
        end else begin
            force_latch <= 1'b0;   // Self-clear every clock
            if (reg_wen) begin
                case (reg_addr)
                    A_PEND_SEC_LO: pend_sec[31:0]  <= reg_wdata;
                    A_PEND_SEC_HI: pend_sec[47:32] <= reg_wdata[15:0];
                    A_PEND_USEC:   pend_usec        <= reg_wdata[19:0];
                    A_CONTROL: begin
                        time_load_en  <= reg_wdata[0];
                        // [1] clr_time_valid handled in latch always_ff block
                        force_latch   <= reg_wdata[2];
                        auto_inc_en   <= reg_wdata[3];
                    end
                    A_IRQ_ENABLE: begin
                        pps_irq_en        <= reg_wdata[0];
                        latch_irq_en      <= reg_wdata[1];
                        pps_unlock_irq_en <= reg_wdata[2];
                    end
                    default: ;  // RO and unmapped registers silently ignored
                endcase
            end
        end
    end

    // =========================================================================
    // Register Read Interface  (1-cycle latency)
    // =========================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rdata_r  <= 32'd0;
            rvalid_r <= 1'b0;
            rerr_r   <= 1'b0;
        end else begin
            rvalid_r <= reg_ren;
            rerr_r   <= 1'b0;
            if (reg_ren) begin
                case (reg_addr)
                    A_PEND_SEC_LO: rdata_r <= pend_sec[31:0];
                    A_PEND_SEC_HI: rdata_r <= {16'd0, pend_sec[47:32]};
                    A_PEND_USEC:   rdata_r <= {12'd0, pend_usec};
                    A_ACT_SEC_LO:  rdata_r <= act_sec[31:0];
                    A_ACT_SEC_HI:  rdata_r <= {16'd0, act_sec[47:32]};
                    A_ACT_USEC:    rdata_r <= {12'd0, act_usec};
                    // CUR_SEC_LO: snapshot is triggered in parallel always_ff
                    A_CUR_SEC_LO:  rdata_r <= run_sec[31:0];
                    A_CUR_SEC_HI:  rdata_r <= {16'd0, snap_sec[47:32]};
                    A_CUR_USEC:    rdata_r <= {12'd0, snap_usec};
                    A_STATUS:      rdata_r <= {period_latch[23:0],
                                               4'd0,
                                               running,
                                               pps_locked,
                                               time_valid,
                                               pps_rising};
                    A_CONTROL:     rdata_r <= {28'd0,
                                               auto_inc_en,
                                               1'b0,          // force_latch reads 0
                                               1'b0,          // clr_time_valid reads 0
                                               time_load_en};
                    A_IRQ_STATUS:  rdata_r <= {29'd0, pps_unlock_irq, latch_irq, pps_irq};
                    A_IRQ_ENABLE:  rdata_r <= {29'd0, pps_unlock_irq_en, latch_irq_en, pps_irq_en};
                    A_PPS_PERIOD:  rdata_r <= period_latch;
                    default: begin
                        rdata_r <= 32'hDEAD_BEEF;  // Unmapped address sentinel
                        rerr_r  <= 1'b1;
                    end
                endcase
            end
        end
    end
    assign reg_rdata  = rdata_r;
    assign reg_rvalid = rvalid_r;
    assign reg_err    = rerr_r;

    // =========================================================================
    // Elaboration-time parameter validation
    // =========================================================================
    initial begin : param_check
        if (CLK_FREQ_HZ < 1_000_000)
            $fatal(1,"[gps_core] CLK_FREQ_HZ must be >= 1 MHz");
        if (CLK_PER_US < 1)
            $fatal(1,"[gps_core] CLK_FREQ_HZ must be a multiple of 1 MHz");
        if (PPS_TOL_PPM > 50_000)
            $fatal(1,"[gps_core] PPS_TOL_PPM > 50000 is unreasonable");
        if ((PPS_NOM + PPS_TOL_CYC) > 32'hFFFF_FFFF)
            $fatal(1,"[gps_core] PPS period + tolerance overflows 32-bit counter");
        $display("[gps_core] CLK_FREQ_HZ=%0d CLK_PER_US=%0d PPS_TOL_CYC=%0d GLITCH_CYC=%0d",
                 CLK_FREQ_HZ, CLK_PER_US, PPS_TOL_CYC, GLITCH_CYC);
    end

endmodule : gps_time_core


// ============================================================================
//  gps_apb_bridge
//  Converts AMBA APB3 to the gps_time_core internal register bus.
//
//  APB3 timing:
//    T1  Setup  phase: PSEL=1, PENABLE=0 -- address and control presented
//    T2  Access phase: PSEL=1, PENABLE=1 -- PREADY sampled; data driven
//  This bridge uses zero wait states (PREADY=1 always).
//  Read data is requested in T1 (Setup) so it is valid by T2 (Access).
// ============================================================================
module gps_apb_bridge #(
    parameter int unsigned CLK_FREQ_HZ   = 100_000_000,
    parameter int unsigned PPS_TOL_PPM   = 100,
    parameter int unsigned PPS_GLITCH_NS = 50
)(
    input  logic        PCLK,
    input  logic        PRESETn,
    input  logic        pps_in,
    input  logic [31:0] PADDR,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR,
    output logic        irq
);
    logic [7:0]  reg_addr;
    logic [31:0] reg_wdata, reg_rdata;
    logic        reg_wen, reg_ren, reg_rvalid, reg_err;

    assign reg_addr  = PADDR[7:0];
    assign reg_wdata = PWDATA;
    // Write fires at start of Access phase (PENABLE rises)
    assign reg_wen   =  PSEL &  PENABLE &  PWRITE;
    // Read requested at Setup phase so data is ready for Access phase
    assign reg_ren   =  PSEL & ~PENABLE & ~PWRITE;

    assign PRDATA    = reg_rdata;
    assign PREADY    = 1'b1;
    assign PSLVERR   = reg_err;

    gps_time_core #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ), .PPS_TOL_PPM(PPS_TOL_PPM),
        .PPS_GLITCH_NS(PPS_GLITCH_NS)
    ) u_core (
        .clk(PCLK), .rst_n(PRESETn), .pps_in(pps_in),
        .reg_addr(reg_addr), .reg_wdata(reg_wdata),
        .reg_wen(reg_wen),   .reg_ren(reg_ren),
        .reg_rdata(reg_rdata), .reg_rvalid(reg_rvalid),
        .reg_err(reg_err),   .irq(irq)
    );
endmodule : gps_apb_bridge


// ============================================================================
//  gps_ahb_bridge
//  Converts AMBA AHB-Lite to the gps_time_core internal register bus.
//
//  AHB-Lite timing (pipelined):
//    Address phase: HTRANS[1]=1, HSEL=1  -- HADDR/HWRITE/HSIZE driven
//    Data    phase: next clock            -- HWDATA valid for writes
//  Control signals from the address phase are registered and used in the
//  data phase when HWDATA is stable, matching the AHB pipeline model.
// ============================================================================
module gps_ahb_bridge #(
    parameter int unsigned CLK_FREQ_HZ   = 100_000_000,
    parameter int unsigned PPS_TOL_PPM   = 100,
    parameter int unsigned PPS_GLITCH_NS = 50
)(
    input  logic        HCLK,
    input  logic        HRESETn,
    input  logic        pps_in,
    input  logic        HSEL,
    input  logic [31:0] HADDR,
    input  logic        HWRITE,
    input  logic [1:0]  HTRANS,
    input  logic [2:0]  HSIZE,
    input  logic [2:0]  HBURST,
    input  logic [31:0] HWDATA,
    output logic [31:0] HRDATA,
    output logic        HREADY,
    output logic        HRESP,
    output logic        irq
);
    // Pipeline registers: address phase -> data phase
    logic        dp_wen, dp_ren;
    logic [7:0]  dp_addr;

    always_ff @(posedge HCLK) begin
        if (!HRESETn) begin
            dp_wen  <= 1'b0;
            dp_ren  <= 1'b0;
            dp_addr <= 8'd0;
        end else if (HREADY) begin
            dp_wen  <= HSEL & HTRANS[1] &  HWRITE;
            dp_ren  <= HSEL & HTRANS[1] & ~HWRITE;
            dp_addr <= HADDR[7:0];
        end
    end

    logic [31:0] reg_rdata;
    logic        reg_rvalid, reg_err;

    gps_time_core #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ), .PPS_TOL_PPM(PPS_TOL_PPM),
        .PPS_GLITCH_NS(PPS_GLITCH_NS)
    ) u_core (
        .clk(HCLK), .rst_n(HRESETn), .pps_in(pps_in),
        .reg_addr(dp_addr),   .reg_wdata(HWDATA),
        .reg_wen(dp_wen),     .reg_ren(dp_ren),
        .reg_rdata(reg_rdata), .reg_rvalid(reg_rvalid),
        .reg_err(reg_err),    .irq(irq)
    );

    assign HRDATA = reg_rdata;
    assign HREADY = 1'b1;          // Zero wait states
    assign HRESP  = reg_err & dp_ren;
endmodule : gps_ahb_bridge


// ============================================================================
//  gps_axi_bridge
//  Converts AXI4-Lite to the gps_time_core internal register bus.
//
//  AXI4-Lite has five independent channels: AW (write address), W (write data),
//  B (write response), AR (read address), R (read data).  The AW and W channels
//  may arrive in any order; this bridge latches each independently and fires the
//  internal write when both have been received.
// ============================================================================
module gps_axi_bridge #(
    parameter int unsigned CLK_FREQ_HZ   = 100_000_000,
    parameter int unsigned PPS_TOL_PPM   = 100,
    parameter int unsigned PPS_GLITCH_NS = 50
)(
    input  logic        ACLK,
    input  logic        ARESETn,
    input  logic        pps_in,
    // Write address channel
    input  logic [31:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    // Write data channel
    input  logic [31:0] WDATA,
    input  logic [3:0]  WSTRB,
    input  logic        WVALID,
    output logic        WREADY,
    // Write response channel
    output logic [1:0]  BRESP,
    output logic        BVALID,
    input  logic        BREADY,
    // Read address channel
    input  logic [31:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,
    // Read data channel
    output logic [31:0] RDATA,
    output logic [1:0]  RRESP,
    output logic        RVALID,
    input  logic        RREADY,
    output logic        irq
);
    // ---- Write path ---------------------------------------------------------
    // Pending flags: set when a channel fires but its partner has not yet arrived
    logic        aw_pend;       // AW arrived; waiting for W
    logic        w_pend;        // W arrived; waiting for AW
    logic [7:0]  aw_addr_r;
    logic [31:0] w_data_r;

    // Internal bus signals
    logic        reg_wen, reg_ren;
    logic [7:0]  reg_addr;
    logic [31:0] reg_wdata, reg_rdata;
    logic        reg_rvalid, reg_err;

    // Handshake fires
    wire aw_fire = AWVALID & AWREADY;
    wire w_fire  = WVALID  & WREADY;

    // Accept each channel unless already pending
    assign AWREADY = ~aw_pend;
    assign WREADY  = ~w_pend;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            aw_pend <= 1'b0; w_pend <= 1'b0;
            aw_addr_r <= 8'd0; w_data_r <= 32'd0;
        end else begin
            // Latch AW if it fires without a simultaneous W
            if (aw_fire && !w_fire && !w_pend) begin
                aw_pend   <= 1'b1;
                aw_addr_r <= AWADDR[7:0];
            end
            // Latch W if it fires without a simultaneous AW
            if (w_fire && !aw_fire && !aw_pend) begin
                w_pend   <= 1'b1;
                w_data_r <= WDATA;
            end
            // Clear pending flags when write commits
            if (reg_wen) begin
                aw_pend <= 1'b0;
                w_pend  <= 1'b0;
            end
        end
    end

    // Write commits when both channels are satisfied
    assign reg_wen   = (aw_fire & w_fire)  |    // Both arrive simultaneously
                       (aw_fire & w_pend)  |    // AW late-arrives; W was pending
                       (w_fire  & aw_pend);     // W  late-arrives; AW was pending
    // Effective address/data (prefer pending latch over live input)
    assign reg_addr  = reg_wen ? (aw_pend ? aw_addr_r : AWADDR[7:0]) : ARADDR[7:0];
    assign reg_wdata = reg_wen ? (w_pend  ? w_data_r  : WDATA)       : 32'd0;

    // Write response channel
    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            BVALID <= 1'b0;
            BRESP  <= 2'b00;
        end else begin
            if (reg_wen)          begin BVALID <= 1'b1; BRESP <= 2'b00; end
            else if (BVALID & BREADY) BVALID <= 1'b0;
        end
    end

    // ---- Read path ----------------------------------------------------------
    logic rd_inflight;   // True when a read is accepted and awaiting reg_rvalid

    assign ARREADY = ~rd_inflight;
    assign reg_ren  = ARVALID & ARREADY;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            rd_inflight <= 1'b0;
            RVALID      <= 1'b0;
            RDATA       <= 32'd0;
            RRESP       <= 2'b00;
        end else begin
            if (reg_ren)           rd_inflight <= 1'b1;
            if (reg_rvalid) begin
                rd_inflight <= 1'b0;
                RVALID      <= 1'b1;
                RDATA       <= reg_rdata;
                RRESP       <= reg_err ? 2'b10 : 2'b00;
            end else if (RVALID & RREADY) begin
                RVALID <= 1'b0;
            end
        end
    end

    // ---- Core instantiation -------------------------------------------------
    gps_time_core #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ), .PPS_TOL_PPM(PPS_TOL_PPM),
        .PPS_GLITCH_NS(PPS_GLITCH_NS)
    ) u_core (
        .clk(ACLK), .rst_n(ARESETn), .pps_in(pps_in),
        .reg_addr(reg_addr),   .reg_wdata(reg_wdata),
        .reg_wen(reg_wen),     .reg_ren(reg_ren),
        .reg_rdata(reg_rdata), .reg_rvalid(reg_rvalid),
        .reg_err(reg_err),     .irq(irq)
    );
endmodule : gps_axi_bridge


// ============================================================================
//  gps_time_latch  (top-level wrapper)
//
//  Selects the bus bridge at elaboration time via the BUS_TYPE string parameter.
//  All possible bus ports are declared; only those matching BUS_TYPE need to be
//  connected by the integrator.  Unused output ports are driven to safe values
//  by the generate tie-off assignments.
//
//  BUS_TYPE = "APB" (default)  PCLK/PRESETn/PADDR/PSEL/PENABLE/PWRITE/PWDATA
//                               PRDATA/PREADY/PSLVERR
//  BUS_TYPE = "AHB"            HCLK/HRESETn/HSEL/HADDR/HWRITE/HTRANS/HSIZE/
//                               HBURST/HWDATA/HRDATA/HREADY/HRESP
//  BUS_TYPE = "AXI"            ACLK/ARESETn  + AW/W/B/AR/R channel signals
// ============================================================================
module gps_time_latch #(
    parameter string   BUS_TYPE      = "APB",
    parameter int unsigned CLK_FREQ_HZ   = 100_000_000,
    parameter int unsigned PPS_TOL_PPM   = 100,
    parameter int unsigned PPS_GLITCH_NS = 50
)(
    input  logic        pps_in,
    // APB3
    input  logic        PCLK,
    input  logic        PRESETn,
    input  logic [31:0] PADDR,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR,
    // AHB-Lite
    input  logic        HCLK,
    input  logic        HRESETn,
    input  logic        HSEL,
    input  logic [31:0] HADDR,
    input  logic        HWRITE,
    input  logic [1:0]  HTRANS,
    input  logic [2:0]  HSIZE,
    input  logic [2:0]  HBURST,
    input  logic [31:0] HWDATA,
    output logic [31:0] HRDATA,
    output logic        HREADY,
    output logic        HRESP,
    // AXI4-Lite
    input  logic        ACLK,
    input  logic        ARESETn,
    input  logic [31:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    input  logic [31:0] WDATA,
    input  logic [3:0]  WSTRB,
    input  logic        WVALID,
    output logic        WREADY,
    output logic [1:0]  BRESP,
    output logic        BVALID,
    input  logic        BREADY,
    input  logic [31:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,
    output logic [31:0] RDATA,
    output logic [1:0]  RRESP,
    output logic        RVALID,
    input  logic        RREADY,
    // Interrupt (all interfaces)
    output logic        irq
);
    generate
        if (BUS_TYPE == "APB") begin : gen_apb
            gps_apb_bridge #(.CLK_FREQ_HZ(CLK_FREQ_HZ),.PPS_TOL_PPM(PPS_TOL_PPM),
                             .PPS_GLITCH_NS(PPS_GLITCH_NS)) u_apb (
                .PCLK(PCLK),.PRESETn(PRESETn),.pps_in(pps_in),
                .PADDR(PADDR),.PSEL(PSEL),.PENABLE(PENABLE),
                .PWRITE(PWRITE),.PWDATA(PWDATA),
                .PRDATA(PRDATA),.PREADY(PREADY),.PSLVERR(PSLVERR),.irq(irq));
            assign HRDATA=32'd0;  assign HREADY=1'b1;  assign HRESP=1'b0;
            assign AWREADY=1'b0;  assign WREADY=1'b0;  assign BRESP=2'd0;
            assign BVALID=1'b0;   assign ARREADY=1'b0; assign RDATA=32'd0;
            assign RRESP=2'd0;    assign RVALID=1'b0;
        end
        else if (BUS_TYPE == "AHB") begin : gen_ahb
            gps_ahb_bridge #(.CLK_FREQ_HZ(CLK_FREQ_HZ),.PPS_TOL_PPM(PPS_TOL_PPM),
                             .PPS_GLITCH_NS(PPS_GLITCH_NS)) u_ahb (
                .HCLK(HCLK),.HRESETn(HRESETn),.pps_in(pps_in),
                .HSEL(HSEL),.HADDR(HADDR),.HWRITE(HWRITE),
                .HTRANS(HTRANS),.HSIZE(HSIZE),.HBURST(HBURST),.HWDATA(HWDATA),
                .HRDATA(HRDATA),.HREADY(HREADY),.HRESP(HRESP),.irq(irq));
            assign PRDATA=32'd0;  assign PREADY=1'b1;  assign PSLVERR=1'b0;
            assign AWREADY=1'b0;  assign WREADY=1'b0;  assign BRESP=2'd0;
            assign BVALID=1'b0;   assign ARREADY=1'b0; assign RDATA=32'd0;
            assign RRESP=2'd0;    assign RVALID=1'b0;
        end
        else if (BUS_TYPE == "AXI") begin : gen_axi
            gps_axi_bridge #(.CLK_FREQ_HZ(CLK_FREQ_HZ),.PPS_TOL_PPM(PPS_TOL_PPM),
                             .PPS_GLITCH_NS(PPS_GLITCH_NS)) u_axi (
                .ACLK(ACLK),.ARESETn(ARESETn),.pps_in(pps_in),
                .AWADDR(AWADDR),.AWVALID(AWVALID),.AWREADY(AWREADY),
                .WDATA(WDATA),.WSTRB(WSTRB),.WVALID(WVALID),.WREADY(WREADY),
                .BRESP(BRESP),.BVALID(BVALID),.BREADY(BREADY),
                .ARADDR(ARADDR),.ARVALID(ARVALID),.ARREADY(ARREADY),
                .RDATA(RDATA),.RRESP(RRESP),.RVALID(RVALID),.RREADY(RREADY),
                .irq(irq));
            assign PRDATA=32'd0;  assign PREADY=1'b1;  assign PSLVERR=1'b0;
            assign HRDATA=32'd0;  assign HREADY=1'b1;  assign HRESP=1'b0;
        end
        else begin : gen_bad_param
            initial $fatal(1,"[gps_time_latch] BUS_TYPE must be APB, AHB, or AXI");
        end
    endgenerate
endmodule : gps_time_latch

`default_nettype wire

// ============================================================================
//  gps_time_latch_tb  --  Self-checking simulation testbench
//
//  Three DUT instances exercise APB, AHB, and AXI interfaces independently.
//  The same pps_in signal is applied to all three because they share a clock.
//
//  Test Groups:
//    G1  APB: write/readback, PPS latch, IRQs, microsecond counter,
//             atomic snapshot, force_latch, auto-increment, error response
//    G2  AHB: write/readback, PPS latch, status flags
//    G3  AXI: write/readback, PPS latch, IRQs, split AW/W channel ordering
//
//  Clock: 10 MHz (100 ns period)  so CLK_PER_US=10 and 1 PPS = 10 M cycles.
// ============================================================================
`timescale 1ns/1ps
`default_nettype none

module gps_time_latch_tb;

    // -------------------------------------------------------------------------
    // Simulation constants
    // -------------------------------------------------------------------------
    localparam int CLK_FREQ   = 10_000_000;
    localparam int CLK_HALF   = 50;            // 50 ns -> 10 MHz
    localparam int PPS_PERIOD = CLK_FREQ;      // 10 M cycles per second
    localparam int PPS_PULSE  = PPS_PERIOD/20; // 5% duty cycle

    // -------------------------------------------------------------------------
    // Global clock and PPS
    // -------------------------------------------------------------------------
    logic clk;
    logic pps_in = 1'b0;
    initial clk = 1'b0;
    always  #(CLK_HALF) clk = ~clk;

    // =========================================================================
    // DUT 1: APB
    // =========================================================================
    logic        apb_rst;
    logic [31:0] apb_addr=0, apb_wdata=0, apb_rdata;
    logic        apb_sel=0, apb_en=0, apb_wr=0;
    logic        apb_ready, apb_slverr, apb_irq;

    gps_time_latch #(.BUS_TYPE("APB"),.CLK_FREQ_HZ(CLK_FREQ),.PPS_TOL_PPM(200)) dut_apb (
        .pps_in(pps_in),
        .PCLK(clk), .PRESETn(apb_rst),
        .PADDR(apb_addr), .PSEL(apb_sel), .PENABLE(apb_en),
        .PWRITE(apb_wr),  .PWDATA(apb_wdata),
        .PRDATA(apb_rdata), .PREADY(apb_ready), .PSLVERR(apb_slverr),
        .irq(apb_irq),
        .HCLK(1'b0),.HRESETn(1'b1),.HSEL(1'b0),.HADDR(32'd0),
        .HWRITE(1'b0),.HTRANS(2'd0),.HSIZE(3'd0),.HBURST(3'd0),.HWDATA(32'd0),
        .ACLK(1'b0),.ARESETn(1'b1),.AWADDR(32'd0),.AWVALID(1'b0),
        .WDATA(32'd0),.WSTRB(4'd0),.WVALID(1'b0),.BREADY(1'b1),
        .ARADDR(32'd0),.ARVALID(1'b0),.RREADY(1'b1)
    );

    // APB tasks
    task automatic apb_wr_reg(input logic [31:0] a, d);
        @(posedge clk); #1;
        apb_addr=a; apb_wdata=d; apb_sel=1; apb_wr=1; apb_en=0;
        @(posedge clk); #1;
        apb_en=1;
        @(posedge clk); #1;
        apb_sel=0; apb_en=0; apb_wr=0;
    endtask

    task automatic apb_rd_reg(input logic [31:0] a, output logic [31:0] d);
        @(posedge clk); #1;
        apb_addr=a; apb_sel=1; apb_wr=0; apb_en=0;
        @(posedge clk); #1;
        apb_en=1;
        @(posedge clk); #1;
        d=apb_rdata;
        apb_sel=0; apb_en=0;
    endtask

    // =========================================================================
    // DUT 2: AHB
    // =========================================================================
    logic        ahb_rst;
    logic        ahb_sel=0, ahb_wr=0, ahb_ready, ahb_resp;
    logic [31:0] ahb_addr=0, ahb_wdata=0, ahb_rdata;
    logic [1:0]  ahb_trans=0;
    logic [2:0]  ahb_size=3'b010, ahb_burst=0;
    logic        ahb_irq;

    gps_time_latch #(.BUS_TYPE("AHB"),.CLK_FREQ_HZ(CLK_FREQ),.PPS_TOL_PPM(200)) dut_ahb (
        .pps_in(pps_in),
        .HCLK(clk), .HRESETn(ahb_rst),
        .HSEL(ahb_sel), .HADDR(ahb_addr), .HWRITE(ahb_wr),
        .HTRANS(ahb_trans), .HSIZE(ahb_size), .HBURST(ahb_burst),
        .HWDATA(ahb_wdata), .HRDATA(ahb_rdata), .HREADY(ahb_ready),
        .HRESP(ahb_resp),   .irq(ahb_irq),
        .PCLK(1'b0),.PRESETn(1'b1),.PADDR(32'd0),.PSEL(1'b0),
        .PENABLE(1'b0),.PWRITE(1'b0),.PWDATA(32'd0),
        .ACLK(1'b0),.ARESETn(1'b1),.AWADDR(32'd0),.AWVALID(1'b0),
        .WDATA(32'd0),.WSTRB(4'd0),.WVALID(1'b0),.BREADY(1'b1),
        .ARADDR(32'd0),.ARVALID(1'b0),.RREADY(1'b1)
    );

    // AHB tasks
    task automatic ahb_wr_reg(input logic [31:0] a, d);
        @(posedge clk); #1;
        ahb_sel=1; ahb_addr=a; ahb_wr=1; ahb_trans=2'b10;
        @(posedge clk); #1;
        ahb_wdata=d;
        @(posedge clk); #1;
        ahb_sel=0; ahb_trans=2'b00; ahb_wr=0;
    endtask

    task automatic ahb_rd_reg(input logic [31:0] a, output logic [31:0] d);
        @(posedge clk); #1;
        ahb_sel=1; ahb_addr=a; ahb_wr=0; ahb_trans=2'b10;
        @(posedge clk); #1;
        ahb_sel=0; ahb_trans=2'b00;
        @(posedge clk); #1;
        d=ahb_rdata;
    endtask

    // =========================================================================
    // DUT 3: AXI
    // =========================================================================
    logic        axi_rst;
    logic [31:0] axi_awaddr=0, axi_wdata=0, axi_araddr=0, axi_rdata;
    logic        axi_awvalid=0, axi_awready;
    logic        axi_wvalid=0,  axi_wready;
    logic [3:0]  axi_wstrb=4'hF;
    logic [1:0]  axi_bresp, axi_rresp;
    logic        axi_bvalid, axi_bready=0;
    logic        axi_arvalid=0, axi_arready;
    logic        axi_rvalid,    axi_rready=0;
    logic        axi_irq;

    gps_time_latch #(.BUS_TYPE("AXI"),.CLK_FREQ_HZ(CLK_FREQ),.PPS_TOL_PPM(200)) dut_axi (
        .pps_in(pps_in),
        .ACLK(clk), .ARESETn(axi_rst),
        .AWADDR(axi_awaddr), .AWVALID(axi_awvalid), .AWREADY(axi_awready),
        .WDATA(axi_wdata),   .WSTRB(axi_wstrb),     .WVALID(axi_wvalid),
        .WREADY(axi_wready),
        .BRESP(axi_bresp),   .BVALID(axi_bvalid),   .BREADY(axi_bready),
        .ARADDR(axi_araddr), .ARVALID(axi_arvalid),  .ARREADY(axi_arready),
        .RDATA(axi_rdata),   .RRESP(axi_rresp),      .RVALID(axi_rvalid),
        .RREADY(axi_rready), .irq(axi_irq),
        .PCLK(1'b0),.PRESETn(1'b1),.PADDR(32'd0),.PSEL(1'b0),
        .PENABLE(1'b0),.PWRITE(1'b0),.PWDATA(32'd0),
        .HCLK(1'b0),.HRESETn(1'b1),.HSEL(1'b0),.HADDR(32'd0),
        .HWRITE(1'b0),.HTRANS(2'd0),.HSIZE(3'd0),.HBURST(3'd0),.HWDATA(32'd0)
    );

    // AXI tasks
    task automatic axi_wr_reg(input logic [31:0] a, d);
        @(posedge clk); #1;
        axi_awaddr=a; axi_awvalid=1;
        axi_wdata=d;  axi_wvalid=1;
        do @(posedge clk); while (!(axi_awready && axi_wready));
        #1; axi_awvalid=0; axi_wvalid=0;
        axi_bready=1;
        do @(posedge clk); while (!axi_bvalid);
        #1; axi_bready=0;
    endtask

    task automatic axi_rd_reg(input logic [31:0] a, output logic [31:0] d);
        @(posedge clk); #1;
        axi_araddr=a; axi_arvalid=1;
        do @(posedge clk); while (!axi_arready);
        #1; axi_arvalid=0;
        axi_rready=1;
        do @(posedge clk); while (!axi_rvalid);
        #1; d=axi_rdata; axi_rready=0;
    endtask

    // =========================================================================
    // PPS generator task: issues n_pulses with correct period and duty cycle
    // =========================================================================
    task automatic gen_pps(input int n);
        repeat(n) begin
            repeat(PPS_PERIOD) @(posedge clk);
            pps_in=1'b1;
            repeat(PPS_PULSE)  @(posedge clk);
            pps_in=1'b0;
        end
    endtask

    // =========================================================================
    // Test result tracking
    // =========================================================================
    int pass_cnt=0, fail_cnt=0;

    task automatic chk(input string name, input logic [31:0] got, exp);
        if (got===exp) begin
            $display("  PASS  %-36s  0x%08X", name, got);
            pass_cnt++;
        end else begin
            $display("  FAIL  %-36s  got=0x%08X  exp=0x%08X", name, got, exp);
            fail_cnt++;
        end
    endtask

    task automatic chk_bit(input string name, input logic got, exp);
        chk(name, {31'd0,got}, {31'd0,exp});
    endtask

    // =========================================================================
    // Main test sequence
    // =========================================================================
    logic [31:0] rd;
    logic [31:0] us_snap;

    initial begin
        apb_rst=0; ahb_rst=0; axi_rst=0;
        repeat(20) @(posedge clk);
        apb_rst=1; ahb_rst=1; axi_rst=1;
        $display("");
        $display("====================================================================");
        $display(" GPS Time Latch -- Full Verification Testbench");
        $display(" CLK_FREQ=%0d MHz  PPS_PERIOD=%0d cycles", CLK_FREQ/1_000_000, PPS_PERIOD);
        $display("====================================================================");

        // ====================================================================
        //  GROUP 1 -- APB Interface
        // ====================================================================
        $display("\n--- GROUP 1: APB Interface ---");

        // 1.1  Pending register write/readback
        $display("\n[1.1] Pending GPS time write/readback (APB)");
        apb_wr_reg(32'h00, 32'h0005_4456);   // PEND_SEC_LO  (TOW = 345174 s)
        apb_wr_reg(32'h04, 32'h0000_08F2);   // PEND_SEC_HI  (Week 2290)
        apb_wr_reg(32'h08, 32'h0000_0000);   // PEND_USEC = 0
        apb_rd_reg(32'h00, rd); chk("PEND_SEC_LO", rd, 32'h0005_4456);
        apb_rd_reg(32'h04, rd); chk("PEND_SEC_HI", rd, 32'h0000_08F2);
        apb_rd_reg(32'h08, rd); chk("PEND_USEC",   rd, 32'h0000_0000);

        // 1.2  time_valid should be clear before any PPS
        $display("\n[1.2] time_valid=0 before first PPS");
        apb_rd_reg(32'h24, rd);
        chk_bit("STATUS.time_valid pre-PPS", rd[1], 1'b0);

        // 1.3  Configure: enable latch, auto-increment, all IRQs
        $display("\n[1.3] CONTROL and IRQ_ENABLE configuration");
        apb_wr_reg(32'h28, 32'h09);   // [0]=time_load_en  [3]=auto_inc_en
        apb_wr_reg(32'h30, 32'h07);   // IRQ_ENABLE: all three
        apb_rd_reg(32'h28, rd); chk("CONTROL readback",    rd[3:0], 4'h9);
        apb_rd_reg(32'h30, rd); chk("IRQ_ENABLE readback", rd[2:0], 3'h7);

        // 1.4  Generate 2 PPS pulses; second fires the latch
        $display("\n[1.4] 2x PPS pulses to trigger latch...");
        fork gen_pps(2); join
        repeat(100) @(posedge clk);

        // 1.5  Verify latched active time
        $display("\n[1.5] Active time verification");
        apb_rd_reg(32'h0C, rd); chk("ACT_SEC_LO post-latch", rd, 32'h0005_4456);
        apb_rd_reg(32'h10, rd); chk("ACT_SEC_HI post-latch", rd, 32'h0000_08F2);
        apb_rd_reg(32'h14, rd);
        $display("  INFO  ACT_USEC at latch edge = %0d us (expect ~0 for on-time PPS)", rd);

        // 1.6  STATUS flags
        $display("\n[1.6] STATUS flags");
        apb_rd_reg(32'h24, rd);
        chk_bit("STATUS.time_valid", rd[1], 1'b1);
        chk_bit("STATUS.pps_locked", rd[2], 1'b1);
        $display("  INFO  PPS period in STATUS[31:8] = %0d cycles (expect %0d)",
                 rd[31:8], PPS_PERIOD);

        // 1.7  IRQ verification and W1C clear
        $display("\n[1.7] IRQ flags and W1C clear");
        apb_rd_reg(32'h2C, rd);
        chk_bit("IRQ_STATUS.pps_irq",   rd[0], 1'b1);
        chk_bit("IRQ_STATUS.latch_irq", rd[1], 1'b1);
        chk_bit("IRQ line asserted",    apb_irq, 1'b1);
        apb_wr_reg(32'h2C, 32'h07);   // W1C: clear all
        apb_rd_reg(32'h2C, rd); chk("IRQ_STATUS after W1C clear", rd[2:0], 3'h0);
        repeat(5) @(posedge clk);
        chk_bit("IRQ de-asserted after clear", apb_irq, 1'b0);

        // 1.8  Auto-increment: 3rd PPS should advance run_sec to TOW+1
        $display("\n[1.8] Auto-increment of run_sec on 3rd PPS");
        fork gen_pps(1); join
        repeat(100) @(posedge clk);
        apb_rd_reg(32'h18, rd); chk("CUR_SEC_LO = TOW+1", rd, 32'h0005_4457);
        apb_rd_reg(32'h1C, rd); chk("CUR_SEC_HI stable",  rd, 32'h0000_08F2);
        apb_rd_reg(32'h20, rd);
        $display("  INFO  CUR_USEC snapshot = %0d us after 3rd PPS", rd);

        // 1.9  Microsecond counter: wait ~0.5 s worth of clocks and sample
        $display("\n[1.9] Microsecond counter accuracy (wait 0.5 s)");
        apb_rd_reg(32'h18, rd);   // Trigger snapshot at start
        repeat(PPS_PERIOD/2) @(posedge clk);
        apb_rd_reg(32'h18, rd);   // Trigger snapshot at mid-second
        apb_rd_reg(32'h20, rd);   // Read CUR_USEC from snapshot
        $display("  INFO  CUR_USEC at ~0.5 s = %0d (expect 490000-510000)", rd);
        if (rd >= 32'd480_000 && rd <= 32'd520_000) begin
            $display("  PASS  CUR_USEC within 2%% of 500000"); pass_cnt++;
        end else begin
            $display("  FAIL  CUR_USEC out of 2%% tolerance: %0d", rd); fail_cnt++;
        end

        // 1.10  Wait for 4th PPS to realign
        fork gen_pps(1); join
        repeat(100) @(posedge clk);

        // 1.11  force_latch: immediate latch without waiting for PPS
        $display("\n[1.10] force_latch (CONTROL[2])");
        apb_wr_reg(32'h00, 32'hCAFE_BABE);
        apb_wr_reg(32'h04, 32'h0000_1234);
        apb_wr_reg(32'h28, 32'h0D);   // time_load_en | force_latch | auto_inc_en
        repeat(10) @(posedge clk);
        apb_rd_reg(32'h0C, rd); chk("ACT_SEC_LO after force_latch", rd, 32'hCAFE_BABE);
        apb_rd_reg(32'h10, rd); chk("ACT_SEC_HI after force_latch", rd, 32'h0000_1234);
        apb_rd_reg(32'h28, rd); chk_bit("force_latch self-cleared",  rd[2], 1'b0);

        // 1.12  PPS_PERIOD register
        $display("\n[1.11] PPS_PERIOD register");
        apb_rd_reg(32'h34, rd);
        $display("  INFO  PPS_PERIOD register = %0d cycles (expect %0d)", rd, PPS_PERIOD);
        if (rd >= (PPS_PERIOD - PPS_PERIOD/100) && rd <= (PPS_PERIOD + PPS_PERIOD/100)) begin
            $display("  PASS  PPS_PERIOD within 1%% of expected"); pass_cnt++;
        end else begin
            $display("  FAIL  PPS_PERIOD out of tolerance: %0d", rd); fail_cnt++;
        end

        // 1.13  Unmapped address sentinel
        $display("\n[1.12] Unmapped address error response");
        apb_rd_reg(32'hFF, rd); chk("Unmapped addr = 0xDEADBEEF", rd, 32'hDEAD_BEEF);

        // ====================================================================
        //  GROUP 2 -- AHB Interface
        // ====================================================================
        $display("\n--- GROUP 2: AHB-Lite Interface ---");

        // 2.1  Pending register write/readback
        $display("\n[2.1] Pending time write/readback (AHB)");
        ahb_wr_reg(32'h00, 32'hABCD_1234);
        ahb_wr_reg(32'h04, 32'h0000_0001);
        ahb_wr_reg(32'h28, 32'h09);   // time_load_en + auto_inc_en
        ahb_rd_reg(32'h00, rd); chk("AHB PEND_SEC_LO", rd, 32'hABCD_1234);
        ahb_rd_reg(32'h04, rd); chk("AHB PEND_SEC_HI", rd, 32'h0000_0001);

        // 2.2  PPS latch
        $display("\n[2.2] AHB PPS latch");
        fork gen_pps(2); join
        repeat(100) @(posedge clk);
        ahb_rd_reg(32'h0C, rd); chk("AHB ACT_SEC_LO",    rd, 32'hABCD_1234);
        ahb_rd_reg(32'h10, rd); chk("AHB ACT_SEC_HI",    rd, 32'h0000_0001);
        ahb_rd_reg(32'h24, rd);
        chk_bit("AHB STATUS.time_valid", rd[1], 1'b1);
        chk_bit("AHB STATUS.pps_locked", rd[2], 1'b1);

        // 2.3  Auto-increment
        $display("\n[2.3] AHB auto-increment");
        fork gen_pps(1); join
        repeat(100) @(posedge clk);
        ahb_rd_reg(32'h18, rd); chk("AHB CUR_SEC_LO +1", rd, 32'hABCD_1235);

        // 2.4  Microsecond snapshot
        $display("\n[2.4] AHB microsecond snapshot");
        ahb_rd_reg(32'h18, rd);   // Trigger snapshot
        ahb_rd_reg(32'h20, rd);   // CUR_USEC
        $display("  INFO  AHB CUR_USEC = %0d us (expect small, just after PPS)", rd);
        if (rd < 32'd100_000) begin
            $display("  PASS  AHB CUR_USEC < 100000 as expected shortly after PPS"); pass_cnt++;
        end else begin
            $display("  FAIL  AHB CUR_USEC unexpectedly large: %0d", rd); fail_cnt++;
        end

        // ====================================================================
        //  GROUP 3 -- AXI4-Lite Interface
        // ====================================================================
        $display("\n--- GROUP 3: AXI4-Lite Interface ---");

        // 3.1  Pending register write/readback
        $display("\n[3.1] Pending time write/readback (AXI)");
        axi_wr_reg(32'h00, 32'h1357_2468);
        axi_wr_reg(32'h04, 32'h0000_0055);
        axi_wr_reg(32'h28, 32'h09);
        axi_rd_reg(32'h00, rd); chk("AXI PEND_SEC_LO", rd, 32'h1357_2468);
        axi_rd_reg(32'h04, rd); chk("AXI PEND_SEC_HI", rd, 32'h0000_0055);

        // 3.2  PPS latch
        $display("\n[3.2] AXI PPS latch");
        fork gen_pps(2); join
        repeat(100) @(posedge clk);
        axi_rd_reg(32'h0C, rd); chk("AXI ACT_SEC_LO",    rd, 32'h1357_2468);
        axi_rd_reg(32'h24, rd);
        chk_bit("AXI STATUS.time_valid", rd[1], 1'b1);
        chk_bit("AXI STATUS.pps_locked", rd[2], 1'b1);

        // 3.3  IRQ on AXI
        $display("\n[3.3] AXI IRQ generation and W1C clear");
        axi_wr_reg(32'h30, 32'h03);   // enable pps + latch IRQs
        axi_rd_reg(32'h2C, rd);
        chk_bit("AXI IRQ_STATUS.latch_irq", rd[1], 1'b1);
        axi_wr_reg(32'h2C, 32'h03);
        axi_rd_reg(32'h2C, rd); chk("AXI IRQ_STATUS after W1C", rd[1:0], 2'd0);

        // 3.4  AXI split-channel: AW arrives before W
        $display("\n[3.4] AXI split AW/W channels (AW before W)");
        @(posedge clk); #1;
        axi_awaddr=32'h00; axi_awvalid=1;
        @(posedge clk); #1;   // AW fires; W not yet
        axi_awvalid=0;
        repeat(5) @(posedge clk); #1;
        axi_wdata=32'hFACE_FEED; axi_wvalid=1;
        do @(posedge clk); while (!axi_wready);
        #1; axi_wvalid=0;
        axi_bready=1;
        do @(posedge clk); while (!axi_bvalid);
        #1; axi_bready=0;
        axi_rd_reg(32'h00, rd); chk("AXI split-AW/W write result", rd, 32'hFACE_FEED);

        // 3.5  AXI split-channel: W arrives before AW
        $display("\n[3.5] AXI split AW/W channels (W before AW)");
        @(posedge clk); #1;
        axi_wdata=32'hDECA_FBAD; axi_wvalid=1;
        @(posedge clk); #1;
        axi_wvalid=0;
        repeat(5) @(posedge clk); #1;
        axi_awaddr=32'h00; axi_awvalid=1;
        do @(posedge clk); while (!axi_awready);
        #1; axi_awvalid=0;
        axi_bready=1;
        do @(posedge clk); while (!axi_bvalid);
        #1; axi_bready=0;
        axi_rd_reg(32'h00, rd); chk("AXI split-W/AW write result", rd, 32'hDECA_FBAD);

        // 3.6  AXI auto-increment
        $display("\n[3.6] AXI auto-increment after latch");
        fork gen_pps(1); join
        repeat(100) @(posedge clk);
        axi_rd_reg(32'h18, rd); chk("AXI CUR_SEC_LO +1", rd, 32'h1357_2469);

        // ====================================================================
        //  SUMMARY
        // ====================================================================
        $display("");
        $display("====================================================================");
        $display(" RESULTS:  %0d PASSED   %0d FAILED   (%0d total)",
                 pass_cnt, fail_cnt, pass_cnt+fail_cnt);
        $display("====================================================================");
        if (fail_cnt == 0) $display(" *** ALL TESTS PASSED ***");
        else               $display(" *** FAILURES DETECTED - see FAIL lines above ***");
        $display("");
        $finish;
    end

    // Watchdog
    initial begin
        #2_000_000_000;
        $fatal(1,"[TB] WATCHDOG TIMEOUT after 2 s sim-time");
    end

endmodule : gps_time_latch_tb

`default_nettype wire

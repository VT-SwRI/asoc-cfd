//-----------------------------------------------------------------------------
// Copyright 2006 Actel Corporation.  All rights reserved.
// IP Engineering
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// File:            tb_verif.v
//
// Description:     Verification Testbench for Core8051s
//
// Rev:             1.2  Dec06
//
// Notes:
//
//-----------------------------------------------------------------------------

`timescale 1ns / 100ps

module tb_verif;

    //---------------------------------------------------------------
    parameter   TESTNAME    = "test001";
    parameter   TESTPATH    = "tests";

    //---------------------------------------------------------------
    // Test Bench file names
    //---------------------------------------------------------------
    parameter   EXTROMFILE  = "extrom.hex";
    parameter   ACSCOMPFILE = "acscomp.txt";
    parameter   ACSDIFFFILE = "acsdiff.txt";

    //---------------------------------------------------------------
    // Test Bench environment parameters
    //---------------------------------------------------------------
    parameter   INTRAMSIZE  = 8;   // Internal RAM size index
    parameter   INTROMSIZE  = 12;  // Internal ROM size index
    parameter   EXTRAMSIZE  = 16;  // External RAM size index
    parameter   EXTROMSIZE  = 16;  // External ROM size index
    parameter   CLOCKPERIOD = 20;  // Clock pulse period
    parameter   CLOCKDUTY   = 50;  // Duty cycle (0-100%)
    parameter   ACSCOMPMODE = 2;   // ACS Comparator mode
    // ACS Comparator mode description:
    // 0 - no occurrence
    // 1 - the COMPFILE writer
    // 2 - vectors comparator
    //---------------------------------------------------------------

    // ASCII file for loading program ROM
    //parameter   ROMFILE = {TESTPATH,"/",TESTNAME,"/",EXTROMFILE};
    parameter   ROMFILE = {"opcode_",TESTNAME,"_",EXTROMFILE};

    //---------------------------------------------------------------
    // Core8051s configuration parameters
    //---------------------------------------------------------------
    parameter   DEBUG                   = 0;
    parameter   INCL_TRACE              = 0;
    parameter   TRIG_NUM                = 0;
    parameter   EN_FF_OPTS              = 0;
    parameter   APB_DWIDTH              = 32;
    parameter   INCL_DPTR1              = 0;
    parameter   INCL_MUL_DIV_DA         = 1;
    parameter   VARIABLE_STRETCH        = 1;
    parameter   STRETCH_VAL             = 1;
    parameter   VARIABLE_WAIT           = 1;
    parameter   WAIT_VAL                = 0;
    parameter   INTRAM_IMPLEMENTATION   = 0;

    //---------------------------------------------------------------
    // Test Bench interconnection signals
    //---------------------------------------------------------------
    // External Memory interface
    wire            MEMPSACKI;
    wire            MEMACKI;
    wire    [7:0]   MEMDATAI;
    wire    [7:0]   MEMDATAO;
    wire    [15:0]  MEMADDR;
    wire            MEMPSRD;	// Program store read enable
    wire            MEMWR;		// Memory write enable
    wire            MEMRD;		// Memory read enable

    wire    [7:0]   user_rom_dout;
    wire    [7:0]   ext_ram_dout;

    // APB interface
    wire            PWRITE;
    wire            PENABLE;
    wire    [11:0]  PADDR;
    wire [APB_DWIDTH-1:0] PWDATA;
    wire [APB_DWIDTH-1:0] PRDATA;

    //---------------------------------------------------------------
    // Miscellaneous signals
    //---------------------------------------------------------------
    reg             reset;
    wire            nreset;
    wire            SYSCLK;
    wire            NSYSCLK;
    wire            GND_sig;
    wire            VCC_sig;
    wire    [31:0]  zeroes;
    wire    [31:0]  ones;

    //---------------------------------------------------------------
    // Initialize signals
    //---------------------------------------------------------------
    assign nreset = !reset;
    assign NSYSCLK = ~SYSCLK ;
    assign GND_sig = 1'b0 ;
    assign VCC_sig = 1'b1 ;
    assign zeroes = {32{1'b0}} ;
    assign ones = {32{1'b1}} ;

    //---------------------------------------------------------------
    // Reset signal
    //---------------------------------------------------------------
    initial
    begin
        reset = 1'b1;
        #(CLOCKPERIOD*5);
        reset = 1'b0;
    end

    //---------------------------------------------------------------
    // Test Bench Clock Generator unit
    //---------------------------------------------------------------
    EXTERNAL_CLOCK_GENERATOR
    #(
        .PERIOD     (CLOCKPERIOD),
        .DUTY       (CLOCKDUTY)
    )
    U_EXT_CLOCK (
        .clk        (SYSCLK)
    );

    //---------------------------------------------------------------
    // Test Bench ACS Comparator
    //---------------------------------------------------------------
    EXTERNAL_ACCESS_COMPARATOR
    #(
        .MODE       (ACSCOMPMODE),
        .DATAWIDTH  (8),
        .ADDRWIDTH  (16),
        .TESTNAME   (TESTNAME),
        .TESTPATH   (TESTPATH),
        .COMPFILE   (ACSCOMPFILE),
        .DIFFFILE   (ACSDIFFFILE)
    )
    U_EXT_ACSCOMP (
        .rst        (reset),
        .addrbus    (MEMADDR[15:0]),
        .databus    (MEMDATAO),
        .wr         (MEMWR),
        .PWRITE     (PWRITE),
        .PENABLE    (PENABLE),
        .PWDATA     (PWDATA[7:0]),
        .PADDR      (PADDR[11:0])
    );

    //---------------------------------------------------------------
    // Instantiate Core8051s
    //---------------------------------------------------------------
    CORE8051S
    #(
        .DEBUG                  (DEBUG),
        .INCL_TRACE             (INCL_TRACE),
        .TRIG_NUM               (TRIG_NUM),
        .EN_FF_OPTS             (EN_FF_OPTS),
        .APB_DWIDTH             (APB_DWIDTH),
        .INCL_DPTR1             (INCL_DPTR1),
        .INCL_MUL_DIV_DA        (INCL_MUL_DIV_DA),
        .VARIABLE_STRETCH       (VARIABLE_STRETCH),
        .STRETCH_VAL            (STRETCH_VAL),
        .VARIABLE_WAIT          (VARIABLE_WAIT),
        .WAIT_VAL               (WAIT_VAL),
        .INTRAM_IMPLEMENTATION  (INTRAM_IMPLEMENTATION)
    )
    CORE8051S_inst (
        .CLK        (SYSCLK),
        .NSYSRESET  (nreset),
        .PRESETN    (),
        .WDOGRES    (GND_sig),
        .WDOGRESN   (),
        .INT0       (GND_sig),
        .INT1       (GND_sig),
        .MOVX       (),
        .MEMPSACKI  (VCC_sig),
        .MEMACKI    (VCC_sig),
        .MEMDATAI   (MEMDATAI),
        .MEMDATAO   (MEMDATAO),
        .MEMADDR    (MEMADDR),
        .MEMPSRD    (MEMPSRD),
        .MEMWR      (MEMWR),
        .MEMRD      (MEMRD),
        .TCK        (VCC_sig),
        .TMS        (VCC_sig),
        .TDI        (GND_sig),
        .TDO        (),
        .TRSTN      (VCC_sig),
        .BREAKIN    (GND_sig),
        .BREAKOUT   (),
        .MEMBANK    (zeroes[3:0]),
        .DBGMEMPSWR (),
        .TRIGOUT    (),
        .AUXOUT     (),
        .PWRITE     (PWRITE),
        .PENABLE    (PENABLE),
        .PSEL       (),
        .PADDR      (PADDR),
        .PWDATA     (PWDATA),
        .PRDATA     (PRDATA),
        .PREADY     (VCC_sig),
        .PSLVERR    (GND_sig)
    );

    //----------------------------------------------------------
    // Make APB space appear as a RAM to facilitate tests which
    // read back values previously written.
    //----------------------------------------------------------
    USER_RAM
    #(
        .WIDTH  (APB_DWIDTH),
        .DEPTH  (4096),
        .ASIZE  (12)
    )
    APB_space (
        .wclk   (SYSCLK),
        .waddr  (PADDR),
        .wr     ((PWRITE && PENABLE)),
        .din    (PWDATA),
        .rclk   (NSYSCLK),
        .raddr  (PADDR),
        .rd     ((!PWRITE && PENABLE)),
        .dout   (PRDATA)
    );

    //----------------------------------------------------------
    // Behavioral program ROM
    //----------------------------------------------------------
    USER_ROM
    #(
        .WIDTH  (8),
        .DEPTH  (65536),
        .ASIZE  (16),
        .ROMFILE(ROMFILE)
    )
    program_ROM (
        .clk    (NSYSCLK),
        .oe     (MEMPSRD),
        .addr   (MEMADDR[15:0]),
        .dout   (user_rom_dout)
    );

    //----------------------------------------------------------
    // Behavioral model of external RAM
    //----------------------------------------------------------
    USER_RAM
    #(
        .WIDTH  (8),
        .DEPTH  (65536),
        .ASIZE  (16)
    )
    external_RAM (
        .wclk   (SYSCLK),
        .waddr  (MEMADDR[15:0]),
        .wr     (MEMWR),
        .din    (MEMDATAO),
        .rclk   (NSYSCLK),
        .raddr  (MEMADDR[15:0]),
        .rd     (MEMRD),
        .dout   (ext_ram_dout)
    );

    assign MEMDATAI = (MEMPSRD == 1'b1) ? user_rom_dout : ext_ram_dout;

endmodule

//-----------------------------------------------------------------------------
// Copyright 2006 Actel Corporation.  All rights reserved.
// IP Engineering
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// File:            oci_sys.v
//
// Description:     System for Core8051s OCI testbench
//
// Rev:             1.2  Dec06
//
// Notes:
//
//-----------------------------------------------------------------------------

`timescale 1 ns / 100 ps

                         //-------------------//
                         //                   //
                         // MODULE DEFINITION //
                         //                   //
                         //-------------------//
module oci_sys (
   clk,             // CPU clock input
   resetiB,         // System reset input (active low)
   tck,             // JTAG clock
   tdi,             // JTAG data in
   tms,             // JTAG mode in
   tdo,             // JTAG data out
   TRSTB,           // JTAG reset
   TrigOut,         // OCI trigger output
   BreakIn,         // Break bus input
   BreakOut,        // Break bus output
   AuxOut           // Aux output
);

`include "jtagdef.v"

    // DEBUG controls whether or not the On Chip Instrumentation (OCI)
    // debug block is included and also the nature of the JTAG connection
    // used for debugging. The JTAG connection can be implemented using
    // either the UJTAG macro or by making use of general purpose I/O pins
    // on the FPGA. DEBUG is used to set the values of the internal parameters
    // USE_OCI and USE_UJTAG.
    // Settings for DEBUG are as follows:
    //
    // DEBUG  USE_OCI  USE_UJTAG  Comments
    // --------------------------------------------------------------
    //   0       0         0      OCI block not included
    //   1       1         0      OCI included, UJTAG macro not used
    //   2       1         1      OCI included, UJTAG macro in use
    //
    parameter DEBUG         = 1;
    // set this to 1 to include OCI trace RAM
    parameter INCL_TRACE    = 1;
	// TRIG_NUM
	// no triggers:  set value to 0
	//  1 trigger:   set value to 1
	//  2 triggers:  set value to 2
	//  4 triggers:  set value to 4
    parameter TRIG_NUM		= 0;
	//----- various rtl optimizations for synthesis size reductions ------
	// set to 1 to enable ff optimizations ...
    parameter EN_FF_OPTS	= 0;
    // APB data width - possible values are 8, 16 or 32
    parameter APB_DWIDTH    = 32;
    // set to 1 to include second data pointer (DPTR1)
    parameter INCL_DPTR1    = 1;
    // set to 1 to include multiply, divide and decimal-adjust instruction functionality
    parameter INCL_MUL_DIV_DA = 1;
    // set to 1 to use MEMACKI control for external data memory
    parameter VARIABLE_STRETCH = 1;
    // fixed setting for stretch, only applicable if VARIABLE_STRETCH = 0
    // range is 0 to 7
    parameter STRETCH_VAL   = 1;
    // set to 1 to use MEMPSACKI control for program memory
    parameter VARIABLE_WAIT = 1;
    // fixed setting for wait, only applicable if VARIABLE_WAIT = 0
    // range is 0 to 7
    parameter WAIT_VAL      = 0;
    // INTRAM_IMPLEMENTATION controls the implementation of the internal (256x8) RAM.
    //  0 = instantiate RAM blocks
    //  1 = infer RAM blocks during synthesis
    //  2 = infer registers during synthesis
    parameter INTRAM_IMPLEMENTATION = 0;
    // WAITSTATES
    //  For simulation, determines the waitstate count for memory.
    //  This value is not used in synthesis.
    parameter WAITSTATES	= 0;


input   clk;
input   resetiB;
input   tck;
input   tdi;
input   tms;
output  tdo;
input   TRSTB;
output  TrigOut;
input   BreakIn;
output  BreakOut;
output  AuxOut;

                         //-------------------//
                         //                   //
                         //  LOCAL VARIABLES  //
                         //                   //
                         //-------------------//

reg  [7:0] waitcount;

// Program Memory Interface
wire [15:0] memaddr;
wire [3:0] membank;
wire [7:0] memdatai;
wire [7:0] memdatao;
wire mempswr;
wire mempsrd;
wire memwr;
wire memrd;
wire mempsack;
wire mempsacko;
wire memacki;

wire dbgmempswr;
// Stop X propagation through netlist ...
reg [7:0] Pmem_no_x;

// Internal storage
reg [7:0] Pmem[65535:0];    // Program memory
reg [7:0] Xmem[65535:0];    // External data memory

// misc. signals
wire    [31:0]  zeroes;
wire    [31:0]  ones;
wire            GND_sig;
wire            VCC_sig;

    //---------------------------------------------------------------
    // initialize signals
    //---------------------------------------------------------------
    assign GND_sig = 1'b0 ;
    assign VCC_sig = 1'b1 ;
    assign zeroes = {32{1'b0}} ;
    assign ones = {32{1'b1}} ;
    assign memacki = 1;

                         //-------------------//
                         //                   //
                         //  INSTANTIATIONS   //
                         //                   //
                         //-------------------//

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
        .CLK        (clk),
        .NSYSRESET  (resetiB),
        .PRESETN    (),
        .WDOGRES    (GND_sig),
        .WDOGRESN   (),
        .INT0       (GND_sig),
        .INT1       (GND_sig),
        .MOVX       (),
        .MEMPSACKI  (mempsack),
        .MEMACKI    (memacki),
        .MEMDATAI   (memdatai),
        .MEMDATAO   (memdatao),
        .MEMADDR    (memaddr),
        .MEMPSRD    (mempsrd),
        .MEMWR      (memwr),
        .MEMRD      (memrd),
        .TCK        (tck),
        .TMS        (tms),
        .TDI        (tdi),
        .TDO        (tdo),
        .TRSTN      (TRSTB),
        .BREAKIN    (BreakIn),
        .BREAKOUT   (BreakOut),
        .MEMBANK    (membank),
        .DBGMEMPSWR (dbgmempswr),
        .TRIGOUT    (TrigOut),
        .AUXOUT     (AuxOut),
        .PWRITE     (),
        .PENABLE    (),
        .PSEL       (),
        .PADDR      (),
        .PWDATA     (),
        .PRDATA     (zeroes[APB_DWIDTH-1:0]),
        .PREADY     (VCC_sig),
        .PSLVERR    (GND_sig)
    );

                         //-------------------//
                         //                   //
                         //  MEMORIES         //
                         //  FOR SIMULATION   //
                         //                   //
                         //-------------------//

always @(posedge clk or negedge resetiB) begin
   if (!resetiB)
      waitcount <= 0;
   else begin
      if ((~mempswr & ~mempsrd) | mempsack) begin
         waitcount <= WAITSTATES;
      end else if (waitcount != 0) begin
         waitcount <= waitcount - 1;
      end
   end
end

assign mempsack = ~(mempsrd & (waitcount != 0));
assign mempswr = 1'b0;

//
// Program memory handling
// Xdata memory handling
//

always @(posedge clk) begin
   if (resetiB & dbgmempswr)
      Pmem[{membank[3:0],memaddr[15:0]}] <= memdatao[7:0];
   if (resetiB & memwr)
      Xmem[{membank[3:0],memaddr[15:0]}] <= memdatao[7:0];
end

// Stop X propagation through netlist ...
always @ (membank or memaddr or resetiB)
begin: no_x_prop
integer i;
	if (!resetiB)
		Pmem_no_x = 8'hff;
	else
	begin
		for (i=0;i<8;i=i+1)
		begin
			if (Pmem[{membank[3:0],memaddr[15:0]}][i] == 1'b0)
				Pmem_no_x[i] = 1'b0;
			else
				Pmem_no_x[i] = 1'b1;
		end
	end
end

assign memdatai = memrd ? Xmem[{membank[3:0],memaddr[15:0]}] :
                 (mempsrd & mempsack) ? Pmem_no_x :
                 8'h99;

assign membank = 0;

endmodule

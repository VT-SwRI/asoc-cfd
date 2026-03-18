//-----------------------------------------------------------------------------
// Copyright 2006 Actel Corporation.  All rights reserved.
// IP Engineering
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// File:            tb_oci_sys.v
//
// Description:     Top-level Verification OCI testbench for Core8051s
//
// Rev:             1.2  Dec06
//
// Notes:
//
//-----------------------------------------------------------------------------

`timescale 1 ns / 100 ps

`define CLK_half 50       // CLK is 10 MHz
`define TCK_half 60       // TCK is 8.33 MHz (max is CLK)


                         //-------------------//
                         //                   //
                         // MODULE DEFINITION //
                         //                   //
                         //-------------------//
module tb_oci_sys;

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
// WAITSTATES
//    For simulation, determines the waitstate count for memory.
//    This value is not used in synthesis.
parameter WAITSTATES	= 0;

// Local parameter TRACE_DEPTH derived from INCL_TRACE parameter.
// Depth of trace memory is fixed at 256 (2^8) if it is included.
localparam TRACE_DEPTH = (INCL_TRACE == 1) ? 8 : 0;


                         //-------------------//
                         //                   //
                         //  LOCAL VARIABLES  //
                         //                   //
                         //-------------------//
integer fp;                 // sim.log file descriptor
reg [7:0] ckcon_value;

reg clkcpu, resetiB;
reg TCK, TMS, TDI, TRSTB;
reg TCKenable;

reg  BreakIn;
wire BreakOut;

wire TDO;
wire TrigOut;
wire AuxOut;

reg [39:0] TDOsr;
reg [39:0] TDOlat;
reg [39:0] TDOout;

                         //-------------------//
                         //                   //
                         //  INSTANTIATIONS   //
                         //                   //
                         //-------------------//

oci_sys
    #(
        .DEBUG              (DEBUG),
        .INCL_TRACE         (INCL_TRACE),
        .TRIG_NUM           (TRIG_NUM),
        .EN_FF_OPTS         (0),
        .APB_DWIDTH         (32),
        .INCL_DPTR1         (1),
        .INCL_MUL_DIV_DA    (1),
        .VARIABLE_STRETCH   (1),
        .STRETCH_VAL        (1),
        .VARIABLE_WAIT      (1),
        .WAIT_VAL           (0),
        .WAITSTATES         (WAITSTATES)
    )
    oci_sys_inst (
        .clk                (clkcpu),
        .resetiB            (resetiB),
        .tck                (TCK),
        .tdi                (TDI),
        .tms                (TMS),
        .tdo                (TDO),
        .TRSTB              (TRSTB),
        .TrigOut            (TrigOut),
        .BreakIn            (BreakIn),
        .BreakOut           (BreakOut),
        .AuxOut             (AuxOut)
);


//
// CLK source
//
initial begin
   clkcpu = 0;
   #`CLK_half forever #`CLK_half clkcpu = ~clkcpu;
end

//
// TCK source
//
initial begin
   TCK = 0;
   #`TCK_half forever #`TCK_half TCK = TCKenable & ~TCK;
end


//
// Main simulation driver
//
initial begin
   fp = $fopen("ocisim.log") | 1; // $fdisplay() goes to both stdout and sim.log
   $fdisplay(fp,"--------------------------------------");
   $fdisplay(fp,"TRIG_NUM = %1d", TRIG_NUM);
   $fdisplay(fp,"WAITSTATES = %1d", WAITSTATES);
   $fdisplay(fp,"DEBUG = %1d", DEBUG);
   $fdisplay(fp,"--");

   ckcon_value = 8'h01;

   BreakIn = 0;

   TCKenable = 1;
   TDI = 0;
   TMS = 0;
   TRSTB = 0;   // force TAP reset (needed for simulation)
   resetiB = 0;

   #10 TRSTB = 1;
   #500 resetiB = 1;

   #1000

   //
   // Run the tests
   //
   IdcodeTest;              // verify JTAG idcode
   TriggerWriteReadTest;    // access to trigger registers
   if (TRACE_DEPTH > 0)
     TraceWriteReadTest;    // access to trace memory
   AuxOutTest;              // AuxOut signal
   ResetTest;               // Reset functions
   GoHaltTest;              // debugack/debugreq behavior
   TrapTest;                // software breakpoint trap instruction
   BreakBusTest;            // BreakIn/BreakOut signals
   StepTest;                // Single-step
   RegTest;                 // Test mechanism to extract registers at bkpt
   MemTest;                 // Read/write memory from debugger
   if (TRACE_DEPTH > 0)
     TraceTest;             // Collect branch-mode trace
   if (TRIG_NUM > 0)
      TriggerTest;          // Complex triggers

   $fdisplay(fp,"Simulation completed successfully.");
   $stop;
end

                         //-------------------//
                         //                   //
                         //  FUNCTION TESTS   //
                         //                   //
                         //-------------------//

//---------------------------------------------------------------------------
// IdcodeTest
//
// Shift in IDCODE JTAG instruction.  Verify that IDCODE reported
// back to debugger is the expected value.
//
//---------------------------------------------------------------------------
task IdcodeTest;
   begin
      $fdisplay(fp,"IdcodeTest");
      IR8(IR_IDCODE);
      DR8(8'h00);
      if (DEBUG == 2)
        CheckTDO(40'h0000000068, "IDCODE");
      else
        CheckTDO(40'h0000000060, "IDCODE");
   end
endtask


//---------------------------------------------------------------------------
// TriggerWriteReadTest
//
// Write then read all trigger configuration registers.  Verifies that
// the registers are accessible from the debugger.
//
//---------------------------------------------------------------------------
task TriggerWriteReadTest;
   begin
      $fdisplay(fp,"TriggerWriteReadTest");
      IR8(IR_Trigger+0);
      DR40(40'h55AA5AA55A);
      IR8(IR_Trigger+1);
      DR40(40'hAA55A55AA5);
      IR8(IR_Trigger+2);
      DR40(40'h33CC3CC33C);
      IR8(IR_Trigger+3);
      DR40(40'hCC33C33CC3);

      IR8(IR_Trigger+0);
      DR40(40'hAA55A55AA5);
      CheckTDO((TRIG_NUM >= 1) ? 40'h55AA5AA55A : 40'h0, "Trigger 0");
      IR8(IR_Trigger+1);
      DR40(40'h55AA5AA55A);
      CheckTDO((TRIG_NUM >= 2) ? 40'hAA55A55AA5 : 40'h0, "Trigger 1");
      IR8(IR_Trigger+2);
      DR40(40'hCC33C33CC3);
      CheckTDO((TRIG_NUM >= 3) ? 40'h33CC3CC33C : 40'h0, "Trigger 2");
      IR8(IR_Trigger+3);
      DR40(40'h33CC3CC33C);
      CheckTDO((TRIG_NUM >= 4) ? 40'hCC33C33CC3 : 40'h0, "Trigger 3");

      IR8(IR_Trigger+0);
      DR40(40'h0000000000);
      CheckTDO((TRIG_NUM >= 1) ? 40'hAA55A55AA5 : 40'h0, "Trigger 0");
      IR8(IR_Trigger+1);
      DR40(40'h0000000000);
      CheckTDO((TRIG_NUM >= 2) ? 40'h55AA5AA55A : 40'h0, "Trigger 1");
      IR8(IR_Trigger+2);
      DR40(40'h0000000000);
      CheckTDO((TRIG_NUM >= 3) ? 40'hCC33C33CC3 : 40'h0, "Trigger 2");
      IR8(IR_Trigger+3);
      DR40(40'h0000000000);
      CheckTDO((TRIG_NUM >= 4) ? 40'h33CC3CC33C : 40'h0, "Trigger 3");
   end
endtask

//---------------------------------------------------------------------------
// TraceWriteReadTest
//
// Write then read all trace RAM locations.  Verifies that the RAM is
// present, the right size, and is accessible from the debugger.
//
//---------------------------------------------------------------------------
task TraceWriteReadTest;
   integer i;
   integer size;
   begin
      $fdisplay(fp,"TraceWriteReadTest");
      size = 1<<TRACE_DEPTH;

      // first verify we can write to the trace address register
      IR8(IR_TraceStop);
      IR8(IR_TraceClear);
      DR8(8'h55);
      CheckTDO(40'h00, "TraceClear");

      IR8(IR_TraceAddr);
      CheckTDO(40'b00000011, "IR status after TraceClear");
      DR8(8'h55);
      DR8(8'hAA);
      CheckTDO(40'h55, "TraceAddr");
      DR8(8'h00);           // initialize address to 0
      CheckTDO(40'hAA, "TraceAddr");
      IR8(IR_TraceData);

      // Test each location in ram for uniqueness and ability to hold both 0 and 1
      for (i=0; i<size; i=i+1) DR24({~i[7:0],i[7:0],~i[7:0]});

      IR8(IR_TraceAddr);
      CheckTDO(40'b00010011, "IR status after trace wrap");
      DR8(8'h00);           // initialize address to 0
      IR8(IR_TraceData);

      for (i=0; i<size; i=i+1) begin
         DR24({i[7:0],~i[7:0],i[7:0]});
         CheckTDO({20'h00000, ~i[3:0], i[7:0], ~i[7:0]}, "Trace memory");
      end

      IR8(IR_TraceAddr);
      CheckTDO(40'b00010011, "IR status after trace wrap");
      DR8(8'h00);           // initialize address to 0
      IR8(IR_TraceData);

      for (i=0; i<size; i=i+1) begin
         DR24(0);
         CheckTDO({20'h00000, i[3:0], ~i[7:0], i[7:0]}, "Trace memory");
      end

      // verify that a write to address "size" wraps to address 0.
      if (size < 256) begin
         IR8(IR_TraceAddr);
         DR8(size);            // set address to "size"
         IR8(IR_TraceData);
         DR24(24'h123456);     // write test data

         IR8(IR_TraceAddr);
         DR8(8'h00);           // set address to 0
         IR8(IR_TraceData);
         DR24(0);              // read data
         CheckTDO({20'h00000, 20'h23456}, "Trace memory wrap");
      end

      IR8(IR_TraceClear);
      CheckTDO(40'b00010011, "IR status after trace wrap");
      IR8(IR_TraceAddr);
      CheckTDO(40'b00000011, "IR status after trace clear");

   end
endtask

//---------------------------------------------------------------------------
// AuxOutTest
//
//---------------------------------------------------------------------------
task AuxOutTest;
   begin
      $fdisplay(fp,"AuxOutTest");
      TRSTB = 0;
      #100;
      TRSTB = 1;
      CheckSignal(AuxOut, 0, "AuxOut step 1");
      IR8(IR_AuxOn);
      repeat (2) @(posedge TCK);
      CheckSignal(AuxOut, 1, "AuxOut step 2");
      IR8(IR_AuxOff);
      repeat (2) @(posedge TCK);
      CheckSignal(AuxOut, 0, "AuxOut step 3");
      IR8(IR_AuxOn);
      repeat (2) @(posedge TCK);
      CheckSignal(AuxOut, 1, "AuxOut step 4");
      TRSTB = 0;
      #100;
      TRSTB = 1;
      CheckSignal(AuxOut, 0, "AuxOut step 5");
   end
endtask


//---------------------------------------------------------------------------
// ResetTest
//
//---------------------------------------------------------------------------
task ResetTest;
   begin
      $fdisplay(fp,"ResetTest");

      //
      // Debugger-initiated reset
      //
      Reset;
      IR8(IR_DebugNop);                     // check status thru JTAG
      CheckTDO(40'b00001101, "IR status 4");   // Stop state (debugreq and debugack)

      IR8(IR_GetPC);
      DR24(0);
      CheckTDO(40'h0, "GetPC after probe reset");

      InitMemory;

      //
      // debugger not installed case (TRSTB low during reset)
      //
      TRSTB = 0;
      resetiB = 0;
      repeat (8) @(posedge clkcpu);
      resetiB = 1;
      repeat (2) @(posedge clkcpu);
      TRSTB = 1;
      IR8(IR_DebugNop);                     // check status thru JTAG
      CheckTDO(40'b00000011, "IR status 1");   // Run state (debugreq and debugack)

      //
      // Debugger installed at system reset (TRSTB high during reset)
      //
      resetiB = 0;
      repeat (8) @(posedge clkcpu);
      resetiB = 1;
      repeat (2) @(posedge clkcpu);
      IR8(IR_DebugNop);                     // check status thru JTAG
      CheckTDO(40'b00000011, "IR status 2"); // reset state
      IR8(IR_DebugReqOn);                   // emerge from reset into debug mode
      CheckTDO(40'b00000011, "IR status 3"); // First read sampled before debugreq is on
      IR8(IR_DebugReqOn);
      CheckTDO(40'b00001101, "IR status 3a"); // Debugreq is on, JReset is off.

      IR8(IR_GetPC);
      DR24(0);
      CheckTDO(40'h0, "GetPC after system reset");

   end
endtask


//---------------------------------------------------------------------------
// GoHaltTest
//
// Submission of halt and go commands to the OCI.  Checks action
// of debugreq/debugack handshake to core.  Tests DebugStep function.
// Tests TRAP function.
//
//---------------------------------------------------------------------------
task GoHaltTest;
   begin
      $fdisplay(fp,"GoHaltTest");
      Reset;
      MemWriteS(8'h8e, ckcon_value);
      Go;
      IR8(IR_DebugNop);                     // check status
      CheckTDO(40'b00000001, "IR status");   // normal run state
      Halt;
      IR8(IR_DebugNop);                     // check status thru JTAG
      CheckTDO(40'b00001101, "IR status");   // Stop state (debugreq and debugack)

   end
endtask

//---------------------------------------------------------------------------
// TrapTest
//
// Submission of halt and go commands to the OCI.  Checks action
// of debugreq/debugack handshake to core.  Tests DebugStep function.
// Tests TRAP function.
//
//---------------------------------------------------------------------------
task TrapTest;
   begin
      $fdisplay(fp,"TrapTest");
      //
      // TRAP (software breakpoint) test
      //
      Reset;
      MemWriteS(8'h8e, ckcon_value);

      MemWriteP(8'h00, 8'h0A, 8'ha5);        // TRAP instruction
      Go;
      WaitFordebugack(200,1);
      repeat (2) @(posedge clkcpu);
      IR8(IR_DebugNop);                     // check status
      CheckTDO(40'b00001101, "IR status");   // Normal stop state
      Checkmemaddr(16'hB, "memaddr after trap"); // CPU stopped at right address?
      IR8(IR_GetPC);
      DR24(0);
      CheckTDO(40'hB, "GetPC after trap");

      GetReg(8'hE9);
      CheckTDO(40'h55, "R1 after trap");
      GetReg(8'hE8);
      CheckTDO(40'h00, "R0 after trap");

      MemWriteP(8'h00, 8'h0A, 8'h00);
   end
endtask

//---------------------------------------------------------------------------
// BreakBusTest
//
// BreakIn and BreakOut signals
//
//---------------------------------------------------------------------------
task BreakBusTest;
   begin
      $fdisplay(fp,"BreakBusTest");
      //
      // brkbus test
      //
      Reset;
      MemWriteS(8'h8e, ckcon_value);
      MemWriteP(8'h00, 8'h0A, 8'ha5);        // TRAP instruction
      Go;
      repeat (10) @(posedge clkcpu);
      CheckSignal(BreakOut, 0, "BreakOut step 1");
      WaitFordebugack(200,1);
      repeat (2) @(posedge clkcpu);
      CheckSignal(BreakOut, 1, "BreakOut step 3");
      IR8(IR_DebugNop);                     // check status
      CheckTDO(40'b00001101, "IR status");   // Normal stop state
      MemWriteP(8'h00, 8'h0A, 8'h00);

      //
      // BreakIn breakpoint
      //
      Reset;
      MemWriteS(8'h8e, ckcon_value);
      Go;
      repeat (10) @(posedge clkcpu);
      CheckSignal(BreakOut, 0, "BreakOut step 4");
      repeat (5) @(posedge clkcpu);
      BreakIn = 1;                           // external break bus assertion
      CheckSignal(BreakOut, 0, "BreakOut step 5");
      repeat (5) @(posedge clkcpu);
      WaitFordebugack(50,1);
      repeat (2) @(posedge clkcpu);
      CheckSignal(BreakOut, 1, "BreakOut step 6");
      IR8(IR_DebugNop);                     // check status
      CheckTDO(40'b01001101, "IR status");   // BreakIn stop state

      Reset;
      MemWriteS(8'h8e, ckcon_value);
      BreakIn = 0;
      IR8(IR_DebugNop);                     // check status
      CheckTDO(40'b00001101, "IR status");   // Normal stop state
   end
endtask

//---------------------------------------------------------------------------
// StepTest
//
// Single-step
//
//---------------------------------------------------------------------------
task StepTest;
   begin
      $fdisplay(fp,"StepTest");
      Reset;
      MemWriteS(8'h8e, ckcon_value);

      Step;
      Checkmemaddr(16'h2, "memaddr after step");
      IR8(IR_GetPC);
      DR24(0);
      CheckTDO(40'h2, "GetPC after step");
      Step;
      Checkmemaddr(16'h4, "memaddr after step");
      Step;
      Checkmemaddr(16'h5, "memaddr after step");
      Step;
      Checkmemaddr(16'h6, "memaddr after step");
      Step;
      Checkmemaddr(16'h7, "memaddr after step");
      Step;
      Checkmemaddr(16'h8, "memaddr after step");
      Step;
      Checkmemaddr(16'h9, "memaddr after step");
      Step;
      Checkmemaddr(16'ha, "memaddr after step");
      Step;
      Checkmemaddr(16'hb, "memaddr after step");
      Step;
      Checkmemaddr(16'hc, "memaddr after step");
      Step;
      Checkmemaddr(16'hd, "memaddr after step");
      Step;
      Checkmemaddr(16'h7, "memaddr after step");
      IR8(IR_GetPC);
      DR24(0);
      CheckTDO(40'h7, "GetPC after step");

   end
endtask

//---------------------------------------------------------------------------
// RegTest
//
// Test mechanism to extract registers after a breakpoint.
//
//---------------------------------------------------------------------------
task RegTest;
   begin
      $fdisplay(fp,"RegTest");
      Reset;
      MemWriteS(8'h8e, ckcon_value);
      Step;
      Step;   // At this point, R0 should be 0x00 and R1 should be 0x55.
      Checkmemaddr(16'h4, "memaddr after step");

      GetReg(8'hE9);
      CheckTDO(40'h55, "R1 after step");

      GetReg(8'hE8);
      CheckTDO(40'h00, "R0 after step");

      //
      // Set register and verify
      //
      SetReg(8'h78, 8'h23);
      GetReg(8'hE8);
      CheckTDO(40'h23, "R0 after setreg");

      SetReg(8'h79, 8'ha8);
      GetReg(8'hE9);
      CheckTDO(40'ha8, "R1 after setreg");

      //
      // Verify that new registers sticky through emulation
      //
      Step;
      Checkmemaddr(16'h5, "memaddr after step");
      GetReg(8'hE8);
      CheckTDO(40'h23, "R0 after setreg and step");
      GetReg(8'hE9);
      CheckTDO(40'ha8, "R1 after setreg and step");

      //
      // Change PC
      //
      SetPc(16'h0002);
      Checkmemaddr(16'h2, "memaddr after setpc");
      Step;
      Checkmemaddr(16'h4, "memaddr after setpc and step");
      GetReg(8'hE8);
      CheckTDO(40'h23, "R0 after set PC");
      GetReg(8'hE9);
      CheckTDO(40'h55, "R1 after set PC");

   end
endtask

//---------------------------------------------------------------------------
// MemTest
//
// Test read/write memory mechanism
//
//---------------------------------------------------------------------------
task MemTest;
   begin
      $fdisplay(fp,"MemTest");
      Reset;
      MemWriteP(8'h00, 8'h00, 8'h75);   // mov 0xF0,#0x10  -- B register
      MemWriteP(8'h00, 8'h01, 8'hF0);
      MemWriteP(8'h00, 8'h02, 8'h10);
      MemWriteP(8'h00, 8'h03, 8'h75);   // mov 0x55,#0x23  -- initialize
      MemWriteP(8'h00, 8'h04, 8'h55);
      MemWriteP(8'h00, 8'h05, 8'h23);
      MemWriteP(8'h00, 8'h06, 8'h90);   // mov DPTR,#0x1234
      MemWriteP(8'h00, 8'h07, 8'h12);
      MemWriteP(8'h00, 8'h08, 8'h34);
      MemWriteP(8'h00, 8'h09, 8'hE0);   // movx a,@dptr
      MemWriteP(8'h00, 8'h0A, 8'h04);   // inc a
      MemWriteP(8'h00, 8'h0B, 8'hF0);   // movx @dptr,a
      MemWriteP(8'h00, 8'h0C, 8'hE5);   // mov a,0x55
      MemWriteP(8'h00, 8'h0D, 8'h55);
      MemWriteP(8'h00, 8'h0E, 8'h04);   // inc a
      MemWriteP(8'h00, 8'h0F, 8'hF5);   // mov 0x55,a
      MemWriteP(8'h00, 8'h10, 8'h55);

      MemWriteP(8'h00, 8'h11, 8'ha5);   // bkpt
      MemWriteP(8'h00, 8'h12, 8'h80);   // sjmp 9
      MemWriteP(8'h00, 8'h13, 8'hF5);
      MemWriteP(8'h00, 8'h14, 8'h00);

      MemWriteP(8'h12, 8'h34, 8'h00);
      MemWriteP(8'h45, 8'h67, 8'h00);
      MemWriteX(8'h12, 8'h34, 8'h00);
      MemWriteX(8'h45, 8'h67, 8'h00);

      SetReg(8'h78, 8'h00);
      SetReg(8'h79, 8'h00);

      Reset;
      MemWriteS(8'h8e, ckcon_value);
      Go;
      WaitFordebugack(1000,1);     // hits breakpoint
      Checkmemaddr(16'h12, "memaddr after bkpt");

      MemReadS(8'h83);
      CheckTDO(40'h12, "DPH after bkpt");
      MemReadS(8'h82);
      CheckTDO(40'h34, "DPL after bkpt");
      MemReadX(8'h12, 8'h34);
      CheckTDO(40'h01, "Xdata[1234] after bkpt");
      MemReadX(8'h45, 8'h67);
      CheckTDO(40'h00, "Xdata[4567] after bkpt");
      MemReadC(8'h12, 8'h34);
      CheckTDO(40'h00, "Code[1234] after bkpt");
      MemReadC(8'h45, 8'h67);
      CheckTDO(40'h00, "Code[4567] after bkpt");
      MemReadI(8'h55);
      CheckTDO(40'h24, "Idata[55] after bkpt");
      MemReadS(8'hF0);
      CheckTDO(40'h10, "SFR[F0] after bkpt");

      MemWriteS(8'h83, 8'h12);  // restore DPTR
      MemWriteS(8'h82, 8'h34);
      Go;
      WaitFordebugack(200,1);
      Checkmemaddr(16'h12, "memaddr after bkpt2");
      MemReadS(8'h83);
      CheckTDO(40'h12, "DPH after bkpt2");
      MemReadS(8'h82);
      CheckTDO(40'h34, "DPL after bkpt2");
      MemReadX(8'h12, 8'h34);
      CheckTDO(40'h02, "Xdata[1234] after bkpt2");
      MemReadX(8'h45, 8'h67);
      CheckTDO(40'h00, "Xdata[4567] after bkpt2");
      MemReadC(8'h12, 8'h34);
      CheckTDO(40'h00, "Code[1234] after bkpt2");
      MemReadC(8'h45, 8'h67);
      CheckTDO(40'h00, "Code[4567] after bkpt2");
      MemReadI(8'h55);
      CheckTDO(40'h25, "Idata[55] after bkpt2");
      MemReadS(8'hF0);
      CheckTDO(40'h10, "SFR[F0] after bkpt2");

      MemWriteI(8'h55,8'h67);
      MemWriteS(8'hF0,8'h8E);
      //MemWriteS(8'h96,8'h55);      // our ESFR port
      //MemWriteS(8'h94,8'hF0);
      MemReadI(8'h55);
      CheckTDO(40'h67, "Idata[55] write verify");
      MemReadS(8'hF0);
      CheckTDO(40'h8E, "SFR[F0] write verify");
      //MemReadS(8'h96);
      //CheckTDO(40'h55, "SFR[96] write verify");
      //MemReadS(8'h94);
      //CheckTDO(40'hF0, "SFR[94] write verify");

      MemWriteS(8'h83, 8'h12);  // restore DPTR
      MemWriteS(8'h82, 8'h34);
      Go;
      WaitFordebugack(200,1);
      Checkmemaddr(16'h12, "memaddr after bkpt 3");

      // Read again
      MemReadI(8'h55);
      CheckTDO(40'h68, "Idata[55]");
      MemReadS(8'hF0);
      CheckTDO(40'h8E, "SFR[F0]");
      //MemReadS(8'h96);
      //CheckTDO(40'h55, "SFR[96]");
      //MemReadS(8'h94);
      //CheckTDO(40'hF0, "SFR[94]");
      MemReadX(8'h12, 8'h34);
      CheckTDO(40'h03, "Xdata[1234]");

      //
      // Test halt from idle state
      //
// This test is removed because oci_sys has been changed to turn off the clock in
// idle mode.  With clocks off, the OCI cannot gain control of the CPU.
//      MemWriteP(8'h00, 8'h00, 8'hE5);  // mov a,pcon
//      MemWriteP(8'h00, 8'h01, 8'h87);
//      MemWriteP(8'h00, 8'h02, 8'h44);  // orl a, #1
//      MemWriteP(8'h00, 8'h03, 8'h01);
//      MemWriteP(8'h00, 8'h04, 8'hF5);  // mov pcon,a
//      MemWriteP(8'h00, 8'h05, 8'h87);
//      MemWriteP(8'h00, 8'h06, 8'h00);
//      MemWriteP(8'h00, 8'h07, 8'h00);
//      MemWriteP(8'h00, 8'h08, 8'h00);
//      MemWriteP(8'h00, 8'h09, 8'h00);
//      MemWriteP(8'h00, 8'h0A, 8'h00);
//      MemWriteP(8'h00, 8'h0B, 8'h00);
//      MemWriteP(8'h00, 8'h0C, 8'h00);
//      MemWriteP(8'h00, 8'h0D, 8'h00);
//      MemWriteP(8'h00, 8'h0E, 8'h80);  // sjmp *
//      MemWriteP(8'h00, 8'h0F, 8'hFE);
//      Reset;
//      MemWriteS(8'h8e, ckcon_value);
//      SetReg(8'h7A, 8'h34);  // R2=34
//      SetReg(8'h79, 8'h97);  // R1=97
//      Go;
//      repeat (20) @(posedge clkcpu);
//      Halt;
//      MemReadI(8'h02);
//      CheckTDO(40'h34, "REG2 after idle");
//      MemReadI(8'h01);
//      CheckTDO(40'h97, "REG1 after idle");

   end
endtask


//---------------------------------------------------------------------------
// TraceTest
//
// Verify trace collection
//
//---------------------------------------------------------------------------
task TraceTest;
   integer i;
   integer traceDepth;
   reg [7:0] traceaddr;
   begin
      $fdisplay(fp,"TraceTest");

      for (i=0; i<256; i=i+1) MemWriteP(i[15:8], i[7:0], 8'h00);

      MemWriteP(8'h00, 8'h00, 8'h00);   // nop
      MemWriteP(8'h00, 8'h01, 8'he0);   // movx a,@dptr
      MemWriteP(8'h00, 8'h02, 8'h04);   // inc a
      MemWriteP(8'h00, 8'h03, 8'hf0);   // movx @dptr,a
      MemWriteP(8'h00, 8'h04, 8'h00);   // nop
      MemWriteP(8'h00, 8'h05, 8'hd5);   // djnz dpl,1
      MemWriteP(8'h00, 8'h06, 8'h82);
      MemWriteP(8'h00, 8'h07, 8'hf9);
      MemWriteP(8'h00, 8'h08, 8'ha5);   // bkpt
      MemWriteP(8'h00, 8'h09, 8'h00);
      MemWriteP(8'h00, 8'h0A, 8'h00);
      MemWriteP(8'h00, 8'h0B, 8'h00);
      MemWriteP(8'h00, 8'h0C, 8'h80);   // jmp self
      MemWriteP(8'h00, 8'h0D, 8'hfe);

      Reset;
      MemWriteS(8'h8e, ckcon_value);

      traceDepth = 1 << TRACE_DEPTH;
      TestTrace(0, 1);
      TestTrace(1, 1);
      TestTrace(2, 1);
      TestTrace((traceDepth>>1)-1, 1);
      TestTrace((traceDepth>>1)  , 1);
      TestTrace((traceDepth>>1)+1, 1);

      //
      // Test Toff/Ton
      //
      if ((TRACE_DEPTH >= 4) && (TRIG_NUM >= 2)) begin
         IR8(IR_Trigger+0);
         DR40(40'hA810001206);   // toff at xdata read 0x1206
         IR8(IR_Trigger+1);
         DR40(40'hA410001202);   // ton at xdata read 0x1202

         TestTrace(8, 0);

         CheckTDO(40'b00001101, "Toff/Ton: IR status after trace");   // no wrap
         DR8(8'h00);
         CheckTDO(12, "TraceAddr");  // 6 frames: 3+toff+ton+1
         IR8(IR_TraceData);
         for (i=0; i<3; i=i+1) begin
            DR24(24'h0);
            CheckTDO(40'h40007, "Trace frame even");
            DR24(24'h0);
            CheckTDO(40'h00001, "Trace frame odd");
         end
         DR24(24'h0);
         CheckTDO(40'h20001, "Trace frame toff");
         DR24(24'h0);
         if (WAITSTATES > 0) begin
            CheckTDO(40'h00001, "Trace frame toff");
         end else begin
            CheckTDO(40'h00002, "Trace frame toff");
         end
         DR24(24'h0);   // value of this frame is not important
         DR24(24'h0);
         if (WAITSTATES > 0) begin
            CheckTDO(40'h00001, "Trace frame ton");
         end else begin
            CheckTDO(40'h00002, "Trace frame ton");
         end
         DR24(24'h0);
         CheckTDO(40'h40007, "Trace frame even");
         DR24(24'h0);
         CheckTDO(40'h00001, "Trace frame odd");

         IR8(IR_TraceClear);
      end

      //
      // Test Trace through Reset
      //
      MemWriteP(8'h00, 8'h04, 8'ha5);   // bkpt
      SetPc(14);
      IR8(IR_TraceClear);
      IR8(IR_TraceStart);
      Go;
      repeat(21) @(posedge clkcpu);  // let CPU run a bit
      resetiB = 0;                   // reset the system
      repeat (8) @(posedge clkcpu);
      resetiB = 1;
      MemWriteS(8'h8e, ckcon_value);
      Go;
      WaitFordebugack(1000,1);
      Checkmemaddr(16'h05, "memaddr after bkpt");
      IR8(IR_TraceStop);
      IR8(IR_TraceAddr);
      if (traceDepth > 2) begin
         CheckTDO(40'b00001101, "Trace reset: IR status after trace");   // no wrap
         DR8(8'h00);
         CheckTDO(2, "TraceAddr after reset");
      end
      else begin
         CheckTDO(40'b00011101, "Trace reset: IR status after trace");   // wrap
         DR8(8'h00);
         CheckTDO(0, "TraceAddr after reset");
      end
      IR8(IR_TraceData);
      DR24(24'h0);
      DR24(24'h0);
      CheckTDO(40'h00000, "Trace frame 1 after reset");

      //
      // Test Trace through Reset from jump self
      //  (tests behavior of reset record occurring simultaneously with branch)
      //  run once for each alignment of jumps to reset (jump loop is 4 clocks).
      //
      MemWriteP(8'h00, 8'h00, 8'h00);
      MemWriteP(8'h00, 8'h01, 8'h75);   // load b
      MemWriteP(8'h00, 8'h02, 8'hE0);
      MemWriteP(8'h00, 8'h03, 8'h10);
      MemWriteP(8'h00, 8'h04, 8'ha5);   // bkpt
      MemWriteP(8'h00, 8'h0E, 8'h80);   // sjmp *
      MemWriteP(8'h00, 8'h0F, 8'hFE);
      for (i=traceDepth*4; i<(traceDepth*4) + 4; i=i+1) begin
         SetPc(14);
         IR8(IR_TraceClear);
         IR8(IR_TraceStart);
         Go;
         repeat(i*(WAITSTATES+1)) @(posedge clkcpu);  // let CPU run enough to fill trace
         resetiB = 0;                   // reset the system
         repeat (8) @(posedge clkcpu);
         resetiB = 1;
         MemWriteS(8'h8e, ckcon_value);
         Go;
         WaitFordebugack(1000,1);
         Checkmemaddr(16'h05, "memaddr after bkpt");
         IR8(IR_TraceStop);
         IR8(IR_TraceAddr);
         CheckTDO(40'b00011101, "Trace thru reset/jump self: IR status after trace");   // wrap
         DR8(8'h00);
         traceaddr = TDOout[7:0];   // youngest frame
         traceaddr = traceaddr - 2;
         DR8(traceaddr);
         IR8(IR_TraceData);
         DR24(24'h0);
         if ((TDOout[39:0] !== 40'h8000E) && (TDOout[39:0] !== 40'h8000F)) begin
            CheckTDO(40'h8000E, "Trace frame n-2 after reset");
         end
         DR24(24'h0);
         CheckTDO(40'h00000, "Trace frame n-1 after reset");
      end

      //
      // Test Trace through Step
      //
      MemWriteP(8'h00, 8'h00, 8'h00);   // nop
      MemWriteP(8'h00, 8'h01, 8'he0);   // movx a,@dptr
      MemWriteP(8'h00, 8'h02, 8'h04);   // inc a
      MemWriteP(8'h00, 8'h03, 8'hf0);   // movx @dptr,a
      MemWriteP(8'h00, 8'h04, 8'h00);   // nop
      MemWriteP(8'h00, 8'h05, 8'hd5);   // djnz dpl,0
      MemWriteP(8'h00, 8'h06, 8'h82);
      MemWriteP(8'h00, 8'h07, 8'hf9);
      MemWriteP(8'h00, 8'h08, 8'ha5);   // bkpt
      MemWriteP(8'h00, 8'h09, 8'h00);
      MemWriteP(8'h00, 8'h0A, 8'h00);
      MemWriteP(8'h00, 8'h0B, 8'h00);
      MemWriteP(8'h00, 8'h0C, 8'h80);   // jmp self
      MemWriteP(8'h00, 8'h0D, 8'hfe);

      Reset;
      MemWriteS(8'h8e, ckcon_value);
      MemWriteS(8'h82, 8'h10); // DPL
      MemWriteS(8'h83, 8'h12);    // DPH=0x12
      IR8(IR_TraceClear);
      IR8(IR_TraceStart);
      Step;
      Checkmemaddr(16'h01, "memaddr after step");
      IR8(IR_TraceStop);
      IR8(IR_TraceAddr);
      DR8(0);
      CheckTDO(40'h0,"Trace addr after step");
      Step;
      Step;
      Step;
      Step;
      //
      // Test trace of step thru jump
      //
      IR8(IR_TraceClear);
      IR8(IR_TraceStart);
      Step;
      Checkmemaddr(16'h01, "memaddr after step");
      IR8(IR_TraceStop);
      IR8(IR_TraceAddr);
      DR8(0);
      if (traceDepth > 2)
         CheckTDO(40'h2,"Trace addr after step");
      else
         CheckTDO(40'h0,"Trace addr after step");
      IR8(IR_TraceData);
      DR24(24'h0);
      CheckTDO(40'h40007, "Trace frame even");
      DR24(24'h0);
      CheckTDO(40'h00001, "Trace frame odd");

   end
endtask

task TestTrace;
   input [7:0] frames;
   input verify;
   integer i;
   integer size;
   integer hwframes;
   begin
      size = 1<<TRACE_DEPTH;
      SetPc(0);
      MemWriteS(8'h82, frames+1); // DPL
      MemWriteS(8'h83, 8'h12);    // DPH=0x12
      IR8(IR_TraceClear);
      IR8(IR_TraceStart);
      Go;
      WaitFordebugack(10000,1);
      Checkmemaddr(16'h09, "memaddr after bkpt");
      IR8(IR_TraceStop);
      IR8(IR_TraceAddr);
      if (verify) begin
         if (2*frames >= size) begin
            CheckTDO(40'b00011101, "TestTrace: IR status after trace");   // wrap
            hwframes = size>>1;
         end else begin
            CheckTDO(40'b00001101, "TestTrace: IR status after trace");   // no wrap
            hwframes = frames;
         end
         DR8(8'h00);
         CheckTDO((2*frames) & (size-1), "TraceAddr");
         IR8(IR_TraceData);
         for (i=0; i<hwframes; i=i+1) begin
            DR24(24'h0);
            CheckTDO(40'h40007, "Trace frame even");
            DR24(24'h0);
            CheckTDO(40'h00001, "Trace frame odd");
         end
         IR8(IR_TraceClear);
      end

   end
endtask


//---------------------------------------------------------------------------
// TriggerTest
//
// Verify triggers
//
//---------------------------------------------------------------------------
task TriggerTest;
   begin
      $fdisplay(fp,"TriggerTest");
      TriggerP;
      TriggerX;
      TriggerI;
      //TriggerS;   // External SFR related test skipped for Core8051s
   end
endtask

task TriggerP;
   begin
      $fdisplay(fp," -- TriggerP");
      MemWriteP(8'h00, 8'h00, 8'he4);   // clr a
      MemWriteP(8'h00, 8'h01, 8'h93);   // movc a,@a+dptr
      MemWriteP(8'h00, 8'h02, 8'h04);   // inc a
      MemWriteP(8'h00, 8'h03, 8'h00);   // nop
      MemWriteP(8'h00, 8'h04, 8'h00);
      MemWriteP(8'h00, 8'h05, 8'h00);
      MemWriteP(8'h00, 8'h06, 8'hd8);   // djnz r0,0
      MemWriteP(8'h00, 8'h07, 8'hf8);
      MemWriteP(8'h00, 8'h08, 8'h75);   // load B
      MemWriteP(8'h00, 8'h09, 8'he0);
      MemWriteP(8'h00, 8'h0A, 8'h10);
      MemWriteP(8'h00, 8'h0B, 8'h00);
      MemWriteP(8'h00, 8'h0C, 8'h00);
      MemWriteP(8'h00, 8'h0D, 8'h00);
      MemWriteP(8'h00, 8'h0E, 8'h80);   // jmp self
      MemWriteP(8'h00, 8'h0F, 8'hfe);

      // reads
      $fdisplay(fp," ---- reads");
      TestSingleTrigger(40'h8110001234, 3'b010, 16'h0002, 16'h0003, 8'h10);  // addr
      TestSingleTrigger(40'h8110001240, 3'b000, 16'h0002, 16'h0003, 8'h10);  // !addr
      TestSingleTrigger(40'h8150001234, 3'b010, 16'h0002, 16'h0003, 8'h10);  // addr, data
      TestSingleTrigger(40'h8159901234, 3'b000, 16'h0002, 16'h0003, 8'h10);  // addr, !data
      TestSingleTrigger(40'h815FF01234, 3'b000, 16'h0002, 16'h0003, 8'h10);  // addr, !data
      TestSingleTrigger(40'h8170001234, 3'b010, 16'h0002, 16'h0003, 8'h10);  // addr, bank, data
      TestSingleTrigger(40'h8170011234, 3'b000, 16'h0002, 16'h0003, 8'h10);  // addr, !bank, data

      // writes
      $fdisplay(fp," ---- writes (no break)");
      TestSingleTrigger(40'h9110001234, 3'b000, 16'h0004, 16'h0006, 8'h10);  // addr
      TestSingleTrigger(40'h9150501234, 3'b000, 16'h0004, 16'h0006, 8'h0c);  // addr, data
      TestSingleTrigger(40'h9170801234, 3'b000, 16'h0004, 16'h0006, 8'h09);  // addr, bank, data

      // execution breakpoints
      $fdisplay(fp," ---- execution");
      TestSingleTrigger(40'h801000000C, 3'b100, 16'h000D, 16'h000D, 8'h00);  // addr
      TestSingleTrigger(40'h8010001234, 3'b000, 16'h000D, 16'h000D, 8'h00);  // !addr
      TestSingleTrigger(40'h803000000C, 3'b100, 16'h000D, 16'h000D, 8'h00);  // addr, bank, data
      TestSingleTrigger(40'h803001000C, 3'b000, 16'h000D, 16'h000D, 8'h00);  // addr, !bank, data

      // no-break
      $fdisplay(fp," ---- no break");
      TestSingleTrigger(40'ha110001234, 3'b000, 16'h0002, 16'h0003, 8'h10);  // addr
      TestSingleTrigger(40'hb110001234, 3'b000, 16'h0002, 16'h0003, 8'h10);  // addr
      TestSingleTrigger(40'hc110001234, 3'b000, 16'h0002, 16'h0003, 8'h10);  // addr
      TestSingleTrigger(40'hd110001234, 3'b000, 16'h0002, 16'h0003, 8'h10);  // addr
      TestSingleTrigger(40'he110001234, 3'b000, 16'h0002, 16'h0003, 8'h10);  // addr
      TestSingleTrigger(40'hf110001234, 3'b000, 16'h0002, 16'h0003, 8'h10);  // addr
      TestSingleTrigger(40'h8210001234, 3'b001, 16'h0002, 16'h0003, 8'h10);  // addr, TrigOut

      // reads paired trigger
      $fdisplay(fp," ---- paired reads");
      TestPairedTrigger(40'h8190001234, 40'h8190001234, 3'b010, 16'h0002, 16'h0003, 8'h10);  // addr
      TestPairedTrigger(40'h8190001230, 40'h819000123F, 3'b010, 16'h0002, 16'h0003, 8'h10);  // addr
      TestPairedTrigger(40'h8190001240, 40'h819000124F, 3'b000, 16'h0002, 16'h0003, 8'h10);  // !addr
      TestPairedTrigger(40'h81d0001234, 40'h81dFF01234, 3'b010, 16'h0002, 16'h0003, 8'h10);  // addr, data

      // writes paired trigger
      $fdisplay(fp," ---- paired writes (no break)");
      TestPairedTrigger(40'h9190001234, 40'h9190001234, 3'b000, 16'h0004, 16'h0006, 8'h10);  // addr
      TestPairedTrigger(40'h9190001230, 40'h919000123F, 3'b000, 16'h0004, 16'h0006, 8'h10);  // addr

   end
endtask

task TriggerX;
   begin
      $fdisplay(fp," -- TriggerX");
      MemWriteP(8'h00, 8'h00, 8'h00);   // nop
      MemWriteP(8'h00, 8'h01, 8'he0);   // movx a,@dptr
      MemWriteP(8'h00, 8'h02, 8'h04);   // inc a
      MemWriteP(8'h00, 8'h03, 8'hf0);   // movx @dptr,a
      MemWriteP(8'h00, 8'h04, 8'h00);   // nop
      MemWriteP(8'h00, 8'h05, 8'h00);
      MemWriteP(8'h00, 8'h06, 8'hd8);   // djnz r0,0
      MemWriteP(8'h00, 8'h07, 8'hf8);
      MemWriteP(8'h00, 8'h08, 8'h75);   // load B
      MemWriteP(8'h00, 8'h09, 8'hE0);
      MemWriteP(8'h00, 8'h0A, 8'h10);
      MemWriteP(8'h00, 8'h0B, 8'h00);
      MemWriteP(8'h00, 8'h0C, 8'h00);
      MemWriteP(8'h00, 8'h0D, 8'h00);
      MemWriteP(8'h00, 8'h0E, 8'h80);   // jmp self
      MemWriteP(8'h00, 8'h0F, 8'hfe);

      // reads
      $fdisplay(fp," ---- reads");
      TestSingleTrigger(40'ha110001234, 3'b010, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'ha110001240, 3'b000, 16'h0002, 16'h0004, 8'h10);  // !addr
      TestSingleTrigger(40'ha150501234, 3'b010, 16'h0002, 16'h0004, 8'h0b);  // addr, data
      TestSingleTrigger(40'ha15FF01234, 3'b000, 16'h0002, 16'h0004, 8'h0b);  // addr, !data
      TestSingleTrigger(40'ha170801234, 3'b010, 16'h0002, 16'h0004, 8'h08);  // addr, bank, data
      TestSingleTrigger(40'ha170811234, 3'b000, 16'h0002, 16'h0004, 8'h08);  // addr, !bank, data

      // writes
      $fdisplay(fp," ---- writes");
      TestSingleTrigger(40'hb110001234, 3'b010, 16'h0004, 16'h0006, 8'h10);  // addr
      TestSingleTrigger(40'hb110001240, 3'b000, 16'h0004, 16'h0006, 8'h10);  // !addr
      TestSingleTrigger(40'hb150501234, 3'b010, 16'h0004, 16'h0006, 8'h0c);  // addr, data
      TestSingleTrigger(40'hb15FF01234, 3'b000, 16'h0004, 16'h0006, 8'h0b);  // addr, !data
      TestSingleTrigger(40'hb170801234, 3'b010, 16'h0004, 16'h0006, 8'h09);  // addr, bank, data
      TestSingleTrigger(40'hb170811234, 3'b000, 16'h0004, 16'h0006, 8'h08);  // addr, !bank, data

      // no-break
      $fdisplay(fp," ---- no break");
      TestSingleTrigger(40'h8110001234, 3'b000, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'h9110001234, 3'b000, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'hc110001234, 3'b000, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'hd110001234, 3'b000, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'he110001234, 3'b000, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'hf110001234, 3'b000, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'ha210001234, 3'b001, 16'h0002, 16'h0004, 8'h10);  // addr, TrigOut

      // reads paired trigger
      $fdisplay(fp," ---- paired reads");
      TestPairedTrigger(40'ha190001234, 40'ha190001234, 3'b010, 16'h0002, 16'h0004, 8'h10);  // addr
      TestPairedTrigger(40'ha190001230, 40'ha19000123F, 3'b010, 16'h0002, 16'h0004, 8'h10);  // addr
      TestPairedTrigger(40'ha190001240, 40'ha19000124F, 3'b000, 16'h0002, 16'h0004, 8'h10);  // !addr
      TestPairedTrigger(40'ha1d0501234, 40'ha1dFF01234, 3'b010, 16'h0002, 16'h0004, 8'h0b);  // addr, data
      TestPairedTrigger(40'ha1d0501234, 40'ha1dFC01234, 3'b010, 16'h0002, 16'h0004, 8'h0c);  // addr, data
      TestPairedTrigger(40'ha1d5501234, 40'ha1d0F01234, 3'b010, 16'h0002, 16'h0004, 8'h0b);  // addr, data
      TestPairedTrigger(40'ha1d5501234, 40'ha1dF001234, 3'b000, 16'h0002, 16'h0004, 8'h0b);  // addr, data

      // writes paired trigger
      $fdisplay(fp," ---- paired writes");
      TestPairedTrigger(40'hb190001234, 40'hb190001234, 3'b010, 16'h0004, 16'h0006, 8'h10);  // addr
      TestPairedTrigger(40'hb190001230, 40'hb19000123F, 3'b010, 16'h0004, 16'h0006, 8'h10);  // addr
      TestPairedTrigger(40'hb190001240, 40'hb19000124F, 3'b000, 16'h0004, 16'h0006, 8'h10);  // !addr
      TestPairedTrigger(40'hb1d0501234, 40'hb1dFF01234, 3'b010, 16'h0004, 16'h0006, 8'h0c);  // addr, data
      TestPairedTrigger(40'hb1d0501234, 40'hb1dFC01234, 3'b010, 16'h0004, 16'h0006, 8'h0d);  // addr, data
      TestPairedTrigger(40'hb1d5501234, 40'hb1d0F01234, 3'b010, 16'h0004, 16'h0006, 8'h0c);  // addr, data
      TestPairedTrigger(40'hb1d5501234, 40'hb1dF001234, 3'b000, 16'h0004, 16'h0006, 8'h0c);  // addr, data

   end
endtask

task TriggerI;
   begin
      $fdisplay(fp," -- TriggerI");
      MemWriteP(8'h00, 8'h00, 8'h00);   // nop
      MemWriteP(8'h00, 8'h01, 8'he7);   // mov a,@r1
      MemWriteP(8'h00, 8'h02, 8'h04);   // inc a
      MemWriteP(8'h00, 8'h03, 8'h00);   // nop
      MemWriteP(8'h00, 8'h04, 8'hf7);   // mov @r1,a
      MemWriteP(8'h00, 8'h05, 8'h00);   // nop
      MemWriteP(8'h00, 8'h06, 8'h00);   // nop
      MemWriteP(8'h00, 8'h07, 8'hd8);   // djnz r0,0
      MemWriteP(8'h00, 8'h08, 8'hf7);
      MemWriteP(8'h00, 8'h09, 8'h75);   // load B
      MemWriteP(8'h00, 8'h0A, 8'hE0);
      MemWriteP(8'h00, 8'h0B, 8'h10);
      MemWriteP(8'h00, 8'h0C, 8'h00);
      MemWriteP(8'h00, 8'h0D, 8'h00);
      MemWriteP(8'h00, 8'h0E, 8'h80);   // jmp self
      MemWriteP(8'h00, 8'h0F, 8'hfe);


      // reads
      $fdisplay(fp," ---- reads");
      TestSingleTrigger(40'hc110000034, 3'b010, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'hc110000040, 3'b000, 16'h0002, 16'h0004, 8'h10);  // !addr
      TestSingleTrigger(40'hc150500034, 3'b010, 16'h0002, 16'h0004, 8'h0b);  // addr, data
      TestSingleTrigger(40'hc15FF00034, 3'b000, 16'h0002, 16'h0004, 8'h0b);  // addr, !data
      TestSingleTrigger(40'hc170800034, 3'b010, 16'h0002, 16'h0004, 8'h08);  // addr, bank, data
      TestSingleTrigger(40'hc170810034, 3'b000, 16'h0002, 16'h0004, 8'h08);  // addr, !bank, data

      // writes
      $fdisplay(fp," ---- writes");
      TestSingleTrigger(40'hd110000034, 3'b010, 16'h0005, 16'h0007, 8'h10);  // addr
      TestSingleTrigger(40'hd110000040, 3'b000, 16'h0005, 16'h0007, 8'h10);  // !addr
      TestSingleTrigger(40'hd150500034, 3'b010, 16'h0005, 16'h0007, 8'h0c);  // addr, data
      TestSingleTrigger(40'hd15FF00034, 3'b000, 16'h0005, 16'h0007, 8'h0b);  // addr, !data
      TestSingleTrigger(40'hd170800034, 3'b010, 16'h0005, 16'h0007, 8'h09);  // addr, bank, data
      TestSingleTrigger(40'hd170810034, 3'b000, 16'h0005, 16'h0007, 8'h08);  // addr, !bank, data

      // no-break
      $fdisplay(fp," ---- no break");
      TestSingleTrigger(40'h8110000034, 3'b000, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'h9110000034, 3'b000, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'ha110000034, 3'b000, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'hb110000034, 3'b000, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'he110000034, 3'b000, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'he1100000b4, 3'b000, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'hf110000034, 3'b000, 16'h0002, 16'h0004, 8'h10);  // addr
      TestSingleTrigger(40'hc210000034, 3'b001, 16'h0002, 16'h0004, 8'h10);  // addr, TrigOut

      // reads paired trigger
      $fdisplay(fp," ---- paired reads");
      TestPairedTrigger(40'hc190000034, 40'hc190000034, 3'b010, 16'h0002, 16'h0004, 8'h10);  // addr
      TestPairedTrigger(40'hc190000030, 40'hc19000003F, 3'b010, 16'h0002, 16'h0004, 8'h10);  // addr
      TestPairedTrigger(40'hc190000040, 40'hc19000004F, 3'b000, 16'h0002, 16'h0004, 8'h10);  // !addr
      TestPairedTrigger(40'hc1d0500034, 40'hc1dFF00034, 3'b010, 16'h0002, 16'h0004, 8'h0b);  // addr, data
      TestPairedTrigger(40'hc1d0500034, 40'hc1dFC00034, 3'b010, 16'h0002, 16'h0004, 8'h0c);  // addr, data
      TestPairedTrigger(40'hc1d5500034, 40'hc1d0F00034, 3'b010, 16'h0002, 16'h0004, 8'h0b);  // addr, data
      TestPairedTrigger(40'hc1d5500034, 40'hc1dF000034, 3'b000, 16'h0002, 16'h0004, 8'h0b);  // addr, data

      // writes paired trigger
      $fdisplay(fp," ---- paired writes");
      TestPairedTrigger(40'hd190000034, 40'hd190000034, 3'b010, 16'h0005, 16'h0007, 8'h10);  // addr
      TestPairedTrigger(40'hd190000030, 40'hd19000003F, 3'b010, 16'h0005, 16'h0007, 8'h10);  // addr
      TestPairedTrigger(40'hd190000040, 40'hd19000004F, 3'b000, 16'h0005, 16'h0007, 8'h10);  // !addr
      TestPairedTrigger(40'hd1d0500034, 40'hd1dFF00034, 3'b010, 16'h0005, 16'h0007, 8'h0c);  // addr, data
      TestPairedTrigger(40'hd1d0500034, 40'hd1dFC00034, 3'b010, 16'h0005, 16'h0007, 8'h0d);  // addr, data
      TestPairedTrigger(40'hd1d5500034, 40'hd1d0F00034, 3'b010, 16'h0005, 16'h0007, 8'h0c);  // addr, data
      TestPairedTrigger(40'hd1d5500034, 40'hd1dF000034, 3'b000, 16'h0005, 16'h0007, 8'h0c);  // addr, data

   end
endtask

task TriggerS;
   integer i;
   begin
      $fdisplay(fp," -- TriggerS");
      MemWriteP(8'h00, 8'h00, 8'h00);   // nop
      MemWriteP(8'h00, 8'h01, 8'he5);   // mov a,0x96
      MemWriteP(8'h00, 8'h02, 8'h96);
      MemWriteP(8'h00, 8'h03, 8'h04);   // inc a
      MemWriteP(8'h00, 8'h04, 8'h00);   // nop
      MemWriteP(8'h00, 8'h05, 8'hf5);   // mov 0x96,a
      MemWriteP(8'h00, 8'h06, 8'h96);
      MemWriteP(8'h00, 8'h07, 8'h00);   // nop
      MemWriteP(8'h00, 8'h08, 8'h00);   // nop
      MemWriteP(8'h00, 8'h09, 8'hd8);   // djnz r0,0
      MemWriteP(8'h00, 8'h0A, 8'hf5);
      MemWriteP(8'h00, 8'h0B, 8'h75);   // load B
      MemWriteP(8'h00, 8'h0C, 8'hE0);
      MemWriteP(8'h00, 8'h0D, 8'h10);
      MemWriteP(8'h00, 8'h0E, 8'h80);   // jmp self
      MemWriteP(8'h00, 8'h0F, 8'hfe);

      // reads
      $fdisplay(fp," ---- reads");
      TestSingleTrigger(40'he110000096, 3'b010, 16'h0002, 16'h0005, 8'h10);  // addr
      TestSingleTrigger(40'he110000097, 3'b000, 16'h0002, 16'h0005, 8'h10);  // !addr
      TestSingleTrigger(40'he110000016, 3'b000, 16'h0002, 16'h0005, 8'h10);  // !addr
      TestSingleTrigger(40'he150500096, 3'b010, 16'h0002, 16'h0005, 8'h0b);  // addr, data
      TestSingleTrigger(40'he15FF00096, 3'b000, 16'h0002, 16'h0005, 8'h0b);  // addr, !data
      TestSingleTrigger(40'he170800096, 3'b010, 16'h0002, 16'h0005, 8'h08);  // addr, bank, data
      TestSingleTrigger(40'he170810096, 3'b000, 16'h0002, 16'h0005, 8'h08);  // addr, !bank, data

      // writes
      $fdisplay(fp," ---- writes");
      TestSingleTrigger(40'hf110000096, 3'b010, 16'h0006, 16'h0009, 8'h10);  // addr
      TestSingleTrigger(40'hf110000016, 3'b000, 16'h0006, 16'h0009, 8'h10);  // !addr
      TestSingleTrigger(40'hf150500096, 3'b010, 16'h0006, 16'h0009, 8'h0c);  // addr, data
      TestSingleTrigger(40'hf15FF00096, 3'b000, 16'h0006, 16'h0009, 8'h0b);  // addr, !data
      TestSingleTrigger(40'hf170800096, 3'b010, 16'h0006, 16'h0009, 8'h09);  // addr, bank, data
      TestSingleTrigger(40'hf170810096, 3'b000, 16'h0006, 16'h0009, 8'h08);  // addr, !bank, data

      // no-break
      $fdisplay(fp," ---- no break");
      TestSingleTrigger(40'h8110000096, 3'b000, 16'h0002, 16'h0005, 8'h10);  // addr
      TestSingleTrigger(40'h9110000096, 3'b000, 16'h0002, 16'h0005, 8'h10);  // addr
      TestSingleTrigger(40'ha110000096, 3'b000, 16'h0002, 16'h0005, 8'h10);  // addr
      TestSingleTrigger(40'hb110000096, 3'b000, 16'h0002, 16'h0005, 8'h10);  // addr
      TestSingleTrigger(40'hc110000096, 3'b000, 16'h0002, 16'h0005, 8'h10);  // addr
      TestSingleTrigger(40'hd110000096, 3'b000, 16'h0002, 16'h0005, 8'h10);  // addr
      TestSingleTrigger(40'he210000096, 3'b001, 16'h0002, 16'h0005, 8'h10);  // addr, TrigOut

      // reads paired trigger
      $fdisplay(fp," ---- paired reads");
      TestPairedTrigger(40'he190000096, 40'he190000096, 3'b010, 16'h0002, 16'h0005, 8'h10);  // addr
      TestPairedTrigger(40'he190000090, 40'he19000009F, 3'b010, 16'h0002, 16'h0005, 8'h10);  // addr
      TestPairedTrigger(40'he1900000a0, 40'he1900000aF, 3'b000, 16'h0002, 16'h0005, 8'h10);  // !addr
      TestPairedTrigger(40'he1d0500096, 40'he1dFF00096, 3'b010, 16'h0002, 16'h0005, 8'h0b);  // addr, data
      TestPairedTrigger(40'he1d0500096, 40'he1dFC00096, 3'b010, 16'h0002, 16'h0005, 8'h0c);  // addr, data
      TestPairedTrigger(40'he1d5500096, 40'he1d0F00096, 3'b010, 16'h0002, 16'h0005, 8'h0b);  // addr, data
      TestPairedTrigger(40'he1d5500096, 40'he1dF000096, 3'b000, 16'h0002, 16'h0005, 8'h0b);  // addr, data

      // writes paired trigger
      $fdisplay(fp," ---- paired writes");
      TestPairedTrigger(40'hf190000096, 40'hf190000096, 3'b010, 16'h0006, 16'h0009, 8'h10);  // addr
      TestPairedTrigger(40'hf190000090, 40'hf19000009F, 3'b010, 16'h0006, 16'h0009, 8'h10);  // addr
      TestPairedTrigger(40'hf1900000a0, 40'hf1900000aF, 3'b000, 16'h0006, 16'h0009, 8'h10);  // !addr
      TestPairedTrigger(40'hf1d0500096, 40'hf1dFF00096, 3'b010, 16'h0006, 16'h0009, 8'h0c);  // addr, data
      TestPairedTrigger(40'hf1d0500096, 40'hf1dFC00096, 3'b010, 16'h0006, 16'h0009, 8'h0d);  // addr, data
      TestPairedTrigger(40'hf1d5500096, 40'hf1d0F00096, 3'b010, 16'h0006, 16'h0009, 8'h0c);  // addr, data
      TestPairedTrigger(40'hf1d5500096, 40'hf1dF000096, 3'b000, 16'h0006, 16'h0009, 8'h0c);  // addr, data

   end
endtask

task TestSingleTrigger;
   input [39:0] trig;           // value for trigger register
   input [2:0] expect;          // xbrk, trigbrk, or trigout
   input [15:0] expectPClow;
   input [15:0] expectPChigh;
   input [7:0] expectR0;
   begin

      if (TRIG_NUM >= 1) TestOneTrigger(trig, 40'h0, 40'h0, 40'h0, expect, expectPClow, expectPChigh, expectR0);
      if (TRIG_NUM >= 2) TestOneTrigger(40'h0, trig, 40'h0, 40'h0, expect, expectPClow, expectPChigh, expectR0);
      if (TRIG_NUM >= 3) TestOneTrigger(40'h0, 40'h0, trig, 40'h0, expect, expectPClow, expectPChigh, expectR0);
      if (TRIG_NUM >= 4) TestOneTrigger(40'h0, 40'h0, 40'h0, trig, expect, expectPClow, expectPChigh, expectR0);
   end
endtask

task TestPairedTrigger;
   input [39:0] trigE;          // value for trigger register
   input [39:0] trigO;          // value for trigger register
   input [2:0] expect;          // xbrk, trigbrk, or trigout
   input [15:0] expectPClow;
   input [15:0] expectPChigh;
   input [7:0] expectR0;
   begin

      if (TRIG_NUM >= 2) TestOneTrigger(trigE, trigO, 40'h0, 40'h0, expect, expectPClow, expectPChigh, expectR0);
      if (TRIG_NUM >= 4) TestOneTrigger(40'h0, 40'h0, trigE, trigO, expect, expectPClow, expectPChigh, expectR0);
   end
endtask

task TestOneTrigger;
   input [39:0] trig0;          // values for trigger registers
   input [39:0] trig1;
   input [39:0] trig2;
   input [39:0] trig3;
   input [2:0] expect;          // xbrk, trigbrk, or trigout
   input [15:0] expectPClow;
   input [15:0] expectPChigh;
   input [7:0] expectR0;
   integer i;
   begin
      Reset;
      MemWriteS(8'h8e, ckcon_value);
      MemWriteP(8'h12, 8'h34, 8'h00);
      MemWriteX(8'h12, 8'h34, 8'h00);
      IR8(IR_Trigger+0);                    // set trigger registers
      DR40(trig0);
      IR8(IR_Trigger+1);
      DR40(trig1);
      IR8(IR_Trigger+2);
      DR40(trig2);
      IR8(IR_Trigger+3);
      DR40(trig3);

      MemWriteI(8'h34,0);         // init ram & sfr's
      MemWriteI(8'h40,0);
      MemWriteS(8'h94,0);
      MemWriteS(8'h96,0);
      MemWriteS(8'h82, 8'h34);    // DPTR=0x1234
      MemWriteS(8'h83, 8'h12);
      SetReg(8'h78, 8'h10);       // R0 = 0 (16 iterations max)
      SetReg(8'h79, 8'h34);       // R1 = 0x34
      Go;
      if (expect[2] | expect[1]) begin
         WaitFordebugack(1000*(WAITSTATES+1),1);
         CheckmemaddrRange(expectPClow, expectPChigh, "memaddr after trigger bkpt");
         GetReg(8'hE8);   // read R0
         CheckTDO({32'h0, expectR0[7:0]}, "R0 after trigger bkpt");
      end
      else if (expect[0]) begin
         WaitForTrigOut(1000*(WAITSTATES+1),1);
         repeat(30) @(posedge clkcpu);
         IR8(IR_DebugNop);                     // check status
         CheckSignal(TDOout[2], 0, "debugack after TrigOut");
         Halt;
      end
      else begin
         IR8(IR_DebugNop);                     // check status
         CheckSignal(TDOout[2], 0, "debugack after TrigOut");
         Halt;
      end
   end
endtask

                         //-------------------//
                         //                   //
                         //   SUPPORT TASKS   //
                         //                   //
                         //-------------------//

//
// IR8: Write one byte to JTAG IR, capture 8 bit output into TDOlat.
//
task IR8;
  input [7:0] in;
  begin
    IR_ENTER;
    if (DEBUG == 2) begin
      SHIFTX(UI_IRCODE);
      DR_ENTER;
    end
    SHIFTX(in);
    TDOout[39:0] = {32'h00000000, TDOlat[39:32]};
  end
endtask

//
// DR8: Write 8 bits to JTAG DR, capture 8 bit output into TDOlat.
//
task DR8;
  input [7:0] in;
  begin
    if (DEBUG == 2) begin
      IR_ENTER;
      SHIFTX(UI_DRCODE);
    end
    DR_ENTER;
    SHIFTX(in);
    TDOout[39:0] = {32'h00000000,TDOlat[39:32]};
  end
endtask

//
// DR16: Write 16 bits to JTAG DR, capture 16 bit output into TDOlat.
//
task DR16;
  input [15:0] in;
  begin
    if (DEBUG == 2) begin
      IR_ENTER;
      SHIFTX(UI_DRCODE);
    end
    DR_ENTER;
    SHIFT(in[7:0]);
    SHIFTX(in[15:8]);
    TDOout[39:0] = {24'h000000,TDOlat[39:24]};
  end
endtask

//
// DR24: Write 24 bits to JTAG DR, capture 24 bit output into TDOlat.
//
task DR24;
  input [23:0] in;
  begin
    if (DEBUG == 2) begin
      IR_ENTER;
      SHIFTX(UI_DRCODE);
    end
    DR_ENTER;
    SHIFT(in[7:0]);
    SHIFT(in[15:8]);
    SHIFTX(in[23:16]);
    TDOout[39:0] = {16'h0000,TDOlat[39:16]};
  end
endtask

//
// DR40: Write 40 bits to JTAG DR, capture 40 bit output into TDOlat.
//
task DR40;
  input [39:0] in;
  begin
    if (DEBUG == 2) begin
      IR_ENTER;
      SHIFTX(UI_DRCODE);
    end
    DR_ENTER;
    SHIFT(in[7:0]);
    SHIFT(in[15:8]);
    SHIFT(in[23:16]);
    SHIFT(in[31:24]);
    SHIFTX(in[39:32]);
    TDOout[39:0] = TDOlat[39:0];
  end
endtask

//
// IR_ENTER:  Advance JTAG TAP from Idle or Reset state to Pause-IR state.
//
task IR_ENTER;
  begin
    TC1(0,0);     // ->idle
    TC1(1,0);     // ->selectdr
    TC1(1,0);     // ->selectir
    TC1(0,0);     // ->captureir
    TC1(1,0);     // ->exit1
    TC1(0,0);     // ->pause
    TDOsr = 0;
  end
endtask

//
// DR_ENTER: Advance JTAG TAP from Idle or Reset state to Pause-DR state.
//
task DR_ENTER;
  begin
    TC1(0,0);     // ->idle
    TC1(1,0);     // ->selectdr
    TC1(0,0);     // ->capturedr
    TC1(1,0);     // ->exit1
    TC1(0,0);     // ->pause
    TDOsr = 0;
  end
endtask

//
// SHIFTX:  From Pause, go to Shift, supply 8 bits, then advance to Idle.
//
task SHIFTX;
  input [7:0] in;
  begin
    TC1X(1,0);      // exit2
    TC1X(0,0);      // shift
    TC1(0,in[0]);
    TC1(0,in[1]);
    TC1(0,in[2]);
    TC1(0,in[3]);
    TC1(0,in[4]);
    TC1(0,in[5]);
    TC1(0,in[6]);
    TC1(1,in[7]);  // -> exit1
    TC1X(1,0);     // -> update
    TDOlat = TDOsr;
    TC1X(0,0);     // -> idle
  end
endtask

//
// SHIFT:  From Pause, go to Shift, supply 8 bits, then traverse to Pause state.
//
task SHIFT;
  input [7:0] in;
  begin
    TC1X(1,0);      // exit2
    TC1X(0,0);      // shift
    TC1(0,in[0]);
    TC1(0,in[1]);
    TC1(0,in[2]);
    TC1(0,in[3]);
    TC1(0,in[4]);
    TC1(0,in[5]);
    TC1(0,in[6]);
    TC1(1,in[7]);   // exit1
    TC1X(0,0);      // pause
  end
endtask

//
// WaitFordebugreq:  Wait up to N clk's for debugreq to take on the specified value.
// WaitFordebugack
//
task WaitFordebugreq;
   input [15:0] count;
   input value;
   begin : break
      repeat (count) begin
         IR8(IR_DebugNop);                     // check status
         if (TDOout[3] == value) disable break;
      end
      CheckSignal(TDOout[3], value, "WaitFordebugreq");
   end
endtask

task WaitFordebugack;
   input [15:0] count;
   input value;
   begin : break
      repeat (count) begin
         IR8(IR_DebugNop);                     // check status
         if (TDOout[2] == value) disable break;
      end
      CheckSignal(TDOout[2], value, "WaitFordebugack");
   end
endtask

task WaitForTrigOut;
   input [15:0] count;
   input value;
   begin : break
      repeat (count) begin
         if (TrigOut == value) disable break;
         @(posedge clkcpu);
      end
      CheckSignal(TrigOut, value, "WaitForTrigOut");
   end
endtask

task WaitForStep;
   input [15:0] count;
   begin : break
      IR8(IR_DebugNop);
      repeat (count) begin
         DR16(16'h0);
         if (TDOout[9:8] == 2'b00) disable break;   // indicates cycle completed
      end
      $fdisplay(fp,"WaitForStep timed out");
      $stop(1);
   end
endtask

//
// CheckTDO:  Verify that TDO has expected value.  Print diagnostic and exit if not.
//
task CheckTDO;
   input [39:0] Expected;
   input [255:0]name;
   begin
      if (Expected[39:0] !== TDOout[39:0]) begin
         $fdisplay(fp,"%0s: Expected %h, Actual %h", name, Expected[39:0], TDOout[39:0]);
         $stop(1);
      end
   end
endtask

//
// CheckSignal:  Verify that signal has expected value.  Print diagnostic and exit if not.
//
task CheckSignal;
   input Actual;
   input Expected;
   input [255:0]name;
   begin
      if (Expected !== Actual) begin
         $fdisplay(fp,"%0s: Expected %b, Actual %b", name, Expected, Actual);
         $stop(1);
      end
   end
endtask

//
// Checkmemaddr:  Verify that PC has expected value.  Print diagnostic and exit if not.
//
task Checkmemaddr;
   input [15:0] Expected;
   input [255:0]name;
   begin
      IR8(IR_GetPC);
      DR24(0);
      CheckTDO(Expected, name);
   end
endtask

task CheckmemaddrRange;
   input [15:0] ExpectedLow;
   input [15:0] ExpectedHigh;
   input [255:0]name;
   begin
      IR8(IR_GetPC);
      DR24(0);
      if ((ExpectedHigh[15:0] < TDOout[15:0]) || (ExpectedLow[15:0] > TDOout[15:0])) begin
         $fdisplay(fp,"%0s: Expected %h to %h, Actual %h", name, ExpectedLow, ExpectedHigh, TDOout);
         $stop(1);
      end
   end
endtask

//
// TC1: Generate one JTAG TCK, supplying TMS and TDI and capturing TDO.
//
task TC1;
  input TMSin, TDIin;
  begin
     @(negedge TCK);
     TMS = TMSin;
     TDI = TDIin;
     @(posedge TCK);
     TDOsr[39:0] = {TDO, TDOsr[39:1]};
  end
endtask

//
// TC1X: Generate one JTAG TCK, supplying TMS and TDI and NOT capturing TDO.
//
task TC1X;
  input TMSin, TDIin;
  begin
     @(negedge TCK);
     TMS = TMSin;
     TDI = TDIin;
     @(posedge TCK);
  end
endtask

//
// Reset:  Reset CPU and wait at program address zero.
//
task Reset;
   begin
      IR8(IR_ResetCPU);                     // JReset on
      IR8(IR_DebugReqOn);                   // request break, JReset off
      WaitFordebugreq(10,1);                 // debugreq turns on
      WaitFordebugack(10,1);                 //  then debugack turns on
      Checkmemaddr(16'h0, "memaddr after reset");      // CPU stopped before any execution?
   end
endtask

//
// Go: Start CPU
//
task Go;
   begin
      IR8(IR_DebugReqOff);                  // request go
      repeat(WAITSTATES) @(posedge clkcpu);
      // No way to check since bkpt may be hit before polling cycle can complete
   end
endtask

//
// Halt: Stop CPU
//
task Halt;
   begin
      IR8(IR_DebugReqOn);                   // request break
      WaitFordebugreq(10,1);                 //  first debugreq turns on
      WaitFordebugack(100,1);                //  then debugack turns on
   end
endtask

//
// Step: Single-step CPU
//
task Step;
   begin
      IR8(IR_DebugStepUser);                // request emulation step
      repeat (8+2*WAITSTATES) @(posedge clkcpu);
      WaitFordebugack(100,1);                // wait for completion
   end
endtask

task GetReg;
   input [7:0] opcode;
   begin
      IR8(IR_DebugStepOCI);
      DR8(opcode);                // mov A, xx
      repeat (8+2*WAITSTATES) @(posedge clkcpu);
      DR8(8'h00);                 // nop (TDO result is A)
   end
endtask

task SetReg;
   input [7:0] opcode;
   input [7:0] data;
   begin
      IR8(IR_DebugStepOCI);
      DR16({opcode, data});          // mov xx, #data
      repeat (8+2*WAITSTATES) @(posedge clkcpu);  // wait for completion
   end
endtask

task SetPc;
   input [15:0] pc;
   begin
      IR8(IR_DebugStepOCI);
      DR24({8'h02, pc[15:8], pc[7:0]});   // ljmp hhll
      repeat (8+3*WAITSTATES) @(posedge clkcpu);  // wait for completion
   end
endtask

task MemReadC;
   input [7:0] addrh;
   input [7:0] addrl;
   begin
      IR8(IR_DebugStepOCI);
      DR8(8'he4);                   // clr a
      repeat (8+WAITSTATES) @(posedge clkcpu);  // wait for completion
      DR24({8'h90, addrh, addrl});  // mov dptr, #hhll
      repeat (8+3*WAITSTATES) @(posedge clkcpu);  // wait for completion
      DR8(8'h93);                   // movc a,@a+dptr
      WaitForStep(10);
   end
endtask

task MemReadX;
   input [7:0] addrh;
   input [7:0] addrl;
   begin
      IR8(IR_DebugStepOCI);
      DR24({8'h90, addrh, addrl});  // mov dptr, #hhll
      repeat (8+3*WAITSTATES) @(posedge clkcpu);  // wait for completion
      DR8(8'hE0);                   // movx a,@dptr
      WaitForStep(10);
   end
endtask

task MemReadI;
   input [7:0] addr;
   begin
      IR8(IR_DebugStepOCI);
      DR16({8'h78, addr});          // mov r0,#addr
      repeat (8+2*WAITSTATES) @(posedge clkcpu);  // wait for completion
      DR8(8'hE6);                   // mov a,@r0
      WaitForStep(10);
   end
endtask

task MemReadS;
   input [7:0] addr;
   begin
      IR8(IR_DebugStepOCI);
      DR16({8'hE5, addr});          // mov a,addr
      WaitForStep(10);
   end
endtask

task MemWriteX;
   input [7:0] addrh;
   input [7:0] addrl;
   input [7:0] data;
   begin
      IR8(IR_DebugStepOCI);
      DR24({8'h90, addrh, addrl});  // mov dptr, #hhll
      repeat (8+3*WAITSTATES) @(posedge clkcpu);  // wait for completion
      DR16({8'h74, data});          // mov a, #data
      repeat (8+2*WAITSTATES) @(posedge clkcpu);  // wait for completion
      DR8(8'hF0);                   // movx @dptr,a
      repeat (8+WAITSTATES) @(posedge clkcpu);  // wait for completion
   end
endtask

task MemWriteP;
   input [7:0] addrh;
   input [7:0] addrl;
   input [7:0] data;
   begin
      IR8(IR_DebugPswrOn);
      IR8(IR_DebugStepOCI);
      DR24({8'h90, addrh, addrl});  // mov dptr, #hhll
      repeat (8+3*WAITSTATES) @(posedge clkcpu);  // wait for completion
      DR16({8'h74, data});          // mov a, #data
      repeat (8+2*WAITSTATES) @(posedge clkcpu);  // wait for completion
      DR8(8'hF0);                   // movx @dptr,a
      repeat (8+WAITSTATES) @(posedge clkcpu);  // wait for completion
      IR8(IR_DebugPswrOff);
   end
endtask

task MemWriteI;
   input [7:0] addr;
   input [7:0] data;
   begin
      IR8(IR_DebugStepOCI);
      DR16({8'h78, addr});          // mov r0,#addr
      repeat (8+2*WAITSTATES) @(posedge clkcpu);  // wait for completion
      DR16({8'h74, data});          // mov a, #data
      repeat (8+2*WAITSTATES) @(posedge clkcpu);  // wait for completion
      DR8(8'hF6);                   // mov @r0,a
      repeat (8+1*WAITSTATES) @(posedge clkcpu);  // wait for completion
   end
endtask

task MemWriteS;
   input [7:0] addr;
   input [7:0] data;
   begin
      IR8(IR_DebugStepOCI);
      DR24({8'h75, addr, data});    // mov addr,#data
      repeat (8+3*WAITSTATES) @(posedge clkcpu);  // wait for completion
   end
endtask

task InitMemory;
   begin
      MemWriteP(8'h00, 8'h00, 8'h78);
      MemWriteP(8'h00, 8'h01, 8'h00);   // mov r0,#00;
      MemWriteP(8'h00, 8'h02, 8'h79);
      MemWriteP(8'h00, 8'h03, 8'h55);   // mov r1,#55;
      MemWriteP(8'h00, 8'h04, 8'h00);
      MemWriteP(8'h00, 8'h05, 8'h00);
      MemWriteP(8'h00, 8'h06, 8'h00);
      MemWriteP(8'h00, 8'h07, 8'h00);
      MemWriteP(8'h00, 8'h08, 8'h00);
      MemWriteP(8'h00, 8'h09, 8'h00);
      MemWriteP(8'h00, 8'h0A, 8'h00);
      MemWriteP(8'h00, 8'h0B, 8'h08);   // inc r0;
      MemWriteP(8'h00, 8'h0C, 8'h09);   // inc r1;
      MemWriteP(8'h00, 8'h0D, 8'h80);   // sjmp 08;
      MemWriteP(8'h00, 8'h0E, 8'hf8);
      MemWriteP(8'h00, 8'h0F, 8'h00);
   end
endtask


endmodule

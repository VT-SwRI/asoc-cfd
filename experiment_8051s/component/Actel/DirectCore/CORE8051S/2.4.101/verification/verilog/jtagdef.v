//-----------------------------------------------------------------------------
// Copyright 2006 Actel Corporation.  All rights reserved.
// IP Engineering
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// File:            jtagdef.v
//
// Description:     OCI JTAG definitions
//
// Rev:             1.2  Dec06
//
// Notes:
//
//-----------------------------------------------------------------------------


                         //-------------------//
                         //                   //
                         //    DEFINITIONS    //
                         //                   //
                         //-------------------//

//
// UJTAG IR codes
//
parameter UI_IRCODE = 8'b00110000;
parameter UI_DRCODE = 8'b00110001;

//
// JTAG IR Classes
//
parameter IRC_JTAG     = 3'b000;
parameter IRC_JTAG1    = 3'b001;
parameter IRC_TRACECMD = 3'b010;
parameter IRC_DEBUGCMD = 3'b011;
parameter IRC_CMD      = 3'b100;
parameter IRC_TRIGGER  = 3'b101;
parameter IRC_TRACE    = 3'b110;
parameter IRC_BYPASS   = 3'b111;

//
// JTAG IR instructions
//
parameter IR_EXTEST = 8'b00000000;
parameter IR_SAMPLE = 8'b00000001;
parameter IR_IDCODE = 8'b00000010;

//
// Trace commands
//   bit 2 indicates a trace state change
//   bit 1 is clear trace command
//   bit 0 is new trace run state
//
parameter IR_TraceAddr  = 8'b01000000;
parameter IR_TraceStop  = 8'b01000100;
parameter IR_TraceStart = 8'b01000101;
parameter IR_TraceClear = 8'b01000110;

//
// Debug commands
//    bit 4 is new JReset state
//    bit 3 indicates a change to debugreq
//    bit 2 pulses DebugStep at Update-IR
//    bit 1 pulses DebugStep at Update-DR
//    bit 0 is new debugreq state (if bit 3 is set)
//
parameter IR_DebugNop      = 8'b01100000;
parameter IR_ResetCPU      = 8'b01111001;
parameter IR_DebugReqOff   = 8'b01101000;
parameter IR_DebugReqOn    = 8'b01101001;
parameter IR_DebugStepUser = 8'b01101101;
parameter IR_DebugStepOCI  = 8'b01101011;
parameter IR_DebugPswrOn   = 8'b10000001;
parameter IR_DebugPswrOff  = 8'b10000000;
parameter IR_AuxOn         = 8'b10000110;
parameter IR_AuxOff        = 8'b10000100;
// 2 lsb's are the trigger id
parameter IR_Trigger       = 8'b10100000;
parameter IR_GetPC         = 8'b11010000;
parameter IR_TraceData     = 8'b11011000;
parameter IR_BYPASS        = 8'b11111111;

//
// Trigger bus select codes
//
parameter TRIGMODE_PROGRD    = 3'b000;
parameter TRIGMODE_PROGWR    = 3'b001;
parameter TRIGMODE_XDATARD   = 3'b010;
parameter TRIGMODE_XDATAWR   = 3'b011;
parameter TRIGMODE_IDATARD   = 3'b100;
parameter TRIGMODE_IDATAWR   = 3'b101;
parameter TRIGMODE_SFRRD     = 3'b110;
parameter TRIGMODE_SFRWR     = 3'b111;
// version number increments with each change
parameter IDCODE_A8051       = 8'b01100000;
parameter IDCODE_A8051_UJTAG = 8'b01101000;
// trap opcode
parameter BKPT = 8'b10100101;

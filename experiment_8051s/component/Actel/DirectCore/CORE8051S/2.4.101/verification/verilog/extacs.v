//-----------------------------------------------------------------------------
// Copyright 2006 Actel Corporation.  All rights reserved.
// IP Engineering
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// File:            extacs.v
//
// Description:     External access comparator
//
//
// Rev:             1.2  Dec06
//
// Notes:
//
//-----------------------------------------------------------------------------

`timescale 1 ns / 100 ps

module EXTERNAL_ACCESS_COMPARATOR (rst, addrbus, databus, wr, PWRITE, PENABLE, PWDATA, PADDR);

  parameter MODE        = 2;    // Comparator mode
                                // 0 - no occurrence
                                // 1 - the COMPFILE writer
                                // 2 - vectors comparator
  parameter DATAWIDTH   = 8;
  parameter ADDRWIDTH   = 16;
  parameter TESTNAME    = "test001";
  parameter TESTPATH    = "tests";
  parameter COMPFILE    = "acscomp.txt";
  parameter DIFFFILE    = "acsdiff.txt";
  parameter NO_OF_LINES = 3000;

// TFB 10/29/03
// characters per line (including '\r' and '\n')
parameter CHPL			= 50;
parameter CHBITS		= CHPL*8;
parameter V_MSB			= (CHBITS*4)-1;

  input     rst;
  input     [ADDRWIDTH-1 : 0] addrbus;
  input     [DATAWIDTH-1 : 0] databus;
  input     wr;
  input     PWRITE;
  input     PENABLE;
  input     [7:0] PWDATA;
  input     [11:0] PADDR;

  reg       [63:0] compmem [0 : 3*NO_OF_LINES-1];
  integer   comp; // file descriptor
  integer   diff; // file descriptor

  time      time_v;
  reg       [ADDRWIDTH-1 : 0] address_v;
  reg       [DATAWIDTH-1 : 0] data_v;
  reg       stop, EOF;
  integer   errors;
  integer   i;

integer				haddr; // highest address
reg	[31:0]	 		time_mem	[0:NO_OF_LINES-1];
reg	[ADDRWIDTH-1:0]	address_mem	[0:NO_OF_LINES-1];
reg	[DATAWIDTH-1:0] data_mem	[0:NO_OF_LINES-1];
integer				raddr; // current read address from sim mems

reg addrMissingSFR;
reg clrAddrMissingSFR;

// initialize simulation memories from external ASCII file
initial
begin: init_mems
	integer			j;
	integer			charnum;
	reg	[CHBITS:1]	raw_line;	// up to 80 characters (bytes) per line

	haddr			= 0;
	raddr			= 0;
    clrAddrMissingSFR = 1'b0;

	if (MODE==1)
	begin
		//comp = $fopen({TESTPATH,"/",TESTNAME,"/",COMPFILE});
		comp = $fopen({"opcode_",TESTNAME,"_",COMPFILE});
		$fdisplay(comp, "   Time     Address         Data");
	end
	if (MODE==2)
	begin
		//diff = $fopen ({TESTPATH,"/",TESTNAME,"/",DIFFFILE});
		diff = $fopen({"opcode_",TESTNAME,"_",DIFFFILE});
		stop = 1'b0;
		EOF  = 1'b0;
		errors = 0;

		// open file
		//comp = $fopen({TESTPATH,"/",TESTNAME,"/",COMPFILE},"r");
		comp = $fopen({"opcode_",TESTNAME,"_",COMPFILE},"r");
		// read each line and process, storing data in sim memories
		charnum	= $fgets(raw_line,comp);
		while (charnum)
		begin
			convline(raw_line);
			charnum	= $fgets(raw_line,comp);
		end
		// if haddr is still 0 at this point, no valid lines in file, EOF
		if (!haddr) EOF = 1'b1;
    end
end

assign apb_write = PWRITE && PENABLE;

//----------------------------------------------------------------//
// writer / reader
//----------------------------------------------------------------//
always @(posedge wr or posedge apb_write)
begin : compare
	begin : create
		if (MODE != 1) disable compare.create;
		if ( !rst )
		$fdisplay(comp, "%0d ns %b  %b  ", $time, addrbus, databus);
	end
	//--------------------------------
	// Vectors comparing
	//--------------------------------
	if (MODE != 2) disable compare;
	if ( rst == 1'b0 )
	begin : dataread
		//-----------------------------
		// Reading vectors
		//-----------------------------
		address_v	= address_mem[raddr];
		data_v		= data_mem[raddr];

        // Check for correct write data in APB writes
        if (apb_write)
        begin
		    if (data_v !== PWDATA)
		    begin
			    errors = errors + 1;
			    $fdisplay(diff, "%0d : PWDATA[7:0] is %b but expected is %b",
				    $time, PWDATA, data_v);
		    end
		    if (address_v[11:0] !== PADDR)
		    begin
			    errors = errors + 1;
			    $fdisplay(diff, "%0d : PADDR is %b but expected is %b",
				    $time, PADDR, address_v[11:0]);
		    end
        end
        else
        begin
		    if (data_v !== databus)
		    begin
			    errors = errors + 1;
			    $fdisplay(diff, "%0d : Data is %b but expected is %b",
				    $time, databus, data_v);
		    end
		    if (address_v !== addrbus)
		    begin
			    errors = errors + 1;
			    $fdisplay(diff, "%0d : address is %b but expected is %b",
				    $time, addrbus, address_v);
		    end
        end
		raddr = raddr + 1;
		if (raddr==haddr) EOF = 1'b1;
		if (EOF) disable dataread;
	end
	//--------------------------------
	// Report writing
	//--------------------------------
	if (EOF && !stop)
	begin
		$display("End of the external access test detected.");
		$fdisplay(diff, "%0d  : End of the external access test detected.",
			$time);
		if (errors==0)
		begin
			$display("The external access test %s passed.", TESTNAME);
			$fdisplay(diff,"The external access test passed.");
		end
		else
		begin
			$write(
			"The external access test %s failed. Differences are in the file ",
				TESTNAME);
			//$write("%s/", TESTPATH);
			//$write("%s/", TESTNAME);
			$write("opcode_%s_%s", TESTNAME, DIFFFILE);
			$fdisplay(diff, "The external access test failed.");
			$fdisplay(diff, "%0d difference(s) detected", errors);
		end
		stop = 1'b1;
		$fclose(comp);
		$fclose(diff);
	end
end

// ------------------------- tasks/functions -----------------------------

// process current line of string data
task convline;
input [CHBITS:1]		line;
	integer				ssresult;
	reg	[8*8:1]			time_s;
	reg	[2*8:1]			ns_s;		// ns declaration
	reg	[ADDRWIDTH*8:1]	address_s;
	reg	[DATAWIDTH*8:1]	data_s;
begin

	// get fields from acscomp.txt file
	ssresult = $sscanf(line,"%s%s%s%s",time_s,ns_s,address_s,data_s);

	if ((ssresult)&&(ns_s=="ns"))
	begin
		time_mem		[haddr] = strtodec(time_s);
		address_mem		[haddr] = slvtoword(address_s);
		data_mem		[haddr] = slvtobyte(data_s);
		haddr = haddr + 1;
	end
end
endtask

// small function to convert VHDL std_logic_vector string to verilog vector
function	[15:0]	slvtoword;
input		[127:0]	slv;
integer				i;
begin
	for (i=0;i<16;i=i+1)
		slvtoword[i]	= sltobit(8'hff&(slv>>(8*i)));
end
endfunction

// small function to convert VHDL std_logic_vector string to verilog vector
function	[7:0]	slvtobyte;
input		[63:0]	slv;
integer				i;
begin
	for (i=0;i<8;i=i+1)
		slvtobyte[i]	= sltobit(8'hff&(slv>>(8*i)));
end
endfunction

// small function to convert VHDL std_logic character to 0,1,x, or z
function			sltobit;
input		[7:0]	ch;
begin
	case (ch)
	"0":		sltobit=1'b0;	// '0'
	"1":		sltobit=1'b1;	// '1'
	"L":		sltobit=1'b0;	// 'L'
	"H":		sltobit=1'b1;	// 'H'
	"W":		sltobit=1'bx;	// 'W'
	"Z":		sltobit=1'bz;	// 'Z'
	"U":		sltobit=1'bx;	// 'U'
	"X":		sltobit=1'bx;	// 'X'
	"-":		sltobit=1'bx;	// '-'
	default:	sltobit=1'bx;
	endcase
end
endfunction

// small function to convert hex string to decimal
function	[31:0]		strtodec;
input		[V_MSB:0]	s;
reg			[V_MSB:0]	hexstr;
integer					m;
begin
	strtodec	= 0;
	hexstr		= s;
	m			= 1;
	while (hexstr)
	begin
		strtodec	= strtodec + (m*(hextonib(hexstr[7:0])));
		hexstr		= hexstr>>8;
		m			= m * 10;
	end
end
endfunction

// small function to convert hex character to nibble
function	[3:0]	hextonib;
input		[7:0]	ch;
begin
	if ((ch>="0")&&(ch<="9"))		hextonib = (4'hf&(ch - 8'h30));
	else if	((ch>="A")&&(ch<="F"))	hextonib = (4'hf&(ch - 8'd55));
	else if	((ch>="a")&&(ch<="f"))	hextonib = (4'hf&(ch - 8'd87));
end
endfunction


endmodule // module EXTERNAL_ACCESS_COMPARATOR

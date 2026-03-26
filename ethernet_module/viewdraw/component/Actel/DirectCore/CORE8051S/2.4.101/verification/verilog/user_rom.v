//-----------------------------------------------------------------------------
// Copyright 2006 Actel Corporation.  All rights reserved.
// IP Engineering
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// File:            user_rom.v
//
// Description:     ROM that reads external .dat ASCII file with one
//                  Hexadecimal byte per line - hex ASCII byte must be first
//                  character on line - anything after hex byte will be ignored
//
// Rev:             1.2  Dec06
//
// Notes:
//
//-----------------------------------------------------------------------------
module USER_ROM (clk, oe, addr, dout);

parameter WIDTH		= 8;	// data width
parameter DEPTH		= 4096;	// ROM depth
parameter ASIZE		= 12;	// address width
parameter ROMFILE	= "rom.hex";

parameter CHPL		= 50; // characters per line
parameter CHBITS	= CHPL*8;
parameter V_MSB		= (CHBITS*4)-1;

input					clk;	// Clock input
input                   oe;     // output enable
input	[ASIZE - 1:0]	addr;	// ROM address
output	[WIDTH - 1:0]	dout;	// ROM data out (available next rising clk)
wire    [WIDTH - 1:0]	dout;
reg		[WIDTH - 1:0]	dataout;
reg		[WIDTH - 1:0]	store		[0:DEPTH - 1];

reg		[CHBITS:1]		raw_line;// up to CHPL characters (bytes) per line
integer  				hexlines;// number of lines (records) in intel Hex file
// sim memories to hold size of each record, and each record
reg		[7:0]			sizemem		[0:DEPTH - 1];
reg		[V_MSB:0]		recordmem	[0:DEPTH - 1];

reg						initialized;
reg		[ASIZE-1:0]		addr_01;// get rid of x's or z's in address
integer					fd;		//file descriptor

//-------------------------------------------------------------------
// main
//-------------------------------------------------------------------

// dout bus is driven when oe is high
assign dout = (oe == 1'b1) ? dataout : {WIDTH{1'bz}};

//-------------------------------------------------------------------
// initialize ROM
//-------------------------------------------------------------------
initial
begin: initrom
integer i;
	// initialize ROM to all 0's before reading file, in case file is
	// not present, etc.
	for(i=0;i<DEPTH;i=i+1)
		store[i] = {WIDTH{1'b0}};
	// open file
	fd = $fopen(ROMFILE,"r");
	initmems;
	initialized = 1'b1;
end


//--------------------------------------
// Convert address to only 1's and 0's
// (get rid of x's or z's)
//--------------------------------------
always @(addr)
begin: addr_conv
integer i;
	for (i=ASIZE-1;i>=0;i=i-1)
	begin
		if (addr[i] === 1'b1)	addr_01[i] = 1'b1;
		else					addr_01[i] = 1'b0;
	end
end

//-------------------------------------------------------------------
// read ROM
//-------------------------------------------------------------------
always @(posedge clk)
begin: rdmem
	wait (initialized);
	dataout <= store[addr_01];
end

//------------------------------ tasks,functions ---------------------------

task initmems;
integer			EOF;
reg [V_MSB:0]	hexrecord;
integer			recsize;
integer			length;
reg	[7:0]		rtype;
integer			charnum;
integer			idx;
integer			i;
reg	[15:0]		a;
begin
	hexlines	= 0;
	// get raw ASCII data from external hex file and store in sim mems
	charnum		= $fgets(raw_line,fd);
	while (charnum) begin
		convline(charnum);
		charnum	= $fgets(raw_line,fd);
	end

	// process each hex record (line)
	idx		= 0;
	EOF		= 0;
	while (!EOF && idx<hexlines)
	begin
		hexrecord			= recordmem[idx];
		recsize				= sizemem[idx];
		idx					= idx + 1;
		// get record length, address, type
		length				= 8'hff & (hexrecord>>((recsize-1)*8));
		a					= 16'hffff & (hexrecord>>((recsize-3)*8));
		rtype				= 8'hff & (hexrecord>>((recsize-4)*8));
		EOF					= (rtype == 8'h01); // EOF record

		if (!EOF)
		begin
			for (i=5;i<recsize;i=i+1)
			begin
				store[a]	= 8'hff & (hexrecord>>((recsize-i)*8));
				a			= a + 1;
			end
		end

		if (!(goodchecksum(hexrecord,recsize)))
		begin
			$display("Invalid check sum in the program memory init file.");
			$display("Check line: %0d in %s file.", idx, ROMFILE);
			$stop;
		end
	end
end
endtask

// strip off ':' char at beginning of line, '\r', \n' chars at end of line,
// convert to vector and store in recordmem memory, store size in bits
// in sizemem memory
task convline;
input	[7:0]	chnum;
reg		[7:0]	ch;
reg [V_MSB:0]	v;// converted vector (nibble characters to vector)
integer			j;
integer			n;
begin
	v = 0;
	// get 1st character of line to check that it's a ':'
	ch=((raw_line>>(8*(chnum-1)))&8'hff);
	if (ch != ":")
		$display("*** Error, first charcter is not the ':' char! It is '%c'",
		ch);
	n = 0;
	for (j=2;j<=chnum;j=j+1) begin
		// get each character, ignore everything except hex chars
		ch=((raw_line>>(8*(chnum-j)))&8'hff);
		// if hex char matches, shift v left by 1 nibble and append hex nibble
		if		((ch>="0")&&(ch<="9")) begin
			v		= v<<4;
			v[3:0]	= (4'hf&(ch - 8'h30));
			n		= n + 1;
		end
		else if	((ch>="A")&&(ch<="F")) begin
			v		= v<<4;
			v[3:0]	= (4'hf&(ch - 8'd55));
			n		= n + 1;
		end
		else if	((ch>="a")&&(ch<="f")) begin
			v		= v<<4;
			v[3:0]	= (4'hf&(ch - 8'd87));
			n		= n + 1;
		end
	end
	// store results in sim memories
	recordmem[hexlines]	= v;
	sizemem[hexlines]	= n/2;
	hexlines			= hexlines + 1;
end
endtask

// check that the checksum is good for given vector
function goodchecksum;
input	[V_MSB:0]	v;
input	[7:0]		vsize;
integer				i;
reg		[7:0]		cs;
begin
	cs = 0;
	for (i=1;i<=vsize;i=i+1)
		cs = cs + (8'hff&(v>>((vsize-i)*8)));
	// checksum should be 0 after adding the checksum byte to all previously
	// added bytes of record
	goodchecksum = (cs == 8'h0);
end
endfunction

endmodule

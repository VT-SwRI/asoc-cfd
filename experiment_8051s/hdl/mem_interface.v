///////////////////////////////////////////////////////////////////////////////////////////////////
// File: mem_interface.v
//
// Description:
//   Memory interface between Core8051s and Two-Port RAM (program memory).
//
//   Configuration:
//     - Core8051s program memory: MEMPSACKI-controlled (check the box)
//     - Core8051s data memory: fixed 0 stretch cycles (unchecked)
//     - Debug: disabled
//     - RAM: Two-Port, 4096x8, no pipeline, single clock, active-high enables
//     - Data memory (MOVX) handled by APB bus for addresses 0xF000-0xFFFF
//
//   The RAM4K9 blocks are synchronous - they latch the address on the
//   rising clock edge and output data one cycle later. MEMPSACKI is
//   delayed by one clock to tell the processor when valid data is ready.
//
// Targeted device: Family::ProASIC3E, Die::A3PE1500, Package::208 PQFP
///////////////////////////////////////////////////////////////////////////////////////////////////

module mem_interface (
    input         CLK,
    input         RESETN,

    // From/To Core8051s ExternalMemIf
    input  [15:0] MEMADDR,       // Memory address bus
    input   [7:0] MEMDATAO,      // Write data from core (unused)
    input         MEMPSRD,       // Program memory read strobe
    input         MEMRD,         // Data memory read (unused)
    input         MEMWR,         // Data memory write (unused)
    output        MEMPSACKI,     // Program read acknowledge
    output        MEMACKI,       // Data read/write acknowledge
    output  [7:0] MEMDATAI,      // Read data back to core

    // To/From ram_core (Two-Port RAM, program memory only)
    output [11:0] RADDR,         // Read address
    output        REN,           // Read enable (active high)
    input   [7:0] RD             // Read data out
);

    // ---- Program Memory Read ----
    assign RADDR = MEMADDR[11:0];
    assign REN   = MEMPSRD;
    assign MEMDATAI = RD;

    // ---- Program Memory Acknowledge ----
    // The RAM is synchronous: data appears one clock cycle after
    // the address and REN are presented. Delay MEMPSACKI by one
    // cycle so the processor knows when to sample valid data.
    reg psack_reg;
    always @(posedge CLK or negedge RESETN) begin
        if (!RESETN)
            psack_reg <= 1'b0;
        else
            psack_reg <= MEMPSRD;
    end
    assign MEMPSACKI = psack_reg;

    // ---- Data Memory Acknowledge ----
    // No external data RAM - APB handles data via PREADY.
    // Tie high so accidental non-APB accesses don't hang.
    assign MEMACKI = 1'b1;

endmodule
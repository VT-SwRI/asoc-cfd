///////////////////////////////////////////////////////////////////////////////////////////////////
// File: tb_top.v
//
// Description:
//   Testbench for Core8051s LED blink system.
//   Drives clock (40 MHz) and reset, then monitors the LED output.
//   
//   What to look for in simulation:
//     - After reset deasserts, Core8051s begins fetching from address 0x0000
//     - MEMPSRD should toggle as instructions are fetched
//     - Eventually GPIO_OUT (LED) should toggle
//     - The full blink delay will take millions of cycles, so for initial
//       testing just verify the processor boots and starts executing.
//
///////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module tb_top;

    // ---- Signals ----
    reg         CLK;
    reg         NSYSRESET;
    wire [0:0]  LED;

    // ---- Instantiate your top-level design ----
    // Adjust the module name to match your SmartDesign top-level name
    top DUT (
        .SYSCLK     (CLK),
        .NSYSRESET  (NSYSRESET),
        .LED        (LED)
    );

    // ---- 40 MHz clock: 25 ns period ----
    initial CLK = 1'b0;
    always #12.5 CLK = ~CLK;

    // ---- Reset sequence ----
    initial begin
        NSYSRESET = 1'b0;       // Assert reset (active low)
        #200;                    // Hold reset for 200 ns (8 clock cycles)
        NSYSRESET = 1'b1;       // Release reset
    end

    // ---- Monitor LED output ----
    // Print a message whenever LED changes
    always @(LED) begin
        $display("TIME=%0t ns : LED = %b", $time, LED);
    end

    // ---- Simulation timeout ----
    // The full blink takes ~0.5 sec = 500,000,000 ns which is too long.
    // Run for 50 ms to verify the processor boots and executes.
    // If you see MEMPSRD toggling and addresses incrementing, it's working.
    // Increase this if you want to see the actual LED toggle.
    initial begin
        #50_000_000;            // 50 ms
        $display("---- Simulation timeout reached (50 ms) ----");
        $display("---- LED final state: %b ----", LED);
        $stop;
    end

    // ---- Optional: dump waveforms ----
    // Uncomment these lines if your simulator supports VCD dump
    // initial begin
    //     $dumpfile("led_blink.vcd");
    //     $dumpvars(0, tb_top);
    // end

endmodule
module rmii_led_toggle (
    input  wire       ref_clk,       // 50 MHz RMII reference clock
    input  wire [1:0] rxd,           // RMII receive data
    input  wire       rx_er,         // optional: receive error
    output reg        led            // LED output, toggles per packet
);

    reg rxd_prev; // previous sample to detect start of packet

    always @(posedge ref_clk) begin
        // Detect start of a packet: RXD goes from 0 -> non-zero
        if (rxd != 2'b00 && rxd_prev == 1'b0 && !rx_er) begin
            led <= ~led; // toggle LED
        end
        // Update previous RXD state
        rxd_prev <= (rxd != 2'b00) ? 1'b1 : 1'b0;
    end

endmodule
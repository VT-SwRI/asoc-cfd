module led_blinker (
    input  wire clk,      // 50 MHz system clock
    input  wire rx_dv,    // RX_DV from PHY
    output reg  led
);

reg rx_dv_d; // delayed version of rx_dv

always @(posedge clk) begin
    rx_dv_d <= rx_dv;               // sample RX_DV
    if (rx_dv & ~rx_dv_d)           // rising edge detected
        led <= ~led;                // toggle LED
end

endmodule
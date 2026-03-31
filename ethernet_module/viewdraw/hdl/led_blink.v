module led_blink (
    input  wire clk,   // 40 MHz clock (CLOCKF)
    input  wire SW0,
    output reg  D1
);

reg [25:0] counter = 0;   // 26 bits enough for 40M
reg led_state = 0;

always @(posedge clk) begin
    if (!SW0) begin  // button pressed (active low)
        if (counter == 40_000_000 - 1) begin
            counter   <= 0;
            led_state <= ~led_state;  // toggle every second
        end else begin
            counter <= counter + 1;
        end
    end else begin
        // button not pressed ? reset everything
        counter   <= 0;
        led_state <= 0;
    end

    D1 <= led_state;
end

endmodule
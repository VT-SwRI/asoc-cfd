// trigger_detector.sv - Simple threshold trigger; asserts trig when sample crosses threshold.
module trigger_detector #(
  parameter int SAMPLE_W = 14
)(
  input  logic                      clk,
  input  logic                      rst_n,
  input  logic signed [SAMPLE_W-1:0] threshold,
  input  logic                      s_valid,
  input  logic signed [SAMPLE_W-1:0] s_data,
  output logic                      trig_pulse
);
  logic prev_above;
  logic above;

  always_comb begin
    above = (s_data > threshold);
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_above <= 1'b0;
      trig_pulse <= 1'b0;
    end else begin
      trig_pulse <= 1'b0;
      if (s_valid) begin
        if (!prev_above && above) trig_pulse <= 1'b1;
        prev_above <= above;
      end
    end
  end
endmodule

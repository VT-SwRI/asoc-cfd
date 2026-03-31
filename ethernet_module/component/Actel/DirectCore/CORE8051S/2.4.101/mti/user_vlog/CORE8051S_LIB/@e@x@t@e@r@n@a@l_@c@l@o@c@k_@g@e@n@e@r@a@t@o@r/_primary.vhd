library verilog;
use verilog.vl_types.all;
entity EXTERNAL_CLOCK_GENERATOR is
    generic(
        PERIOD          : integer := 100;
        DUTY            : integer := 50
    );
    port(
        clk             : out    vl_logic
    );
end EXTERNAL_CLOCK_GENERATOR;

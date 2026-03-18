library verilog;
use verilog.vl_types.all;
entity USER_ROM is
    generic(
        WIDTH           : integer := 8;
        DEPTH           : integer := 4096;
        ASIZE           : integer := 12;
        ROMFILE         : string  := "rom.hex";
        CHPL            : integer := 50
    );
    port(
        clk             : in     vl_logic;
        oe              : in     vl_logic;
        addr            : in     vl_logic_vector;
        dout            : out    vl_logic_vector
    );
end USER_ROM;

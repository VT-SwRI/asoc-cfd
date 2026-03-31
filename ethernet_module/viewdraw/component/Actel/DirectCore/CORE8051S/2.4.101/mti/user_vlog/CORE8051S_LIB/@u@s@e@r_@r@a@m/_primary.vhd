library verilog;
use verilog.vl_types.all;
entity USER_RAM is
    generic(
        WIDTH           : integer := 8;
        DEPTH           : integer := 256;
        ASIZE           : integer := 8
    );
    port(
        wclk            : in     vl_logic;
        waddr           : in     vl_logic_vector;
        wr              : in     vl_logic;
        din             : in     vl_logic_vector;
        rclk            : in     vl_logic;
        raddr           : in     vl_logic_vector;
        rd              : in     vl_logic;
        dout            : out    vl_logic_vector
    );
end USER_RAM;

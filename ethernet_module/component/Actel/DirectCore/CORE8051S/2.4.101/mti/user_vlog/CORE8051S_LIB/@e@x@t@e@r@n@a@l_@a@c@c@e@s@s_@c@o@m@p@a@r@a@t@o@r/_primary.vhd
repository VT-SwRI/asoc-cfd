library verilog;
use verilog.vl_types.all;
entity EXTERNAL_ACCESS_COMPARATOR is
    generic(
        MODE            : integer := 2;
        DATAWIDTH       : integer := 8;
        ADDRWIDTH       : integer := 16;
        TESTNAME        : string  := "test001";
        TESTPATH        : string  := "tests";
        COMPFILE        : string  := "acscomp.txt";
        DIFFFILE        : string  := "acsdiff.txt";
        NO_OF_LINES     : integer := 3000;
        CHPL            : integer := 50
    );
    port(
        rst             : in     vl_logic;
        addrbus         : in     vl_logic_vector;
        databus         : in     vl_logic_vector;
        wr              : in     vl_logic;
        PWRITE          : in     vl_logic;
        PENABLE         : in     vl_logic;
        PWDATA          : in     vl_logic_vector(7 downto 0);
        PADDR           : in     vl_logic_vector(11 downto 0)
    );
end EXTERNAL_ACCESS_COMPARATOR;

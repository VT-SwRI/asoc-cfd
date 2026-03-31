library verilog;
use verilog.vl_types.all;
entity tb_verif is
    generic(
        TESTNAME        : string  := "test001";
        TESTPATH        : string  := "tests";
        EXTROMFILE      : string  := "extrom.hex";
        ACSCOMPFILE     : string  := "acscomp.txt";
        ACSDIFFFILE     : string  := "acsdiff.txt";
        INTRAMSIZE      : integer := 8;
        INTROMSIZE      : integer := 12;
        EXTRAMSIZE      : integer := 16;
        EXTROMSIZE      : integer := 16;
        CLOCKPERIOD     : integer := 20;
        CLOCKDUTY       : integer := 50;
        ACSCOMPMODE     : integer := 2;
        DEBUG           : integer := 0;
        INCL_TRACE      : integer := 0;
        TRIG_NUM        : integer := 0;
        EN_FF_OPTS      : integer := 0;
        APB_DWIDTH      : integer := 32;
        INCL_DPTR1      : integer := 0;
        INCL_MUL_DIV_DA : integer := 1;
        VARIABLE_STRETCH: integer := 1;
        STRETCH_VAL     : integer := 1;
        VARIABLE_WAIT   : integer := 1;
        WAIT_VAL        : integer := 0;
        INTRAM_IMPLEMENTATION: integer := 0
    );
end tb_verif;

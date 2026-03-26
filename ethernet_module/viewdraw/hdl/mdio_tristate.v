///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: mdio_tristate.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module mdio_tristate( 
    inout wire mdio,
    input wire mdo,
    input wire md_en,
    output wire mdi
);

    // read input
    assign mdi = mdio;

    // drive output of mdio when enabled, otherwise high impedence
    assign mdio = md_en ? mdo : 1'bz;
//<statements>

endmodule


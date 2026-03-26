`timescale 1 ns/100 ps
// Version: v11.9 SP6 11.9.6.7
// File used only for Simulation


module led_test(
       SW0,
       clock,
       led
    );
input  SW0;
input  clock;
output led;

    wire SW0_c, clock_c, led_c, \led_blink_0/counter_n25_0_0 , 
        \led_blink_0/counter10 , \led_blink_0/counter_n25_0 , 
        \led_blink_0/counter10_17 , \led_blink_0/counter10_13 , 
        \led_blink_0/counter10_12 , \led_blink_0/counter_c3 , 
        \led_blink_0/counter10_16 , \led_blink_0/counter10_11 , 
        \led_blink_0/counter10_10 , \led_blink_0/counter10_20_2 , 
        \led_blink_0/counter10_1 , \led_blink_0/counter10_0 , 
        \led_blink_0/counter10_8 , \led_blink_0/counter[8]_net_1 , 
        \led_blink_0/counter10_6 , \led_blink_0/counter[9]_net_1 , 
        \led_blink_0/counter10_5 , \led_blink_0/counter[19]_net_1 , 
        \led_blink_0/counter[15]_net_1 , 
        \led_blink_0/counter[21]_net_1 , 
        \led_blink_0/counter[14]_net_1 , \led_blink_0/counter10_3 , 
        \led_blink_0/counter[18]_net_1 , 
        \led_blink_0/counter[16]_net_1 , 
        \led_blink_0/counter[11]_net_1 , 
        \led_blink_0/counter[12]_net_1 , 
        \led_blink_0/counter[20]_net_1 , 
        \led_blink_0/counter[10]_net_1 , 
        \led_blink_0/counter[17]_net_1 , 
        \led_blink_0/counter[13]_net_1 , 
        \led_blink_0/counter[24]_net_1 , 
        \led_blink_0/counter[23]_net_1 , 
        \led_blink_0/counter[25]_net_1 , 
        \led_blink_0/counter[22]_net_1 , 
        \led_blink_0/counter_m6_0_a2_5_7 , 
        \led_blink_0/counter_N_7_mux , \led_blink_0/counter_m6_0_a2_2 , 
        \led_blink_0/counter_m6_0_a2_5_5 , 
        \led_blink_0/counter_m6_0_a2_5_2 , 
        \led_blink_0/counter_m6_0_a2_5_1 , 
        \led_blink_0/counter_m6_0_a2_5_3 , 
        \led_blink_0/counter_m3_e_0 , \led_blink_0/counter[3]_net_1 , 
        \led_blink_0/counter[4]_net_1 , \led_blink_0/counter[5]_net_1 , 
        \led_blink_0/counter10_20_2_0 , \led_blink_0/counter[7]_net_1 , 
        \led_blink_0/counter[6]_net_1 , \led_blink_0/counter[2]_net_1 , 
        \led_blink_0/counter_c1 , \led_blink_0/counter_c17 , 
        \led_blink_0/counter_m6_0_a2_3 , \led_blink_0/counter_c15_0 , 
        \led_blink_0/counter_c17_0 , \led_blink_0/counter_c21 , 
        \led_blink_0/counter_n25 , \led_blink_0/counter_51_0 , 
        \led_blink_0/counter_c23 , \led_blink_0/counter_c2 , 
        \led_blink_0/counter_n24 , \led_blink_0/counter_n23 , 
        \led_blink_0/counter_c22 , \led_blink_0/counter_n22 , 
        \led_blink_0/counter_n21 , \led_blink_0/counter_c20 , 
        \led_blink_0/counter_n20 , \led_blink_0/counter_n20_tz , 
        \led_blink_0/counter_c19_0 , \led_blink_0/counter_n19 , 
        \led_blink_0/counter_c18 , \led_blink_0/counter_n18 , 
        \led_blink_0/counter_n17 , \led_blink_0/counter_c16 , 
        \led_blink_0/counter_n16 , \led_blink_0/counter_n16_tz , 
        \led_blink_0/counter_n15 , \led_blink_0/counter_c14 , 
        \led_blink_0/counter_n14 , \led_blink_0/counter_c13 , 
        \led_blink_0/counter_n13 , \led_blink_0/counter_c12 , 
        \led_blink_0/counter_n12 , \led_blink_0/counter_c11 , 
        \led_blink_0/counter_n11 , \led_blink_0/counter_n11_tz , 
        \led_blink_0/counter_n10 , \led_blink_0/counter_c9 , 
        \led_blink_0/counter_n9 , \led_blink_0/counter_c8 , 
        \led_blink_0/counter_n8 , \led_blink_0/counter_n8_tz , 
        \led_blink_0/counter_n7 , \led_blink_0/counter_n7_tz , 
        \led_blink_0/counter_n6 , \led_blink_0/counter_c5 , 
        \led_blink_0/counter_n5 , \led_blink_0/counter_n5_tz , 
        \led_blink_0/counter_n4 , \led_blink_0/counter_n3 , 
        \led_blink_0/counter_n2 , \led_blink_0/counter[1]_net_1 , 
        \led_blink_0/counter[0]_net_1 , \led_blink_0/counter_2_0 , 
        \led_blink_0/counter_4_0 , \led_blink_0/counter_m3_0_a2_4 , 
        \led_blink_0/counter_m3_0_a2_1 , 
        \led_blink_0/counter_m3_0_a2_2 , \led_blink_0/counter_n1 , 
        \led_blink_0/counter_n0 , \led_blink_0/led_state_4 , 
        \led_blink_0/led_state_net_1 , \SW0_pad/U0/NET1 , 
        \led_pad/U0/NET1 , \led_pad/U0/NET2 , VCC, \clock_pad/U0/NET1 , 
        AFLSDF_VCC, AFLSDF_GND;
    wire GND_power_net1;
    wire VCC_power_net1;
    assign AFLSDF_GND = GND_power_net1;
    assign VCC = VCC_power_net1;
    assign AFLSDF_VCC = VCC_power_net1;
    
    AX1C \led_blink_0/counter_RNO_0[16]  (.A(
        \led_blink_0/counter_m6_0_a2_3 ), .B(
        \led_blink_0/counter_c15_0 ), .C(
        \led_blink_0/counter[16]_net_1 ), .Y(
        \led_blink_0/counter_n16_tz ));
    NOR2B \led_blink_0/counter_RNIOEKL[9]  (.A(
        \led_blink_0/counter[9]_net_1 ), .B(
        \led_blink_0/counter_m3_e_0 ), .Y(
        \led_blink_0/counter_m3_0_a2_2 ));
    NOR2B \led_blink_0/counter_RNISM9B[2]  (.A(
        \led_blink_0/counter[2]_net_1 ), .B(
        \led_blink_0/counter[8]_net_1 ), .Y(
        \led_blink_0/counter_m3_0_a2_1 ));
    NOR3C \led_blink_0/counter_RNI9D9R[8]  (.A(
        \led_blink_0/counter[9]_net_1 ), .B(
        \led_blink_0/counter[8]_net_1 ), .C(
        \led_blink_0/counter_m3_e_0 ), .Y(
        \led_blink_0/counter_N_7_mux ));
    XA1 \led_blink_0/counter_RNO[13]  (.A(
        \led_blink_0/counter[13]_net_1 ), .B(\led_blink_0/counter_c12 )
        , .C(\led_blink_0/counter_n25_0_0 ), .Y(
        \led_blink_0/counter_n13 ));
    XA1 \led_blink_0/counter_RNO[12]  (.A(
        \led_blink_0/counter[12]_net_1 ), .B(\led_blink_0/counter_c11 )
        , .C(\led_blink_0/counter_n25_0_0 ), .Y(
        \led_blink_0/counter_n12 ));
    AX1C \led_blink_0/counter_RNO_0[7]  (.A(\led_blink_0/counter_c5 ), 
        .B(\led_blink_0/counter[6]_net_1 ), .C(
        \led_blink_0/counter[7]_net_1 ), .Y(
        \led_blink_0/counter_n7_tz ));
    AX1C \led_blink_0/counter_RNO_0[11]  (.A(
        \led_blink_0/counter10_20_2 ), .B(
        \led_blink_0/counter_m3_0_a2_4 ), .C(
        \led_blink_0/counter[11]_net_1 ), .Y(
        \led_blink_0/counter_n11_tz ));
    NOR3C \led_blink_0/counter_RNO_0[21]  (.A(
        \led_blink_0/counter_c17 ), .B(\led_blink_0/counter_c19_0 ), 
        .C(\led_blink_0/counter[20]_net_1 ), .Y(
        \led_blink_0/counter_c20 ));
    NOR3C \led_blink_0/counter_RNO_0[15]  (.A(
        \led_blink_0/counter_N_7_mux ), .B(
        \led_blink_0/counter_m6_0_a2_2 ), .C(
        \led_blink_0/counter_m6_0_a2_3 ), .Y(\led_blink_0/counter_c14 )
        );
    NOR3C \led_blink_0/counter_RNI90C93[14]  (.A(
        \led_blink_0/counter10_11 ), .B(\led_blink_0/counter10_10 ), 
        .C(\led_blink_0/counter10_20_2 ), .Y(
        \led_blink_0/counter10_16 ));
    NOR2B \led_blink_0/counter_RNO_0[25]  (.A(
        \led_blink_0/counter[24]_net_1 ), .B(\led_blink_0/counter_c23 )
        , .Y(\led_blink_0/counter_51_0 ));
    DFN1 \led_blink_0/counter[19]  (.D(\led_blink_0/counter_n19 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[19]_net_1 ));
    NOR2B \led_blink_0/counter_RNO[8]  (.A(\led_blink_0/counter_n25_0 )
        , .B(\led_blink_0/counter_n8_tz ), .Y(\led_blink_0/counter_n8 )
        );
    NOR2B \led_blink_0/counter_RNIRJMK[20]  (.A(
        \led_blink_0/counter[20]_net_1 ), .B(
        \led_blink_0/counter[16]_net_1 ), .Y(
        \led_blink_0/counter_m6_0_a2_5_2 ));
    NOR3B \led_blink_0/counter_RNIQCVV[8]  (.A(
        \led_blink_0/counter[8]_net_1 ), .B(\led_blink_0/counter10_6 ), 
        .C(\led_blink_0/counter[9]_net_1 ), .Y(
        \led_blink_0/counter10_12 ));
    NOR2B \led_blink_0/counter_RNIF6KK5[8]  (.A(
        \led_blink_0/counter_m6_0_a2_5_7 ), .B(
        \led_blink_0/counter_m6_0_a2_3 ), .Y(\led_blink_0/counter_c21 )
        );
    DFN1 \led_blink_0/counter[0]  (.D(\led_blink_0/counter_n0 ), .CLK(
        clock_c), .Q(\led_blink_0/counter[0]_net_1 ));
    DFN1E0 \led_blink_0/led_state  (.D(\led_blink_0/led_state_4 ), 
        .CLK(clock_c), .E(\led_blink_0/counter_n25_0 ), .Q(
        \led_blink_0/led_state_net_1 ));
    NOR3C \led_blink_0/counter_RNIU5UG[1]  (.A(
        \led_blink_0/counter[0]_net_1 ), .B(
        \led_blink_0/counter[1]_net_1 ), .C(
        \led_blink_0/counter[2]_net_1 ), .Y(\led_blink_0/counter_c2 ));
    NOR3C \led_blink_0/counter_RNILDRI1[8]  (.A(
        \led_blink_0/counter_c3 ), .B(\led_blink_0/counter10_20_2 ), 
        .C(\led_blink_0/counter[8]_net_1 ), .Y(
        \led_blink_0/counter_c8 ));
    DFN1 \led_blink_0/counter[16]  (.D(\led_blink_0/counter_n16 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[16]_net_1 ));
    NOR2B \led_blink_0/counter_RNIVP9B[7]  (.A(
        \led_blink_0/counter[7]_net_1 ), .B(
        \led_blink_0/counter[6]_net_1 ), .Y(
        \led_blink_0/counter10_20_2_0 ));
    NOR3C \led_blink_0/counter_RNIS75U1[16]  (.A(
        \led_blink_0/counter10_1 ), .B(\led_blink_0/counter10_0 ), .C(
        \led_blink_0/counter10_8 ), .Y(\led_blink_0/counter10_13 ));
    DFN1 \led_blink_0/counter[7]  (.D(\led_blink_0/counter_n7 ), .CLK(
        clock_c), .Q(\led_blink_0/counter[7]_net_1 ));
    DFN1 \led_blink_0/counter[6]  (.D(\led_blink_0/counter_n6 ), .CLK(
        clock_c), .Q(\led_blink_0/counter[6]_net_1 ));
    DFN1 \led_blink_0/counter[4]  (.D(\led_blink_0/counter_n4 ), .CLK(
        clock_c), .Q(\led_blink_0/counter[4]_net_1 ));
    NOR2B \led_blink_0/counter_RNIJD9B[1]  (.A(
        \led_blink_0/counter[1]_net_1 ), .B(
        \led_blink_0/counter[0]_net_1 ), .Y(\led_blink_0/counter_c1 ));
    DFN1 \led_blink_0/counter[24]  (.D(\led_blink_0/counter_n24 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[24]_net_1 ));
    XA1 \led_blink_0/counter_RNO[9]  (.A(
        \led_blink_0/counter[9]_net_1 ), .B(\led_blink_0/counter_c8 ), 
        .C(\led_blink_0/counter_n25_0 ), .Y(\led_blink_0/counter_n9 ));
    NOR2B \led_blink_0/counter_RNO[20]  (.A(
        \led_blink_0/counter_n25_0 ), .B(\led_blink_0/counter_n20_tz ), 
        .Y(\led_blink_0/counter_n20 ));
    DFN1 \led_blink_0/counter[15]  (.D(\led_blink_0/counter_n15 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[15]_net_1 ));
    NOR2 \led_blink_0/led_state_RNO  (.A(SW0_c), .B(
        \led_blink_0/led_state_net_1 ), .Y(\led_blink_0/led_state_4 ));
    NOR3C \led_blink_0/counter_RNIJO6B4[17]  (.A(
        \led_blink_0/counter_m6_0_a2_3 ), .B(
        \led_blink_0/counter_c15_0 ), .C(\led_blink_0/counter_c17_0 ), 
        .Y(\led_blink_0/counter_c17 ));
    XA1 \led_blink_0/counter_RNO[21]  (.A(
        \led_blink_0/counter[21]_net_1 ), .B(\led_blink_0/counter_c20 )
        , .C(\led_blink_0/counter_n25_0_0 ), .Y(
        \led_blink_0/counter_n21 ));
    NOR2B \led_blink_0/counter_RNI0OLK[15]  (.A(
        \led_blink_0/counter[15]_net_1 ), .B(
        \led_blink_0/counter[17]_net_1 ), .Y(
        \led_blink_0/counter_m6_0_a2_5_1 ));
    DFN1 \led_blink_0/counter[21]  (.D(\led_blink_0/counter_n21 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[21]_net_1 ));
    DFN1 \led_blink_0/counter[17]  (.D(\led_blink_0/counter_n17 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[17]_net_1 ));
    XA1 \led_blink_0/counter_RNO[3]  (.A(
        \led_blink_0/counter[3]_net_1 ), .B(\led_blink_0/counter_c2 ), 
        .C(\led_blink_0/counter_n25_0 ), .Y(\led_blink_0/counter_n3 ));
    NOR3 \led_blink_0/counter_RNO[0]  (.A(
        \led_blink_0/counter[0]_net_1 ), .B(SW0_c), .C(
        \led_blink_0/counter10 ), .Y(\led_blink_0/counter_n0 ));
    NOR2 \led_blink_0/counter_RNINAA87_0[8]  (.A(SW0_c), .B(
        \led_blink_0/counter10 ), .Y(\led_blink_0/counter_n25_0 ));
    NOR2B \led_blink_0/counter_RNI1PLK[17]  (.A(
        \led_blink_0/counter[17]_net_1 ), .B(
        \led_blink_0/counter[16]_net_1 ), .Y(
        \led_blink_0/counter_c17_0 ));
    NOR3C \led_blink_0/counter_RNIQFJM[5]  (.A(
        \led_blink_0/counter[4]_net_1 ), .B(
        \led_blink_0/counter[5]_net_1 ), .C(
        \led_blink_0/counter10_20_2_0 ), .Y(
        \led_blink_0/counter10_20_2 ));
    NOR2 \led_blink_0/counter_RNI2QLK[16]  (.A(
        \led_blink_0/counter[18]_net_1 ), .B(
        \led_blink_0/counter[16]_net_1 ), .Y(\led_blink_0/counter10_8 )
        );
    NOR2A \led_blink_0/counter_RNO_1[1]  (.A(
        \led_blink_0/counter[1]_net_1 ), .B(SW0_c), .Y(
        \led_blink_0/counter_4_0 ));
    NOR2B \led_blink_0/counter_RNI6FVF[3]  (.A(
        \led_blink_0/counter[10]_net_1 ), .B(
        \led_blink_0/counter[3]_net_1 ), .Y(
        \led_blink_0/counter_m3_e_0 ));
    NOR2B \led_blink_0/counter_RNI9K3U6[8]  (.A(
        \led_blink_0/counter10_17 ), .B(\led_blink_0/counter10_16 ), 
        .Y(\led_blink_0/counter10 ));
    NOR3C \led_blink_0/counter_RNI5LS11[5]  (.A(
        \led_blink_0/counter[4]_net_1 ), .B(\led_blink_0/counter_c3 ), 
        .C(\led_blink_0/counter[5]_net_1 ), .Y(
        \led_blink_0/counter_c5 ));
    XA1 \led_blink_0/counter_RNO[10]  (.A(
        \led_blink_0/counter[10]_net_1 ), .B(\led_blink_0/counter_c9 ), 
        .C(\led_blink_0/counter_n25_0_0 ), .Y(
        \led_blink_0/counter_n10 ));
    NOR2B \led_blink_0/counter_RNITMNK[25]  (.A(
        \led_blink_0/counter[25]_net_1 ), .B(
        \led_blink_0/counter[22]_net_1 ), .Y(\led_blink_0/counter10_0 )
        );
    NOR3C \led_blink_0/counter_RNISP5D2[11]  (.A(
        \led_blink_0/counter10_20_2 ), .B(
        \led_blink_0/counter_m3_0_a2_4 ), .C(
        \led_blink_0/counter[11]_net_1 ), .Y(\led_blink_0/counter_c11 )
        );
    XA1 \led_blink_0/counter_RNO[25]  (.A(
        \led_blink_0/counter[25]_net_1 ), .B(
        \led_blink_0/counter_51_0 ), .C(\led_blink_0/counter_n25_0_0 ), 
        .Y(\led_blink_0/counter_n25 ));
    NOR2B \led_blink_0/counter_RNO[11]  (.A(
        \led_blink_0/counter_n25_0 ), .B(\led_blink_0/counter_n11_tz ), 
        .Y(\led_blink_0/counter_n11 ));
    DFN1 \led_blink_0/counter[12]  (.D(\led_blink_0/counter_n12 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[12]_net_1 ));
    NOR2B \led_blink_0/counter_RNO_0[14]  (.A(
        \led_blink_0/counter_c12 ), .B(\led_blink_0/counter[13]_net_1 )
        , .Y(\led_blink_0/counter_c13 ));
    XA1 \led_blink_0/counter_RNO[6]  (.A(
        \led_blink_0/counter[6]_net_1 ), .B(\led_blink_0/counter_c5 ), 
        .C(\led_blink_0/counter_n25_0 ), .Y(\led_blink_0/counter_n6 ));
    NOR2B \led_blink_0/counter_RNIOLH71[1]  (.A(
        \led_blink_0/counter10_20_2 ), .B(\led_blink_0/counter_c2 ), 
        .Y(\led_blink_0/counter_m6_0_a2_3 ));
    NOR3C \led_blink_0/counter_RNI0KNK3[8]  (.A(
        \led_blink_0/counter10_13 ), .B(\led_blink_0/counter10_12 ), 
        .C(\led_blink_0/counter_c3 ), .Y(\led_blink_0/counter10_17 ));
    NOR2 \led_blink_0/counter_RNINAA87[8]  (.A(SW0_c), .B(
        \led_blink_0/counter10 ), .Y(\led_blink_0/counter_n25_0_0 ));
    NOR2B \led_blink_0/counter_RNO[7]  (.A(\led_blink_0/counter_n25_0 )
        , .B(\led_blink_0/counter_n7_tz ), .Y(\led_blink_0/counter_n7 )
        );
    NOR2B \led_blink_0/counter_RNO_0[10]  (.A(\led_blink_0/counter_c8 )
        , .B(\led_blink_0/counter[9]_net_1 ), .Y(
        \led_blink_0/counter_c9 ));
    DFN1 \led_blink_0/counter[10]  (.D(\led_blink_0/counter_n10 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[10]_net_1 ));
    DFN1 \led_blink_0/D1  (.D(\led_blink_0/led_state_net_1 ), .CLK(
        clock_c), .Q(led_c));
    AX1C \led_blink_0/counter_RNO_0[20]  (.A(\led_blink_0/counter_c17 )
        , .B(\led_blink_0/counter_c19_0 ), .C(
        \led_blink_0/counter[20]_net_1 ), .Y(
        \led_blink_0/counter_n20_tz ));
    DFN1 \led_blink_0/counter[18]  (.D(\led_blink_0/counter_n18 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[18]_net_1 ));
    NOR2B \led_blink_0/counter_RNI5TLK[19]  (.A(
        \led_blink_0/counter[19]_net_1 ), .B(
        \led_blink_0/counter[18]_net_1 ), .Y(
        \led_blink_0/counter_c19_0 ));
    DFN1 \led_blink_0/counter[8]  (.D(\led_blink_0/counter_n8 ), .CLK(
        clock_c), .Q(\led_blink_0/counter[8]_net_1 ));
    CLKIO \clock_pad/U0/U1  (.A(\clock_pad/U0/NET1 ), .Y(clock_c));
    XA1 \led_blink_0/counter_RNO[15]  (.A(
        \led_blink_0/counter[15]_net_1 ), .B(\led_blink_0/counter_c14 )
        , .C(\led_blink_0/counter_n25_0_0 ), .Y(
        \led_blink_0/counter_n15 ));
    IOPAD_IN \clock_pad/U0/U0  (.PAD(clock), .Y(\clock_pad/U0/NET1 ));
    DFN1 \led_blink_0/counter[25]  (.D(\led_blink_0/counter_n25 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[25]_net_1 ));
    DFN1 \led_blink_0/counter[13]  (.D(\led_blink_0/counter_n13 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[13]_net_1 ));
    NOR3C \led_blink_0/counter_RNING2D4[8]  (.A(
        \led_blink_0/counter_N_7_mux ), .B(
        \led_blink_0/counter_m6_0_a2_2 ), .C(
        \led_blink_0/counter_m6_0_a2_5_5 ), .Y(
        \led_blink_0/counter_m6_0_a2_5_7 ));
    DFN1 \led_blink_0/counter[5]  (.D(\led_blink_0/counter_n5 ), .CLK(
        clock_c), .Q(\led_blink_0/counter[5]_net_1 ));
    NOR2A \led_blink_0/counter_RNIULLK[13]  (.A(
        \led_blink_0/counter[17]_net_1 ), .B(
        \led_blink_0/counter[13]_net_1 ), .Y(\led_blink_0/counter10_3 )
        );
    NOR3C \led_blink_0/counter_RNIAVIM[3]  (.A(
        \led_blink_0/counter[2]_net_1 ), .B(
        \led_blink_0/counter[3]_net_1 ), .C(\led_blink_0/counter_c1 ), 
        .Y(\led_blink_0/counter_c3 ));
    NOR3C \led_blink_0/counter_RNIO8C91[14]  (.A(
        \led_blink_0/counter[21]_net_1 ), .B(
        \led_blink_0/counter[14]_net_1 ), .C(\led_blink_0/counter10_3 )
        , .Y(\led_blink_0/counter10_10 ));
    NOR2A \led_blink_0/counter_RNO_0[1]  (.A(
        \led_blink_0/counter[0]_net_1 ), .B(SW0_c), .Y(
        \led_blink_0/counter_2_0 ));
    AX1C \led_blink_0/counter_RNO_0[5]  (.A(
        \led_blink_0/counter[4]_net_1 ), .B(\led_blink_0/counter_c3 ), 
        .C(\led_blink_0/counter[5]_net_1 ), .Y(
        \led_blink_0/counter_n5_tz ));
    NOR2B \led_blink_0/counter_RNIOHGN2[12]  (.A(
        \led_blink_0/counter_c11 ), .B(\led_blink_0/counter[12]_net_1 )
        , .Y(\led_blink_0/counter_c12 ));
    NOR2B \led_blink_0/counter_RNINELK[11]  (.A(
        \led_blink_0/counter[11]_net_1 ), .B(
        \led_blink_0/counter[12]_net_1 ), .Y(\led_blink_0/counter10_6 )
        );
    NOR3C \led_blink_0/counter_RNI1M1V[21]  (.A(
        \led_blink_0/counter[19]_net_1 ), .B(
        \led_blink_0/counter[21]_net_1 ), .C(
        \led_blink_0/counter[18]_net_1 ), .Y(
        \led_blink_0/counter_m6_0_a2_5_3 ));
    XA1 \led_blink_0/counter_RNO[2]  (.A(
        \led_blink_0/counter[2]_net_1 ), .B(\led_blink_0/counter_c1 ), 
        .C(\led_blink_0/counter_n25_0 ), .Y(\led_blink_0/counter_n2 ));
    NOR3A \led_blink_0/counter_RNIN7C91[15]  (.A(
        \led_blink_0/counter10_5 ), .B(\led_blink_0/counter[19]_net_1 )
        , .C(\led_blink_0/counter[15]_net_1 ), .Y(
        \led_blink_0/counter10_11 ));
    DFN1 \led_blink_0/counter[9]  (.D(\led_blink_0/counter_n9 ), .CLK(
        clock_c), .Q(\led_blink_0/counter[9]_net_1 ));
    NOR2 \led_blink_0/counter_RNILDMK[10]  (.A(
        \led_blink_0/counter[20]_net_1 ), .B(
        \led_blink_0/counter[10]_net_1 ), .Y(\led_blink_0/counter10_5 )
        );
    NOR3C \led_blink_0/counter_RNO_0[17]  (.A(
        \led_blink_0/counter_m6_0_a2_3 ), .B(
        \led_blink_0/counter_c15_0 ), .C(
        \led_blink_0/counter[16]_net_1 ), .Y(\led_blink_0/counter_c16 )
        );
    IOPAD_TRI \led_pad/U0/U0  (.D(\led_pad/U0/NET1 ), .E(
        \led_pad/U0/NET2 ), .PAD(led));
    AX1C \led_blink_0/counter_RNO_0[8]  (.A(\led_blink_0/counter_c3 ), 
        .B(\led_blink_0/counter10_20_2 ), .C(
        \led_blink_0/counter[8]_net_1 ), .Y(
        \led_blink_0/counter_n8_tz ));
    XA1 \led_blink_0/counter_RNO[19]  (.A(
        \led_blink_0/counter[19]_net_1 ), .B(\led_blink_0/counter_c18 )
        , .C(\led_blink_0/counter_n25_0_0 ), .Y(
        \led_blink_0/counter_n19 ));
    NOR2B \led_blink_0/counter_RNO[16]  (.A(
        \led_blink_0/counter_n25_0 ), .B(\led_blink_0/counter_n16_tz ), 
        .Y(\led_blink_0/counter_n16 ));
    DFN1 \led_blink_0/counter[22]  (.D(\led_blink_0/counter_n22 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[22]_net_1 ));
    NOR2B \led_blink_0/counter_RNIC00V5[22]  (.A(
        \led_blink_0/counter_c21 ), .B(\led_blink_0/counter[22]_net_1 )
        , .Y(\led_blink_0/counter_c22 ));
    NOR2B \led_blink_0/counter_RNO_0[19]  (.A(
        \led_blink_0/counter_c17 ), .B(\led_blink_0/counter[18]_net_1 )
        , .Y(\led_blink_0/counter_c18 ));
    NOR2B \led_blink_0/counter_RNO[5]  (.A(\led_blink_0/counter_n25_0 )
        , .B(\led_blink_0/counter_n5_tz ), .Y(\led_blink_0/counter_n5 )
        );
    NOR2B \led_blink_0/counter_RNIARB96[23]  (.A(
        \led_blink_0/counter_c22 ), .B(\led_blink_0/counter[23]_net_1 )
        , .Y(\led_blink_0/counter_c23 ));
    XA1B \led_blink_0/counter_RNO[1]  (.A(\led_blink_0/counter_2_0 ), 
        .B(\led_blink_0/counter_4_0 ), .C(\led_blink_0/counter10 ), .Y(
        \led_blink_0/counter_n1 ));
    XA1 \led_blink_0/counter_RNO[24]  (.A(
        \led_blink_0/counter[24]_net_1 ), .B(\led_blink_0/counter_c23 )
        , .C(\led_blink_0/counter_n25_0_0 ), .Y(
        \led_blink_0/counter_n24 ));
    NOR2 \led_blink_0/counter_RNITMNK[23]  (.A(
        \led_blink_0/counter[24]_net_1 ), .B(
        \led_blink_0/counter[23]_net_1 ), .Y(\led_blink_0/counter10_1 )
        );
    DFN1 \led_blink_0/counter[14]  (.D(\led_blink_0/counter_n14 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[14]_net_1 ));
    XA1 \led_blink_0/counter_RNO[4]  (.A(
        \led_blink_0/counter[4]_net_1 ), .B(\led_blink_0/counter_c3 ), 
        .C(\led_blink_0/counter_n25_0 ), .Y(\led_blink_0/counter_n4 ));
    DFN1 \led_blink_0/counter[2]  (.D(\led_blink_0/counter_n2 ), .CLK(
        clock_c), .Q(\led_blink_0/counter[2]_net_1 ));
    IOIN_IB \SW0_pad/U0/U1  (.YIN(\SW0_pad/U0/NET1 ), .Y(SW0_c));
    IOPAD_IN \SW0_pad/U0/U0  (.PAD(SW0), .Y(\SW0_pad/U0/NET1 ));
    XA1 \led_blink_0/counter_RNO[23]  (.A(
        \led_blink_0/counter[23]_net_1 ), .B(\led_blink_0/counter_c22 )
        , .C(\led_blink_0/counter_n25_0_0 ), .Y(
        \led_blink_0/counter_n23 ));
    XA1 \led_blink_0/counter_RNO[22]  (.A(
        \led_blink_0/counter[22]_net_1 ), .B(\led_blink_0/counter_c21 )
        , .C(\led_blink_0/counter_n25_0_0 ), .Y(
        \led_blink_0/counter_n22 ));
    DFN1 \led_blink_0/counter[3]  (.D(\led_blink_0/counter_n3 ), .CLK(
        clock_c), .Q(\led_blink_0/counter[3]_net_1 ));
    NOR3C \led_blink_0/counter_RNIS1E82[15]  (.A(
        \led_blink_0/counter_m6_0_a2_5_2 ), .B(
        \led_blink_0/counter_m6_0_a2_5_1 ), .C(
        \led_blink_0/counter_m6_0_a2_5_3 ), .Y(
        \led_blink_0/counter_m6_0_a2_5_5 ));
    DFN1 \led_blink_0/counter[11]  (.D(\led_blink_0/counter_n11 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[11]_net_1 ));
    XA1 \led_blink_0/counter_RNO[17]  (.A(
        \led_blink_0/counter[17]_net_1 ), .B(\led_blink_0/counter_c16 )
        , .C(\led_blink_0/counter_n25_0_0 ), .Y(
        \led_blink_0/counter_n17 ));
    DFN1 \led_blink_0/counter[20]  (.D(\led_blink_0/counter_n20 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[20]_net_1 ));
    XA1 \led_blink_0/counter_RNO[18]  (.A(
        \led_blink_0/counter[18]_net_1 ), .B(\led_blink_0/counter_c17 )
        , .C(\led_blink_0/counter_n25_0_0 ), .Y(
        \led_blink_0/counter_n18 ));
    NOR3C \led_blink_0/counter_RNII1B91[14]  (.A(
        \led_blink_0/counter[13]_net_1 ), .B(
        \led_blink_0/counter[14]_net_1 ), .C(\led_blink_0/counter10_6 )
        , .Y(\led_blink_0/counter_m6_0_a2_2 ));
    IOTRI_OB_EB \led_pad/U0/U1  (.D(led_c), .E(VCC), .DOUT(
        \led_pad/U0/NET1 ), .EOUT(\led_pad/U0/NET2 ));
    NOR3C \led_blink_0/counter_RNIQ9VE2[15]  (.A(
        \led_blink_0/counter_N_7_mux ), .B(
        \led_blink_0/counter_m6_0_a2_2 ), .C(
        \led_blink_0/counter[15]_net_1 ), .Y(
        \led_blink_0/counter_c15_0 ));
    DFN1 \led_blink_0/counter[23]  (.D(\led_blink_0/counter_n23 ), 
        .CLK(clock_c), .Q(\led_blink_0/counter[23]_net_1 ));
    NOR3C \led_blink_0/counter_RNI7J7C1[2]  (.A(
        \led_blink_0/counter_c1 ), .B(\led_blink_0/counter_m3_0_a2_1 ), 
        .C(\led_blink_0/counter_m3_0_a2_2 ), .Y(
        \led_blink_0/counter_m3_0_a2_4 ));
    XA1 \led_blink_0/counter_RNO[14]  (.A(
        \led_blink_0/counter[14]_net_1 ), .B(\led_blink_0/counter_c13 )
        , .C(\led_blink_0/counter_n25_0_0 ), .Y(
        \led_blink_0/counter_n14 ));
    DFN1 \led_blink_0/counter[1]  (.D(\led_blink_0/counter_n1 ), .CLK(
        clock_c), .Q(\led_blink_0/counter[1]_net_1 ));
    GND GND_power_inst1 (.Y(GND_power_net1));
    VCC VCC_power_inst1 (.Y(VCC_power_net1));
    
endmodule

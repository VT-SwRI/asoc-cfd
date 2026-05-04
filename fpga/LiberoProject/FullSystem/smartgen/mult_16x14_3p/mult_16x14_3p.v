`timescale 1 ns/100 ps
// Version: v11.9 SP6 11.9.6.7


module mult_16x14_3p(
       DataA,
       DataB,
       Mult,
       Clock
    );
input  [15:0] DataA;
input  [13:0] DataB;
output [29:0] Mult;
input  Clock;

    wire \S[0] , \S[1] , \S[2] , \S[3] , \S[4] , \S[5] , \S[6] , 
        \E[0] , \E[1] , \E[2] , \E[3] , \E[4] , \E[5] , \E[6] , EBAR, 
        \PP0[0] , \PP0[1] , \PP0[2] , \PP0[3] , \PP0[4] , \PP0[5] , 
        \PP0[6] , \PP0[7] , \PP0[8] , \PP0[9] , \PP0[10] , \PP0[11] , 
        \PP0[12] , \PP0[13] , \PP0[14] , \PP0[15] , \PP0[16] , 
        \PP1[0] , \PP1[1] , \PP1[2] , \PP1[3] , \PP1[4] , \PP1[5] , 
        \PP1[6] , \PP1[7] , \PP1[8] , \PP1[9] , \PP1[10] , \PP1[11] , 
        \PP1[12] , \PP1[13] , \PP1[14] , \PP1[15] , \PP1[16] , 
        \PP2[0] , \PP2[1] , \PP2[2] , \PP2[3] , \PP2[4] , \PP2[5] , 
        \PP2[6] , \PP2[7] , \PP2[8] , \PP2[9] , \PP2[10] , \PP2[11] , 
        \PP2[12] , \PP2[13] , \PP2[14] , \PP2[15] , \PP2[16] , 
        \PP3[0] , \PP3[1] , \PP3[2] , \PP3[3] , \PP3[4] , \PP3[5] , 
        \PP3[6] , \PP3[7] , \PP3[8] , \PP3[9] , \PP3[10] , \PP3[11] , 
        \PP3[12] , \PP3[13] , \PP3[14] , \PP3[15] , \PP3[16] , 
        \PP4[0] , \PP4[1] , \PP4[2] , \PP4[3] , \PP4[4] , \PP4[5] , 
        \PP4[6] , \PP4[7] , \PP4[8] , \PP4[9] , \PP4[10] , \PP4[11] , 
        \PP4[12] , \PP4[13] , \PP4[14] , \PP4[15] , \PP4[16] , 
        \PP5[0] , \PP5[1] , \PP5[2] , \PP5[3] , \PP5[4] , \PP5[5] , 
        \PP5[6] , \PP5[7] , \PP5[8] , \PP5[9] , \PP5[10] , \PP5[11] , 
        \PP5[12] , \PP5[13] , \PP5[14] , \PP5[15] , \PP5[16] , 
        \PP6[0] , \PP6[1] , \PP6[2] , \PP6[3] , \PP6[4] , \PP6[5] , 
        \PP6[6] , \PP6[7] , \PP6[8] , \PP6[9] , \PP6[10] , \PP6[11] , 
        \PP6[12] , \PP6[13] , \PP6[14] , \PP6[15] , \PP6[16] , 
        \SumA[0] , \SumA[1] , \SumA[2] , \SumA[3] , \SumA[4] , 
        \SumA[5] , \SumA[6] , \SumA[7] , \SumA[8] , \SumA[9] , 
        \SumA[10] , \SumA[11] , \SumA[12] , \SumA[13] , \SumA[14] , 
        \SumA[15] , \SumA[16] , \SumA[17] , \SumA[18] , \SumA[19] , 
        \SumA[20] , \SumA[21] , \SumA[22] , \SumA[23] , \SumA[24] , 
        \SumA[25] , \SumA[26] , \SumA[27] , \SumA[28] , \SumB[0] , 
        \SumB[1] , \SumB[2] , \SumB[3] , \SumB[4] , \SumB[5] , 
        \SumB[6] , \SumB[7] , \SumB[8] , \SumB[9] , \SumB[10] , 
        \SumB[11] , \SumB[12] , \SumB[13] , \SumB[14] , \SumB[15] , 
        \SumB[16] , \SumB[17] , \SumB[18] , \SumB[19] , \SumB[20] , 
        \SumB[21] , \SumB[22] , \SumB[23] , \SumB[24] , \SumB[25] , 
        \SumB[26] , \SumB[27] , \SumB[28] , DFN1_187_Q, DFN1_181_Q, 
        DFN1_36_Q, DFN1_173_Q, DFN1_222_Q, DFN1_198_Q, DFN1_27_Q, 
        DFN1_43_Q, DFN1_152_Q, DFN1_142_Q, DFN1_158_Q, DFN1_101_Q, 
        DFN1_219_Q, DFN1_216_Q, DFN1_70_Q, DFN1_114_Q, DFN1_34_Q, 
        DFN1_192_Q, DFN1_52_Q, DFN1_206_Q, DFN1_65_Q, DFN1_14_Q, 
        DFN1_123_Q, DFN1_122_Q, DFN1_213_Q, DFN1_30_Q, DFN1_175_Q, 
        DFN1_95_Q, DFN1_197_Q, DFN1_109_Q, DFN1_85_Q, DFN1_41_Q, 
        DFN1_148_Q, DFN1_147_Q, DFN1_3_Q, DFN1_50_Q, DFN1_199_Q, 
        DFN1_121_Q, DFN1_225_Q, DFN1_136_Q, DFN1_75_Q, DFN1_26_Q, 
        DFN1_131_Q, DFN1_130_Q, DFN1_227_Q, DFN1_39_Q, DFN1_183_Q, 
        DFN1_104_Q, DFN1_209_Q, DFN1_119_Q, DFN1_16_Q, DFN1_202_Q, 
        DFN1_79_Q, DFN1_77_Q, DFN1_164_Q, DFN1_224_Q, DFN1_126_Q, 
        DFN1_49_Q, DFN1_153_Q, DFN1_66_Q, DFN1_195_Q, DFN1_149_Q, 
        DFN1_19_Q, DFN1_17_Q, DFN1_105_Q, DFN1_163_Q, DFN1_73_Q, 
        DFN1_235_Q, DFN1_89_Q, DFN1_11_Q, DFN1_159_Q, DFN1_102_Q, 
        DFN1_220_Q, DFN1_217_Q, DFN1_71_Q, DFN1_115_Q, DFN1_35_Q, 
        DFN1_193_Q, DFN1_53_Q, DFN1_207_Q, DFN1_90_Q, DFN1_45_Q, 
        DFN1_156_Q, DFN1_154_Q, DFN1_8_Q, DFN1_61_Q, DFN1_208_Q, 
        DFN1_127_Q, DFN1_233_Q, DFN1_143_Q, DFN1_157_Q, DFN1_100_Q, 
        DFN1_218_Q, DFN1_215_Q, DFN1_69_Q, DFN1_113_Q, DFN1_33_Q, 
        DFN1_191_Q, DFN1_51_Q, DFN1_205_Q, DFN1_106_Q, DFN1_188_Q, 
        DFN1_24_Q, DFN1_6_Q, DFN1_133_Q, DFN1_169_Q, DFN1_94_Q, 
        DFN1_128_Q, DFN1_84_Q, DFN1_82_Q, DFN1_29_Q, DFN1_107_Q, 
        DFN1_178_Q, DFN1_162_Q, DFN1_54_Q, DFN1_87_Q, DFN1_18_Q, 
        DFN1_48_Q, DFN1_7_Q, DFN1_1_Q, DFN1_236_Q, DFN1_80_Q, 
        DFN1_145_Q, DFN1_124_Q, DFN1_20_Q, DFN1_55_Q, DFN1_226_Q, 
        DFN1_15_Q, DFN1_210_Q, DFN1_200_Q, DFN1_12_Q, DFN1_88_Q, 
        DFN1_161_Q, DFN1_140_Q, XOR2_21_Y, AND2_209_Y, XOR3_30_Y, 
        MAJ3_22_Y, XOR3_16_Y, MAJ3_63_Y, XOR2_43_Y, AND2_213_Y, 
        XOR3_9_Y, MAJ3_60_Y, XOR2_81_Y, AND2_72_Y, XOR3_47_Y, 
        MAJ3_53_Y, XOR2_86_Y, AND2_32_Y, XOR3_50_Y, MAJ3_74_Y, 
        XOR2_58_Y, AND2_187_Y, XOR3_37_Y, MAJ3_67_Y, XOR2_87_Y, 
        AND2_22_Y, XOR3_25_Y, MAJ3_62_Y, XOR2_2_Y, AND2_96_Y, 
        XOR3_48_Y, MAJ3_43_Y, XOR2_20_Y, AND2_193_Y, XOR3_61_Y, 
        MAJ3_50_Y, DFN1_37_Q, DFN1_72_Q, DFN1_0_Q, DFN1_31_Q, 
        DFN1_229_Q, DFN1_221_Q, DFN1_144_Q, DFN1_231_Q, DFN1_60_Q, 
        DFN1_42_Q, DFN1_170_Q, DFN1_203_Q, DFN1_134_Q, DFN1_165_Q, 
        DFN1_116_Q, DFN1_110_Q, DFN1_103_Q, DFN1_186_Q, DFN1_22_Q, 
        DFN1_168_Q, DFN1_118_Q, DFN1_5_Q, DFN1_132_Q, DFN1_167_Q, 
        DFN1_112_Q, DFN1_76_Q, DFN1_91_Q, DFN1_125_Q, DFN1_9_Q, 
        DFN1_196_Q, DFN1_4_Q, DFN1_184_Q, DFN1_83_Q, DFN1_67_Q, 
        DFN1_13_Q, DFN1_182_Q, DFN1_129_Q, DFN1_28_Q, DFN1_214_Q, 
        DFN1_189_Q, DFN1_137_Q, DFN1_150_Q, DFN1_93_Q, DFN1_139_Q, 
        DFN1_86_Q, DFN1_59_Q, DFN1_10_Q, DFN1_155_Q, DFN1_96_Q, 
        DFN1_40_Q, DFN1_230_Q, DFN1_212_Q, DFN1_177_Q, DFN1_223_Q, 
        DFN1_185_Q, DFN1_92_Q, DFN1_64_Q, DFN1_180_Q, DFN1_151_Q, 
        DFN1_99_Q, DFN1_74_Q, DFN1_63_Q, DFN1_32_Q, DFN1_56_Q, 
        DFN1_25_Q, DFN1_211_Q, DFN1_176_Q, DFN1_68_Q, DFN1_38_Q, 
        DFN1_190_Q, DFN1_160_Q, DFN1_98_Q, DFN1_47_Q, DFN1_108_Q, 
        DFN1_58_Q, DFN1_234_Q, DFN1_172_Q, DFN1_78_Q, DFN1_21_Q, 
        DFN1_2_Q, DFN1_179_Q, DFN1_194_Q, DFN1_138_Q, DFN1_23_Q, 
        DFN1_201_Q, DFN1_97_Q, DFN1_46_Q, DFN1_81_Q, DFN1_174_Q, 
        DFN1_117_Q, DFN1_146_Q, DFN1_232_Q, DFN1_62_Q, DFN1_44_Q, 
        DFN1_171_Q, DFN1_204_Q, DFN1_135_Q, DFN1_166_Q, DFN1_120_Q, 
        DFN1_111_Q, DFN1_141_Q, DFN1_228_Q, DFN1_57_Q, XOR2_14_Y, 
        AND2_163_Y, XOR3_38_Y, MAJ3_65_Y, XOR3_49_Y, MAJ3_76_Y, 
        XOR3_26_Y, MAJ3_57_Y, XOR3_24_Y, MAJ3_11_Y, XOR3_52_Y, 
        MAJ3_41_Y, XOR3_39_Y, MAJ3_21_Y, XOR3_62_Y, MAJ3_48_Y, 
        XOR3_2_Y, MAJ3_70_Y, XOR3_74_Y, MAJ3_6_Y, XOR3_57_Y, MAJ3_15_Y, 
        XOR3_79_Y, MAJ3_40_Y, XOR3_7_Y, MAJ3_59_Y, XOR3_64_Y, 
        MAJ3_37_Y, XOR3_63_Y, MAJ3_78_Y, XOR3_8_Y, MAJ3_29_Y, 
        XOR3_80_Y, MAJ3_3_Y, XOR3_23_Y, MAJ3_33_Y, XOR3_41_Y, 
        MAJ3_49_Y, XOR3_31_Y, MAJ3_75_Y, XOR3_17_Y, MAJ3_0_Y, XOR2_7_Y, 
        AND2_197_Y, XOR2_52_Y, AND2_190_Y, XOR3_78_Y, MAJ3_35_Y, 
        XOR3_0_Y, MAJ3_7_Y, XOR3_71_Y, MAJ3_9_Y, XOR3_53_Y, MAJ3_61_Y, 
        XOR3_43_Y, MAJ3_13_Y, XOR3_20_Y, MAJ3_17_Y, XOR3_73_Y, 
        MAJ3_71_Y, XOR3_59_Y, MAJ3_23_Y, XOR2_62_Y, AND2_33_Y, 
        XOR3_35_Y, MAJ3_10_Y, XOR3_11_Y, MAJ3_31_Y, XOR3_69_Y, 
        MAJ3_16_Y, XOR3_6_Y, MAJ3_66_Y, XOR3_77_Y, MAJ3_77_Y, 
        XOR3_10_Y, MAJ3_30_Y, XOR3_67_Y, MAJ3_14_Y, XOR3_29_Y, 
        MAJ3_38_Y, XOR3_15_Y, MAJ3_1_Y, XOR3_76_Y, MAJ3_12_Y, XOR2_1_Y, 
        AND2_62_Y, XOR3_60_Y, MAJ3_68_Y, XOR3_72_Y, MAJ3_45_Y, 
        XOR3_32_Y, MAJ3_80_Y, XOR3_66_Y, MAJ3_46_Y, XOR3_40_Y, 
        MAJ3_42_Y, XOR3_33_Y, MAJ3_34_Y, XOR3_51_Y, MAJ3_5_Y, 
        XOR3_13_Y, MAJ3_19_Y, XOR3_19_Y, MAJ3_58_Y, XOR3_18_Y, 
        MAJ3_54_Y, XOR3_68_Y, MAJ3_28_Y, XOR3_5_Y, MAJ3_56_Y, 
        XOR3_65_Y, MAJ3_44_Y, XOR3_58_Y, MAJ3_69_Y, XOR2_38_Y, 
        AND2_138_Y, XOR3_22_Y, MAJ3_27_Y, XOR3_21_Y, MAJ3_51_Y, 
        XOR3_3_Y, MAJ3_55_Y, XOR3_56_Y, MAJ3_47_Y, XOR3_36_Y, 
        MAJ3_32_Y, XOR3_42_Y, MAJ3_73_Y, XOR3_14_Y, MAJ3_4_Y, 
        XOR3_55_Y, MAJ3_18_Y, XOR3_28_Y, MAJ3_72_Y, XOR3_4_Y, 
        MAJ3_52_Y, XOR3_46_Y, MAJ3_25_Y, XOR2_50_Y, AND2_139_Y, 
        XOR3_75_Y, MAJ3_36_Y, XOR3_54_Y, MAJ3_26_Y, XOR3_27_Y, 
        MAJ3_8_Y, XOR3_12_Y, MAJ3_2_Y, XOR3_70_Y, MAJ3_79_Y, XOR3_44_Y, 
        MAJ3_64_Y, XOR3_34_Y, MAJ3_39_Y, XOR2_17_Y, AND2_7_Y, 
        XOR3_45_Y, MAJ3_24_Y, XOR3_1_Y, MAJ3_20_Y, BUFF_31_Y, 
        BUFF_11_Y, BUFF_23_Y, BUFF_37_Y, BUFF_29_Y, BUFF_27_Y, 
        BUFF_30_Y, BUFF_6_Y, BUFF_43_Y, BUFF_3_Y, BUFF_50_Y, BUFF_38_Y, 
        BUFF_10_Y, BUFF_16_Y, BUFF_8_Y, BUFF_49_Y, BUFF_17_Y, 
        BUFF_22_Y, BUFF_13_Y, BUFF_42_Y, BUFF_48_Y, BUFF_12_Y, 
        BUFF_47_Y, BUFF_18_Y, BUFF_26_Y, BUFF_2_Y, BUFF_19_Y, 
        BUFF_34_Y, BUFF_1_Y, BUFF_33_Y, BUFF_51_Y, BUFF_45_Y, 
        BUFF_52_Y, BUFF_46_Y, BUFF_24_Y, XOR2_78_Y, XOR2_63_Y, 
        AO1_52_Y, XOR2_29_Y, AO16_4_Y, MX2_74_Y, AND2_147_Y, MX2_54_Y, 
        AND2_123_Y, MX2_89_Y, AND2_122_Y, MX2_35_Y, AND2_231_Y, 
        MX2_14_Y, XOR2_28_Y, AO16_5_Y, AND2_120_Y, MX2_106_Y, 
        AND2_223_Y, MX2_61_Y, AND2_135_Y, MX2_85_Y, AND2_145_Y, 
        MX2_44_Y, AND2_124_Y, MX2_33_Y, AND2_70_Y, MX2_15_Y, 
        XOR2_101_Y, AO16_7_Y, AND2_100_Y, MX2_21_Y, AND2_210_Y, 
        MX2_104_Y, AND2_133_Y, AND2_194_Y, MX2_99_Y, AND2_108_Y, 
        MX2_1_Y, AND2_198_Y, MX2_98_Y, OR3_3_Y, AND3_5_Y, BUFF_20_Y, 
        BUFF_9_Y, BUFF_41_Y, XOR2_3_Y, XOR2_32_Y, AO1_69_Y, XOR2_39_Y, 
        AO16_3_Y, MX2_67_Y, AND2_101_Y, MX2_11_Y, AND2_15_Y, MX2_48_Y, 
        AND2_115_Y, MX2_23_Y, AND2_40_Y, MX2_5_Y, XOR2_9_Y, AO16_10_Y, 
        AND2_81_Y, MX2_41_Y, AND2_20_Y, MX2_95_Y, AND2_106_Y, MX2_45_Y, 
        AND2_56_Y, MX2_38_Y, AND2_166_Y, MX2_92_Y, AND2_150_Y, 
        MX2_34_Y, XOR2_33_Y, AO16_8_Y, AND2_57_Y, MX2_20_Y, AND2_47_Y, 
        MX2_79_Y, AND2_90_Y, AND2_74_Y, MX2_65_Y, AND2_156_Y, MX2_60_Y, 
        AND2_207_Y, MX2_24_Y, OR3_0_Y, AND3_3_Y, BUFF_21_Y, BUFF_14_Y, 
        BUFF_44_Y, XOR2_91_Y, XOR2_45_Y, AO1_65_Y, XOR2_100_Y, 
        AO16_12_Y, MX2_10_Y, AND2_110_Y, MX2_12_Y, AND2_18_Y, MX2_3_Y, 
        AND2_212_Y, MX2_6_Y, AND2_134_Y, MX2_36_Y, XOR2_10_Y, AO16_6_Y, 
        AND2_128_Y, MX2_71_Y, AND2_202_Y, MX2_18_Y, AND2_201_Y, 
        MX2_51_Y, AND2_203_Y, MX2_50_Y, AND2_63_Y, MX2_56_Y, 
        AND2_189_Y, MX2_76_Y, XOR2_82_Y, AO16_17_Y, AND2_230_Y, 
        MX2_55_Y, AND2_216_Y, MX2_43_Y, AND2_71_Y, AND2_173_Y, 
        MX2_108_Y, AND2_42_Y, MX2_31_Y, AND2_69_Y, MX2_47_Y, OR3_2_Y, 
        AND3_6_Y, BUFF_28_Y, BUFF_25_Y, BUFF_0_Y, XOR2_55_Y, XOR2_83_Y, 
        AND2A_0_Y, MX2_46_Y, AND2_152_Y, MX2_32_Y, AND2_34_Y, MX2_13_Y, 
        AND2_103_Y, MX2_39_Y, AND2_178_Y, MX2_84_Y, AND2A_2_Y, 
        AND2_146_Y, MX2_63_Y, AND2_161_Y, MX2_8_Y, AND2_126_Y, 
        MX2_17_Y, AND2_77_Y, MX2_68_Y, AND2_88_Y, MX2_87_Y, AND2_180_Y, 
        MX2_69_Y, AND2A_1_Y, AND2_172_Y, MX2_75_Y, AND2_25_Y, MX2_86_Y, 
        AND2_17_Y, AND2_104_Y, MX2_78_Y, AND2_98_Y, MX2_0_Y, AND2_75_Y, 
        MX2_30_Y, OR3_1_Y, AND3_1_Y, BUFF_39_Y, BUFF_35_Y, BUFF_7_Y, 
        XOR2_0_Y, XOR2_67_Y, AO1_4_Y, XOR2_13_Y, AO16_11_Y, MX2_37_Y, 
        AND2_181_Y, MX2_53_Y, AND2_204_Y, MX2_83_Y, AND2_168_Y, 
        MX2_96_Y, AND2_59_Y, MX2_73_Y, XOR2_27_Y, AO16_0_Y, AND2_43_Y, 
        MX2_77_Y, AND2_219_Y, MX2_16_Y, AND2_78_Y, MX2_62_Y, 
        AND2_182_Y, MX2_110_Y, AND2_11_Y, MX2_93_Y, AND2_186_Y, 
        MX2_2_Y, XOR2_35_Y, AO16_1_Y, AND2_109_Y, MX2_91_Y, AND2_31_Y, 
        MX2_9_Y, AND2_99_Y, AND2_95_Y, MX2_49_Y, AND2_141_Y, MX2_109_Y, 
        AND2_228_Y, MX2_81_Y, OR3_6_Y, AND3_0_Y, BUFF_15_Y, BUFF_5_Y, 
        BUFF_40_Y, XOR2_48_Y, XOR2_54_Y, AO1_13_Y, XOR2_46_Y, 
        AO16_16_Y, MX2_25_Y, AND2_112_Y, MX2_103_Y, AND2_8_Y, MX2_4_Y, 
        AND2_127_Y, MX2_70_Y, AND2_117_Y, MX2_90_Y, XOR2_99_Y, 
        AO16_9_Y, AND2_79_Y, MX2_57_Y, AND2_164_Y, MX2_97_Y, 
        AND2_179_Y, MX2_52_Y, AND2_76_Y, MX2_82_Y, AND2_132_Y, 
        MX2_88_Y, AND2_23_Y, MX2_59_Y, XOR2_60_Y, AO16_15_Y, 
        AND2_218_Y, MX2_66_Y, AND2_4_Y, MX2_107_Y, AND2_129_Y, 
        AND2_65_Y, MX2_80_Y, AND2_111_Y, MX2_29_Y, AND2_232_Y, 
        MX2_28_Y, OR3_4_Y, AND3_4_Y, BUFF_36_Y, BUFF_32_Y, BUFF_4_Y, 
        XOR2_34_Y, XOR2_72_Y, AO1_16_Y, XOR2_90_Y, AO16_2_Y, MX2_19_Y, 
        AND2_143_Y, MX2_26_Y, AND2_2_Y, MX2_102_Y, AND2_64_Y, MX2_94_Y, 
        AND2_183_Y, MX2_111_Y, XOR2_75_Y, AO16_13_Y, AND2_0_Y, 
        MX2_105_Y, AND2_27_Y, MX2_100_Y, AND2_155_Y, MX2_42_Y, 
        AND2_97_Y, MX2_7_Y, AND2_130_Y, MX2_72_Y, AND2_196_Y, MX2_22_Y, 
        XOR2_71_Y, AO16_14_Y, AND2_149_Y, MX2_58_Y, AND2_116_Y, 
        MX2_40_Y, AND2_19_Y, AND2_167_Y, MX2_27_Y, AND2_67_Y, 
        MX2_101_Y, AND2_49_Y, MX2_64_Y, OR3_5_Y, AND3_2_Y, AND2_6_Y, 
        AND2_14_Y, AND2_9_Y, AND2_154_Y, AND2_85_Y, AND2_131_Y, 
        AND2_119_Y, AND2_165_Y, AND2_66_Y, AND2_220_Y, AND2_148_Y, 
        AND2_174_Y, AND2_114_Y, AND2_229_Y, AND2_39_Y, AND2_68_Y, 
        AND2_10_Y, AND2_46_Y, AND2_169_Y, AND2_3_Y, AND2_175_Y, 
        AND2_195_Y, AND2_153_Y, AND2_16_Y, AND2_55_Y, AND2_86_Y, 
        AND2_37_Y, AND2_61_Y, XOR2_102_Y, XOR2_65_Y, XOR2_96_Y, 
        XOR2_89_Y, XOR2_84_Y, XOR2_69_Y, XOR2_59_Y, XOR2_47_Y, 
        XOR2_31_Y, XOR2_24_Y, XOR2_41_Y, XOR2_104_Y, XOR2_93_Y, 
        XOR2_42_Y, XOR2_57_Y, XOR2_23_Y, XOR2_76_Y, XOR2_44_Y, 
        XOR2_8_Y, XOR2_51_Y, XOR2_74_Y, XOR2_26_Y, XOR2_16_Y, 
        XOR2_77_Y, XOR2_94_Y, XOR2_53_Y, XOR2_5_Y, XOR2_80_Y, 
        XOR2_37_Y, AND2_30_Y, AO1_62_Y, AND2_82_Y, AO1_68_Y, AND2_29_Y, 
        AO1_12_Y, AND2_206_Y, AO1_78_Y, AND2_50_Y, AO1_54_Y, 
        AND2_121_Y, AO1_0_Y, AND2_151_Y, AO1_18_Y, AND2_177_Y, 
        AO1_75_Y, AND2_158_Y, AO1_6_Y, AND2_217_Y, AO1_29_Y, 
        AND2_118_Y, AO1_8_Y, AND2_226_Y, AO1_59_Y, AND2_162_Y, 
        AO1_31_Y, AND2_84_Y, AND2_188_Y, AND2_28_Y, AO1_21_Y, 
        AND2_45_Y, AO1_47_Y, AND2_60_Y, AO1_81_Y, AND2_52_Y, AO1_73_Y, 
        AND2_94_Y, AO1_33_Y, AND2_24_Y, AO1_10_Y, AND2_224_Y, AO1_61_Y, 
        AND2_160_Y, AO1_36_Y, AND2_83_Y, AO1_60_Y, AND2_184_Y, 
        AO1_49_Y, AND2_26_Y, AO1_26_Y, AND2_44_Y, AO1_51_Y, AND2_58_Y, 
        AO1_3_Y, AND2_51_Y, AO1_77_Y, AND2_93_Y, AO1_19_Y, AND2_21_Y, 
        AND2_176_Y, AND2_92_Y, AND2_41_Y, AND2_113_Y, AO1_32_Y, 
        AND2_215_Y, AO1_14_Y, AND2_225_Y, AO1_35_Y, AND2_13_Y, 
        AO1_67_Y, AND2_1_Y, AO1_63_Y, AND2_53_Y, AO1_25_Y, AND2_211_Y, 
        AO1_5_Y, AND2_73_Y, AO1_53_Y, AND2_12_Y, AO1_27_Y, AND2_191_Y, 
        AO1_50_Y, AND2_35_Y, AO1_38_Y, AND2_105_Y, AO1_17_Y, 
        AND2_125_Y, AND2_157_Y, AND2_142_Y, AND2_199_Y, AND2_102_Y, 
        AND2_170_Y, AND2_87_Y, AND2_36_Y, AND2_107_Y, AO1_41_Y, 
        AND2_208_Y, AO1_20_Y, AND2_221_Y, AO1_46_Y, AND2_5_Y, AO1_79_Y, 
        AND2_227_Y, AO1_71_Y, AND2_48_Y, AO1_23_Y, AND2_205_Y, AO1_1_Y, 
        AND2_89_Y, AO1_48_Y, AND2_38_Y, AND2_214_Y, AND2_54_Y, 
        AND2_140_Y, AND2_159_Y, AND2_185_Y, AND2_171_Y, AND2_222_Y, 
        AND2_136_Y, AND2_192_Y, AND2_200_Y, AND2_137_Y, AND2_80_Y, 
        AO1_2_Y, AND2_144_Y, AND2_91_Y, AO1_55_Y, AO1_57_Y, AO1_43_Y, 
        AO1_80_Y, AO1_44_Y, AO1_22_Y, AO1_42_Y, AO1_39_Y, AO1_76_Y, 
        AO1_66_Y, AO1_28_Y, AO1_7_Y, AO1_58_Y, AO1_30_Y, AO1_56_Y, 
        AO1_24_Y, AO1_45_Y, AO1_34_Y, AO1_15_Y, AO1_37_Y, AO1_72_Y, 
        AO1_64_Y, AO1_70_Y, AO1_40_Y, AO1_11_Y, AO1_74_Y, AO1_9_Y, 
        XOR2_70_Y, XOR2_11_Y, XOR2_88_Y, XOR2_103_Y, XOR2_30_Y, 
        XOR2_49_Y, XOR2_97_Y, XOR2_66_Y, XOR2_85_Y, XOR2_15_Y, 
        XOR2_98_Y, XOR2_40_Y, XOR2_12_Y, XOR2_25_Y, XOR2_64_Y, 
        XOR2_56_Y, XOR2_4_Y, XOR2_73_Y, XOR2_92_Y, XOR2_19_Y, 
        XOR2_61_Y, XOR2_6_Y, XOR2_79_Y, XOR2_95_Y, XOR2_22_Y, 
        XOR2_18_Y, XOR2_68_Y, XOR2_36_Y, VCC, GND;
    wire GND_power_net1;
    wire VCC_power_net1;
    assign GND = GND_power_net1;
    assign VCC = VCC_power_net1;
    
    DFN1 DFN1_160 (.D(MAJ3_10_Y), .CLK(Clock), .Q(DFN1_160_Q));
    BUFF BUFF_8 (.A(DataA[7]), .Y(BUFF_8_Y));
    DFN1 DFN1_40 (.D(XOR3_21_Y), .CLK(Clock), .Q(DFN1_40_Q));
    DFN1 DFN1_146 (.D(DFN1_205_Q), .CLK(Clock), .Q(DFN1_146_Q));
    XOR2 \XOR2_Mult[8]  (.A(XOR2_97_Y), .B(AO1_22_Y), .Y(Mult[8]));
    DFN1 DFN1_24 (.D(\PP6[0] ), .CLK(Clock), .Q(DFN1_24_Q));
    XOR2 \XOR2_Mult[29]  (.A(XOR2_36_Y), .B(AO1_9_Y), .Y(Mult[29]));
    AND2 AND2_12 (.A(AND2_26_Y), .B(AND2_118_Y), .Y(AND2_12_Y));
    AO1 AO1_23 (.A(AND2_93_Y), .B(AO1_38_Y), .C(AO1_77_Y), .Y(AO1_23_Y)
        );
    MAJ3 MAJ3_9 (.A(DFN1_225_Q), .B(DFN1_122_Q), .C(DFN1_152_Q), .Y(
        MAJ3_9_Y));
    AND2 AND2_72 (.A(DFN1_71_Q), .B(DFN1_66_Q), .Y(AND2_72_Y));
    DFN1 DFN1_219 (.D(\PP0[12] ), .CLK(Clock), .Q(DFN1_219_Q));
    AND2 AND2_158 (.A(XOR2_76_Y), .B(XOR2_44_Y), .Y(AND2_158_Y));
    MX2 \MX2_PP1[16]  (.A(MX2_10_Y), .B(AO1_65_Y), .S(AO16_12_Y), .Y(
        \PP1[16] ));
    MAJ3 MAJ3_17 (.A(MAJ3_74_Y), .B(AND2_187_Y), .C(DFN1_218_Q), .Y(
        MAJ3_17_Y));
    AND2 AND2_225 (.A(AND2_45_Y), .B(AND2_52_Y), .Y(AND2_225_Y));
    DFN1 DFN1_149 (.D(\PP3[10] ), .CLK(Clock), .Q(DFN1_149_Q));
    DFN1 DFN1_192 (.D(\PP1[0] ), .CLK(Clock), .Q(DFN1_192_Q));
    MAJ3 MAJ3_62 (.A(DFN1_209_Q), .B(DFN1_147_Q), .C(DFN1_140_Q), .Y(
        MAJ3_62_Y));
    XOR2 XOR2_58 (.A(DFN1_35_Q), .B(DFN1_149_Q), .Y(XOR2_58_Y));
    XOR2 \XOR2_Mult[13]  (.A(XOR2_40_Y), .B(AO1_28_Y), .Y(Mult[13]));
    DFN1 DFN1_190 (.D(XOR3_35_Y), .CLK(Clock), .Q(DFN1_190_Q));
    MAJ3 MAJ3_52 (.A(XOR3_47_Y), .B(XOR2_86_Y), .C(DFN1_169_Q), .Y(
        MAJ3_52_Y));
    XOR2 \XOR2_Mult[2]  (.A(XOR2_70_Y), .B(AND2_91_Y), .Y(Mult[2]));
    DFN1 DFN1_78 (.D(XOR3_65_Y), .CLK(Clock), .Q(DFN1_78_Q));
    XOR3 XOR3_21 (.A(AND2_213_Y), .B(DFN1_143_Q), .C(MAJ3_63_Y), .Y(
        XOR3_21_Y));
    DFN1 DFN1_94 (.D(\PP6[4] ), .CLK(Clock), .Q(DFN1_94_Q));
    AND2 AND2_232 (.A(XOR2_60_Y), .B(BUFF_30_Y), .Y(AND2_232_Y));
    XOR2 \XOR2_PP0[13]  (.A(MX2_32_Y), .B(BUFF_0_Y), .Y(\PP0[13] ));
    XOR2 \XOR2_PP5[4]  (.A(MX2_21_Y), .B(BUFF_52_Y), .Y(\PP5[4] ));
    AND2 AND2_49 (.A(XOR2_71_Y), .B(BUFF_30_Y), .Y(AND2_49_Y));
    AND2 AND2_23 (.A(XOR2_99_Y), .B(BUFF_13_Y), .Y(AND2_23_Y));
    XOR3 XOR3_7 (.A(DFN1_151_Q), .B(DFN1_74_Q), .C(DFN1_56_Q), .Y(
        XOR3_7_Y));
    DFN1 DFN1_188 (.D(\PP5[16] ), .CLK(Clock), .Q(DFN1_188_Q));
    XOR3 XOR3_18 (.A(MAJ3_78_Y), .B(DFN1_108_Q), .C(XOR3_8_Y), .Y(
        XOR3_18_Y));
    AO1 AO1_22 (.A(AND2_60_Y), .B(AO1_43_Y), .C(AO1_47_Y), .Y(AO1_22_Y)
        );
    XOR2 XOR2_40 (.A(\SumA[12] ), .B(\SumB[12] ), .Y(XOR2_40_Y));
    AND2 AND2_91 (.A(\SumA[0] ), .B(\SumB[0] ), .Y(AND2_91_Y));
    XOR3 XOR3_31 (.A(DFN1_232_Q), .B(DFN1_146_Q), .C(DFN1_174_Q), .Y(
        XOR3_31_Y));
    MAJ3 MAJ3_31 (.A(DFN1_159_Q), .B(DFN1_75_Q), .C(DFN1_158_Q), .Y(
        MAJ3_31_Y));
    XOR2 \XOR2_PP6[6]  (.A(MX2_45_Y), .B(BUFF_9_Y), .Y(\PP6[6] ));
    BUFF BUFF_7 (.A(DataB[9]), .Y(BUFF_7_Y));
    AO1 AO1_54 (.A(XOR2_104_Y), .B(AND2_220_Y), .C(AND2_148_Y), .Y(
        AO1_54_Y));
    MAJ3 MAJ3_44 (.A(DFN1_107_Q), .B(DFN1_45_Q), .C(DFN1_210_Q), .Y(
        MAJ3_44_Y));
    DFN1 \DFN1_SumA[1]  (.D(DFN1_31_Q), .CLK(Clock), .Q(\SumA[1] ));
    XOR2 \XOR2_PP6[4]  (.A(MX2_20_Y), .B(BUFF_20_Y), .Y(\PP6[4] ));
    XOR2 \XOR2_PP5[13]  (.A(MX2_54_Y), .B(BUFF_24_Y), .Y(\PP5[13] ));
    AND2 AND2_184 (.A(AND2_158_Y), .B(XOR2_8_Y), .Y(AND2_184_Y));
    XOR2 \XOR2_PP6[10]  (.A(MX2_41_Y), .B(BUFF_9_Y), .Y(\PP6[10] ));
    MX2 MX2_89 (.A(AND2_123_Y), .B(BUFF_18_Y), .S(AO16_4_Y), .Y(
        MX2_89_Y));
    DFN1 DFN1_117 (.D(AND2_33_Y), .CLK(Clock), .Q(DFN1_117_Q));
    DFN1 DFN1_4 (.D(XOR2_17_Y), .CLK(Clock), .Q(DFN1_4_Q));
    OR3 OR3_6 (.A(DataB[7]), .B(DataB[8]), .C(DataB[9]), .Y(OR3_6_Y));
    AND2 AND2_69 (.A(XOR2_82_Y), .B(BUFF_30_Y), .Y(AND2_69_Y));
    MX2 MX2_37 (.A(BUFF_7_Y), .B(XOR2_67_Y), .S(XOR2_13_Y), .Y(
        MX2_37_Y));
    XOR2 XOR2_92 (.A(\SumA[19] ), .B(\SumB[19] ), .Y(XOR2_92_Y));
    MX2 MX2_54 (.A(AND2_147_Y), .B(BUFF_2_Y), .S(AO16_4_Y), .Y(
        MX2_54_Y));
    MX2 MX2_75 (.A(AND2_172_Y), .B(BUFF_30_Y), .S(AND2A_1_Y), .Y(
        MX2_75_Y));
    AND2 AND2_55 (.A(\SumA[25] ), .B(\SumB[25] ), .Y(AND2_55_Y));
    XOR2 \XOR2_Mult[10]  (.A(XOR2_85_Y), .B(AO1_39_Y), .Y(Mult[10]));
    MX2 MX2_23 (.A(AND2_115_Y), .B(BUFF_34_Y), .S(AO16_3_Y), .Y(
        MX2_23_Y));
    MX2 MX2_94 (.A(AND2_64_Y), .B(BUFF_19_Y), .S(AO16_2_Y), .Y(
        MX2_94_Y));
    MAJ3 MAJ3_19 (.A(XOR3_64_Y), .B(MAJ3_59_Y), .C(DFN1_211_Q), .Y(
        MAJ3_19_Y));
    XOR2 \XOR2_PP2[4]  (.A(MX2_58_Y), .B(BUFF_36_Y), .Y(\PP2[4] ));
    DFN1 DFN1_200 (.D(\E[3] ), .CLK(Clock), .Q(DFN1_200_Q));
    MAJ3 MAJ3_18 (.A(DFN1_136_Q), .B(DFN1_213_Q), .C(DFN1_142_Q), .Y(
        MAJ3_18_Y));
    DFN1 \DFN1_SumA[24]  (.D(MAJ3_64_Y), .CLK(Clock), .Q(\SumA[24] ));
    AND2 AND2_181 (.A(XOR2_13_Y), .B(BUFF_34_Y), .Y(AND2_181_Y));
    MX2 MX2_65 (.A(AND2_74_Y), .B(BUFF_3_Y), .S(AO16_8_Y), .Y(MX2_65_Y)
        );
    MX2 MX2_1 (.A(AND2_108_Y), .B(BUFF_37_Y), .S(AO16_7_Y), .Y(MX2_1_Y)
        );
    DFN1 \DFN1_SumB[18]  (.D(XOR3_33_Y), .CLK(Clock), .Q(\SumB[18] ));
    DFN1 DFN1_231 (.D(DFN1_236_Q), .CLK(Clock), .Q(DFN1_231_Q));
    DFN1 DFN1_73 (.D(\PP3[15] ), .CLK(Clock), .Q(DFN1_73_Q));
    DFN1 DFN1_142 (.D(\PP0[9] ), .CLK(Clock), .Q(DFN1_142_Q));
    XOR2 \XOR2_PP2[11]  (.A(MX2_7_Y), .B(BUFF_32_Y), .Y(\PP2[11] ));
    DFN1 DFN1_140 (.D(EBAR), .CLK(Clock), .Q(DFN1_140_Q));
    AND2 AND2_96 (.A(DFN1_53_Q), .B(DFN1_17_Q), .Y(AND2_96_Y));
    AO1 AO1_59 (.A(XOR2_53_Y), .B(AND2_16_Y), .C(AND2_55_Y), .Y(
        AO1_59_Y));
    XOR2 XOR2_71 (.A(DataB[3]), .B(DataB[4]), .Y(XOR2_71_Y));
    AND2 AND2_146 (.A(DataB[0]), .B(BUFF_48_Y), .Y(AND2_146_Y));
    XOR2 \XOR2_Mult[12]  (.A(XOR2_98_Y), .B(AO1_66_Y), .Y(Mult[12]));
    DFN1 DFN1_138 (.D(MAJ3_55_Y), .CLK(Clock), .Q(DFN1_138_Q));
    AND2 AND2_18 (.A(XOR2_100_Y), .B(BUFF_26_Y), .Y(AND2_18_Y));
    MAJ3 MAJ3_21 (.A(DFN1_189_Q), .B(DFN1_13_Q), .C(DFN1_129_Q), .Y(
        MAJ3_21_Y));
    XOR2 \XOR2_PP1[15]  (.A(MX2_36_Y), .B(BUFF_44_Y), .Y(\PP1[15] ));
    BUFF BUFF_12 (.A(DataA[10]), .Y(BUFF_12_Y));
    XOR2 XOR2_96 (.A(\SumA[2] ), .B(\SumB[2] ), .Y(XOR2_96_Y));
    AND2 AND2_78 (.A(XOR2_27_Y), .B(BUFF_16_Y), .Y(AND2_78_Y));
    AO1 AO1_30 (.A(AND2_53_Y), .B(AO1_32_Y), .C(AO1_63_Y), .Y(AO1_30_Y)
        );
    DFN1 \DFN1_SumA[5]  (.D(MAJ3_77_Y), .CLK(Clock), .Q(\SumA[5] ));
    AND2 AND2_138 (.A(DFN1_144_Q), .B(DFN1_221_Q), .Y(AND2_138_Y));
    XOR2 \XOR2_PP4[7]  (.A(MX2_16_Y), .B(BUFF_35_Y), .Y(\PP4[7] ));
    AND2 AND2_40 (.A(XOR2_39_Y), .B(BUFF_45_Y), .Y(AND2_40_Y));
    BUFF BUFF_33 (.A(DataA[14]), .Y(BUFF_33_Y));
    BUFF BUFF_31 (.A(DataA[0]), .Y(BUFF_31_Y));
    MX2 MX2_100 (.A(AND2_27_Y), .B(BUFF_10_Y), .S(AO16_13_Y), .Y(
        MX2_100_Y));
    XOR2 XOR2_24 (.A(\SumA[9] ), .B(\SumB[9] ), .Y(XOR2_24_Y));
    MAJ3 MAJ3_71 (.A(XOR3_7_Y), .B(MAJ3_40_Y), .C(DFN1_63_Q), .Y(
        MAJ3_71_Y));
    AND2 AND2_153 (.A(\SumA[23] ), .B(\SumB[23] ), .Y(AND2_153_Y));
    AO1 AO1_71 (.A(AND2_162_Y), .B(AO1_50_Y), .C(AO1_59_Y), .Y(
        AO1_71_Y));
    BUFF BUFF_22 (.A(DataA[8]), .Y(BUFF_22_Y));
    XOR2 XOR2_34 (.A(AND2_19_Y), .B(BUFF_36_Y), .Y(XOR2_34_Y));
    AND2 AND2_32 (.A(DFN1_115_Q), .B(DFN1_195_Q), .Y(AND2_32_Y));
    XOR2 \XOR2_PP2[14]  (.A(MX2_94_Y), .B(BUFF_4_Y), .Y(\PP2[14] ));
    AO1 AO1_66 (.A(AND2_94_Y), .B(AO1_42_Y), .C(AO1_73_Y), .Y(AO1_66_Y)
        );
    AND2 AND2_201 (.A(XOR2_10_Y), .B(BUFF_10_Y), .Y(AND2_201_Y));
    AND2 AND2_60 (.A(AND2_29_Y), .B(XOR2_59_Y), .Y(AND2_60_Y));
    OR3 OR3_4 (.A(DataB[5]), .B(DataB[6]), .C(DataB[7]), .Y(OR3_4_Y));
    DFN1 DFN1_207 (.D(\PP4[11] ), .CLK(Clock), .Q(DFN1_207_Q));
    XOR2 \XOR2_PP3[0]  (.A(XOR2_48_Y), .B(DataB[7]), .Y(\PP3[0] ));
    MX2 MX2_0 (.A(AND2_98_Y), .B(BUFF_23_Y), .S(AND2A_1_Y), .Y(MX2_0_Y)
        );
    XOR2 XOR2_43 (.A(DFN1_217_Q), .B(DFN1_153_Q), .Y(XOR2_43_Y));
    DFN1 DFN1_47 (.D(MAJ3_20_Y), .CLK(Clock), .Q(DFN1_47_Q));
    DFN1 DFN1_46 (.D(MAJ3_24_Y), .CLK(Clock), .Q(DFN1_46_Q));
    BUFF BUFF_4 (.A(DataB[5]), .Y(BUFF_4_Y));
    XOR2 XOR2_61 (.A(\SumA[21] ), .B(\SumB[21] ), .Y(XOR2_61_Y));
    BUFF BUFF_48 (.A(DataA[10]), .Y(BUFF_48_Y));
    XOR2 XOR2_49 (.A(\SumA[6] ), .B(\SumB[6] ), .Y(XOR2_49_Y));
    DFN1 DFN1_11 (.D(\PP4[1] ), .CLK(Clock), .Q(DFN1_11_Q));
    AND2 AND2_85 (.A(\SumA[5] ), .B(\SumB[5] ), .Y(AND2_85_Y));
    AND2 AND2_147 (.A(XOR2_29_Y), .B(BUFF_34_Y), .Y(AND2_147_Y));
    AND2 AND2_209 (.A(DFN1_175_Q), .B(DFN1_101_Q), .Y(AND2_209_Y));
    AO1 AO1_35 (.A(XOR2_93_Y), .B(AO1_33_Y), .C(AND2_174_Y), .Y(
        AO1_35_Y));
    AO1 AO1_27 (.A(AND2_58_Y), .B(AO1_26_Y), .C(AO1_51_Y), .Y(AO1_27_Y)
        );
    MX2 MX2_21 (.A(AND2_100_Y), .B(BUFF_6_Y), .S(AO16_7_Y), .Y(
        MX2_21_Y));
    AND2 AND2_53 (.A(AND2_224_Y), .B(AND2_160_Y), .Y(AND2_53_Y));
    XOR3 XOR3_22 (.A(AND2_163_Y), .B(DFN1_22_Q), .C(XOR3_38_Y), .Y(
        XOR3_22_Y));
    AO1 AO1_13 (.A(XOR2_54_Y), .B(OR3_4_Y), .C(AND3_4_Y), .Y(AO1_13_Y));
    MX2 MX2_14 (.A(AND2_231_Y), .B(BUFF_33_Y), .S(AO16_4_Y), .Y(
        MX2_14_Y));
    AND2 AND2_174 (.A(\SumA[12] ), .B(\SumB[12] ), .Y(AND2_174_Y));
    DFN1 DFN1_206 (.D(\PP1[2] ), .CLK(Clock), .Q(DFN1_206_Q));
    AND2 AND2_125 (.A(AND2_21_Y), .B(XOR2_37_Y), .Y(AND2_125_Y));
    DFN1 DFN1_49 (.D(\PP3[6] ), .CLK(Clock), .Q(DFN1_49_Q));
    MX2 MX2_33 (.A(AND2_124_Y), .B(BUFF_49_Y), .S(AO16_5_Y), .Y(
        MX2_33_Y));
    XOR3 XOR3_8 (.A(DFN1_160_Q), .B(DFN1_47_Q), .C(DFN1_234_Q), .Y(
        XOR3_8_Y));
    XOR3 XOR3_32 (.A(MAJ3_41_Y), .B(DFN1_28_Q), .C(XOR3_39_Y), .Y(
        XOR3_32_Y));
    MAJ3 MAJ3_37 (.A(DFN1_68_Q), .B(DFN1_32_Q), .C(DFN1_25_Q), .Y(
        MAJ3_37_Y));
    XOR2 \XOR2_Mult[3]  (.A(XOR2_11_Y), .B(AO1_55_Y), .Y(Mult[3]));
    MX2 MX2_28 (.A(AND2_232_Y), .B(BUFF_29_Y), .S(AO16_15_Y), .Y(
        MX2_28_Y));
    AND2 AND2_99 (.A(XOR2_35_Y), .B(BUFF_11_Y), .Y(AND2_99_Y));
    XOR2 \XOR2_PP5[1]  (.A(MX2_104_Y), .B(BUFF_52_Y), .Y(\PP5[1] ));
    XOR2 XOR2_47 (.A(\SumA[7] ), .B(\SumB[7] ), .Y(XOR2_47_Y));
    BUFF BUFF_51 (.A(DataA[15]), .Y(BUFF_51_Y));
    XOR2 \XOR2_PP4[10]  (.A(MX2_77_Y), .B(BUFF_35_Y), .Y(\PP4[10] ));
    AO1 AO1_28 (.A(AND2_24_Y), .B(AO1_42_Y), .C(AO1_33_Y), .Y(AO1_28_Y)
        );
    XOR2 \XOR2_PP3[11]  (.A(MX2_82_Y), .B(BUFF_5_Y), .Y(\PP3[11] ));
    XOR2 XOR2_9 (.A(DataB[11]), .B(DataB[12]), .Y(XOR2_9_Y));
    AND2 AND2_224 (.A(AND2_50_Y), .B(AND2_121_Y), .Y(AND2_224_Y));
    AO1 AO1_12 (.A(XOR2_47_Y), .B(AND2_131_Y), .C(AND2_119_Y), .Y(
        AO1_12_Y));
    MAJ3 MAJ3_61 (.A(XOR3_57_Y), .B(MAJ3_6_Y), .C(DFN1_223_Q), .Y(
        MAJ3_61_Y));
    AND2 AND2_171 (.A(AND2_208_Y), .B(AND2_12_Y), .Y(AND2_171_Y));
    MAJ3 MAJ3_51 (.A(MAJ3_63_Y), .B(AND2_213_Y), .C(DFN1_143_Q), .Y(
        MAJ3_51_Y));
    AND2 AND2_120 (.A(XOR2_28_Y), .B(BUFF_12_Y), .Y(AND2_120_Y));
    XOR2 XOR2_25 (.A(\SumA[14] ), .B(\SumB[14] ), .Y(XOR2_25_Y));
    XOR2 \XOR2_Mult[17]  (.A(XOR2_56_Y), .B(AO1_56_Y), .Y(Mult[17]));
    XOR2 XOR2_35 (.A(DataB[7]), .B(DataB[8]), .Y(XOR2_35_Y));
    AND3 AND3_0 (.A(DataB[7]), .B(DataB[8]), .C(DataB[9]), .Y(AND3_0_Y)
        );
    DFN1 DFN1_151 (.D(MAJ3_7_Y), .CLK(Clock), .Q(DFN1_151_Q));
    DFN1 \DFN1_SumA[27]  (.D(XOR2_52_Y), .CLK(Clock), .Q(\SumA[27] ));
    XOR3 XOR3_26 (.A(DFN1_125_Q), .B(DFN1_91_Q), .C(DFN1_118_Q), .Y(
        XOR3_26_Y));
    XOR2 \XOR2_PP4[0]  (.A(XOR2_0_Y), .B(DataB[9]), .Y(\PP4[0] ));
    XOR2 \XOR2_PP1[1]  (.A(MX2_43_Y), .B(BUFF_21_Y), .Y(\PP1[1] ));
    AO16 AO16_4 (.A(DataB[9]), .B(DataB[10]), .C(BUFF_24_Y), .Y(
        AO16_4_Y));
    MX2 MX2_50 (.A(AND2_203_Y), .B(BUFF_48_Y), .S(AO16_6_Y), .Y(
        MX2_50_Y));
    MX2 MX2_7 (.A(AND2_97_Y), .B(BUFF_48_Y), .S(AO16_13_Y), .Y(MX2_7_Y)
        );
    DFN1 \DFN1_SumB[5]  (.D(XOR3_22_Y), .CLK(Clock), .Q(\SumB[5] ));
    AND2 AND2_17 (.A(DataB[0]), .B(BUFF_31_Y), .Y(AND2_17_Y));
    AND2 AND2_114 (.A(\SumA[13] ), .B(\SumB[13] ), .Y(AND2_114_Y));
    DFN1 \DFN1_SumA[22]  (.D(MAJ3_69_Y), .CLK(Clock), .Q(\SumA[22] ));
    XOR3 XOR3_36 (.A(MAJ3_76_Y), .B(DFN1_112_Q), .C(XOR3_26_Y), .Y(
        XOR3_36_Y));
    AND2 AND2_77 (.A(DataB[0]), .B(BUFF_47_Y), .Y(AND2_77_Y));
    DFN1 DFN1_224 (.D(\PP3[4] ), .CLK(Clock), .Q(DFN1_224_Q));
    AO1 AO1_3 (.A(AND2_226_Y), .B(AO1_29_Y), .C(AO1_8_Y), .Y(AO1_3_Y));
    BUFF BUFF_16 (.A(DataA[6]), .Y(BUFF_16_Y));
    DFN1 \DFN1_SumB[8]  (.D(XOR3_56_Y), .CLK(Clock), .Q(\SumB[8] ));
    MX2 MX2_90 (.A(AND2_117_Y), .B(BUFF_1_Y), .S(AO16_16_Y), .Y(
        MX2_90_Y));
    AND2 AND2_133 (.A(XOR2_101_Y), .B(BUFF_11_Y), .Y(AND2_133_Y));
    AND2 AND2_38 (.A(AND2_105_Y), .B(AND2_125_Y), .Y(AND2_38_Y));
    OR3 OR3_0 (.A(DataB[11]), .B(DataB[12]), .C(DataB[13]), .Y(OR3_0_Y)
        );
    MX2 MX2_6 (.A(AND2_212_Y), .B(BUFF_19_Y), .S(AO16_12_Y), .Y(
        MX2_6_Y));
    XOR2 XOR2_72 (.A(BUFF_51_Y), .B(DataB[5]), .Y(XOR2_72_Y));
    AND2 AND2_129 (.A(XOR2_60_Y), .B(BUFF_31_Y), .Y(AND2_129_Y));
    XOR2 \XOR2_PP3[14]  (.A(MX2_70_Y), .B(BUFF_40_Y), .Y(\PP3[14] ));
    AO16 AO16_1 (.A(DataB[7]), .B(DataB[8]), .C(BUFF_39_Y), .Y(
        AO16_1_Y));
    DFN1 DFN1_30 (.D(\PP1[8] ), .CLK(Clock), .Q(DFN1_30_Q));
    MAJ3 MAJ3_27 (.A(XOR3_38_Y), .B(AND2_163_Y), .C(DFN1_22_Q), .Y(
        MAJ3_27_Y));
    MAJ3 MAJ3_39 (.A(XOR3_16_Y), .B(XOR2_43_Y), .C(DFN1_6_Q), .Y(
        MAJ3_39_Y));
    AO1 AO1_56 (.A(AND2_211_Y), .B(AO1_32_Y), .C(AO1_25_Y), .Y(
        AO1_56_Y));
    XOR2 \XOR2_PP0[12]  (.A(MX2_13_Y), .B(BUFF_0_Y), .Y(\PP0[12] ));
    MAJ3 MAJ3_38 (.A(XOR3_50_Y), .B(XOR2_58_Y), .C(DFN1_94_Q), .Y(
        MAJ3_38_Y));
    AO1 AO1_0 (.A(XOR2_42_Y), .B(AND2_174_Y), .C(AND2_114_Y), .Y(
        AO1_0_Y));
    AND2 AND2_111 (.A(XOR2_60_Y), .B(BUFF_29_Y), .Y(AND2_111_Y));
    DFN1 DFN1_44 (.D(DFN1_106_Q), .CLK(Clock), .Q(DFN1_44_Q));
    XOR3 XOR3_44 (.A(MAJ3_49_Y), .B(DFN1_46_Q), .C(XOR3_31_Y), .Y(
        XOR3_44_Y));
    BUFF BUFF_26 (.A(DataA[12]), .Y(BUFF_26_Y));
    DFN1 \DFN1_SumA[18]  (.D(MAJ3_19_Y), .CLK(Clock), .Q(\SumA[18] ));
    XOR3 XOR3_64 (.A(DFN1_32_Q), .B(DFN1_25_Q), .C(DFN1_68_Q), .Y(
        XOR3_64_Y));
    XOR2 \XOR2_PP0[0]  (.A(XOR2_55_Y), .B(DataB[1]), .Y(\PP0[0] ));
    AND2 AND2_83 (.A(AND2_151_Y), .B(AND2_177_Y), .Y(AND2_83_Y));
    DFN1 DFN1_80 (.D(\S[2] ), .CLK(Clock), .Q(DFN1_80_Q));
    AO16 AO16_7 (.A(DataB[9]), .B(DataB[10]), .C(BUFF_52_Y), .Y(
        AO16_7_Y));
    MX2 MX2_42 (.A(AND2_155_Y), .B(BUFF_50_Y), .S(AO16_13_Y), .Y(
        MX2_42_Y));
    AND2 AND2_11 (.A(XOR2_27_Y), .B(BUFF_22_Y), .Y(AND2_11_Y));
    XOR2 XOR2_18 (.A(\SumA[26] ), .B(\SumB[26] ), .Y(XOR2_18_Y));
    AND2 AND2_90 (.A(XOR2_33_Y), .B(BUFF_11_Y), .Y(AND2_90_Y));
    XOR2 \XOR2_PP5[12]  (.A(MX2_89_Y), .B(BUFF_24_Y), .Y(\PP5[12] ));
    MAJ3 MAJ3_77 (.A(XOR2_14_Y), .B(DFN1_116_Q), .C(DFN1_165_Q), .Y(
        MAJ3_77_Y));
    AND2 AND2_71 (.A(XOR2_82_Y), .B(BUFF_31_Y), .Y(AND2_71_Y));
    AND2 AND2_185 (.A(AND2_208_Y), .B(AND2_73_Y), .Y(AND2_185_Y));
    BUFF BUFF_37 (.A(DataA[1]), .Y(BUFF_37_Y));
    AND2 AND2_164 (.A(XOR2_99_Y), .B(BUFF_8_Y), .Y(AND2_164_Y));
    XOR2 XOR2_20 (.A(DFN1_207_Q), .B(DFN1_105_Q), .Y(XOR2_20_Y));
    MX2 MX2_31 (.A(AND2_42_Y), .B(BUFF_23_Y), .S(AO16_17_Y), .Y(
        MX2_31_Y));
    XOR2 XOR2_76 (.A(\SumA[16] ), .B(\SumB[16] ), .Y(XOR2_76_Y));
    AND2 AND2_215 (.A(AND2_45_Y), .B(AND2_52_Y), .Y(AND2_215_Y));
    MX2 MX2_85 (.A(AND2_135_Y), .B(BUFF_38_Y), .S(AO16_5_Y), .Y(
        MX2_85_Y));
    XOR2 XOR2_30 (.A(\SumA[5] ), .B(\SumB[5] ), .Y(XOR2_30_Y));
    XOR2 XOR2_88 (.A(\SumA[3] ), .B(\SumB[3] ), .Y(XOR2_88_Y));
    MX2 \MX2_PP3[16]  (.A(MX2_25_Y), .B(AO1_13_Y), .S(AO16_16_Y), .Y(
        \PP3[16] ));
    MX2 MX2_56 (.A(AND2_63_Y), .B(BUFF_8_Y), .S(AO16_6_Y), .Y(MX2_56_Y)
        );
    MX2 MX2_38 (.A(AND2_56_Y), .B(BUFF_12_Y), .S(AO16_10_Y), .Y(
        MX2_38_Y));
    AND2 \AND2_S[3]  (.A(XOR2_48_Y), .B(DataB[7]), .Y(\S[3] ));
    MX2 MX2_107 (.A(AND2_4_Y), .B(BUFF_31_Y), .S(AO16_15_Y), .Y(
        MX2_107_Y));
    AND2 AND2_180 (.A(DataB[0]), .B(BUFF_13_Y), .Y(AND2_180_Y));
    XOR2 XOR2_62 (.A(DFN1_8_Q), .B(VCC), .Y(XOR2_62_Y));
    DFN1 DFN1_228 (.D(DFN1_7_Q), .CLK(Clock), .Q(DFN1_228_Q));
    AND2 AND2_161 (.A(DataB[0]), .B(BUFF_8_Y), .Y(AND2_161_Y));
    DFN1 DFN1_3 (.D(\PP2[0] ), .CLK(Clock), .Q(DFN1_3_Q));
    AND2 AND2_4 (.A(XOR2_60_Y), .B(BUFF_23_Y), .Y(AND2_4_Y));
    DFN1 DFN1_115 (.D(\PP4[7] ), .CLK(Clock), .Q(DFN1_115_Q));
    XOR3 XOR3_2 (.A(DFN1_93_Q), .B(DFN1_86_Q), .C(DFN1_155_Q), .Y(
        XOR3_2_Y));
    MAJ3 MAJ3_29 (.A(DFN1_234_Q), .B(DFN1_160_Q), .C(DFN1_47_Q), .Y(
        MAJ3_29_Y));
    MX2 MX2_96 (.A(AND2_168_Y), .B(BUFF_34_Y), .S(AO16_11_Y), .Y(
        MX2_96_Y));
    DFN1 \DFN1_SumA[4]  (.D(MAJ3_35_Y), .CLK(Clock), .Q(\SumA[4] ));
    MAJ3 MAJ3_28 (.A(XOR3_62_Y), .B(MAJ3_21_Y), .C(DFN1_150_Q), .Y(
        MAJ3_28_Y));
    DFN1 DFN1_61 (.D(\PP5[0] ), .CLK(Clock), .Q(DFN1_61_Q));
    MX2 MX2_74 (.A(BUFF_24_Y), .B(XOR2_63_Y), .S(XOR2_29_Y), .Y(
        MX2_74_Y));
    MX2 \MX2_PP6[16]  (.A(MX2_67_Y), .B(AO1_69_Y), .S(AO16_3_Y), .Y(
        \PP6[16] ));
    DFN1 DFN1_223 (.D(XOR3_28_Y), .CLK(Clock), .Q(DFN1_223_Q));
    AO16 AO16_15 (.A(DataB[5]), .B(DataB[6]), .C(BUFF_15_Y), .Y(
        AO16_15_Y));
    AND2 AND2_0 (.A(XOR2_75_Y), .B(BUFF_48_Y), .Y(AND2_0_Y));
    DFN1 DFN1_104 (.D(\PP2[13] ), .CLK(Clock), .Q(DFN1_104_Q));
    AND2 AND2_230 (.A(XOR2_82_Y), .B(BUFF_43_Y), .Y(AND2_230_Y));
    AND2 AND2_156 (.A(XOR2_33_Y), .B(BUFF_27_Y), .Y(AND2_156_Y));
    DFN1 DFN1_113 (.D(\PP5[10] ), .CLK(Clock), .Q(DFN1_113_Q));
    AO1 AO1_34 (.A(AND2_184_Y), .B(AO1_41_Y), .C(AO1_60_Y), .Y(
        AO1_34_Y));
    XOR3 XOR3_3 (.A(DFN1_235_Q), .B(VCC), .C(DFN1_156_Q), .Y(XOR3_3_Y));
    DFN1 \DFN1_SumA[23]  (.D(MAJ3_79_Y), .CLK(Clock), .Q(\SumA[23] ));
    AO1 AO1_43 (.A(AND2_82_Y), .B(AO1_55_Y), .C(AO1_62_Y), .Y(AO1_43_Y)
        );
    DFN1 DFN1_51 (.D(\PP5[13] ), .CLK(Clock), .Q(DFN1_51_Q));
    AND2 AND2_16 (.A(\SumA[24] ), .B(\SumB[24] ), .Y(AND2_16_Y));
    MX2 MX2_64 (.A(AND2_49_Y), .B(BUFF_29_Y), .S(AO16_14_Y), .Y(
        MX2_64_Y));
    DFN1 DFN1_8 (.D(\PP4[16] ), .CLK(Clock), .Q(DFN1_8_Q));
    DFN1 \DFN1_SumB[9]  (.D(XOR3_42_Y), .CLK(Clock), .Q(\SumB[9] ));
    AND2 AND2_76 (.A(XOR2_99_Y), .B(BUFF_47_Y), .Y(AND2_76_Y));
    MX2 MX2_10 (.A(BUFF_44_Y), .B(XOR2_45_Y), .S(XOR2_100_Y), .Y(
        MX2_10_Y));
    AND2 AND2_6 (.A(\SumA[1] ), .B(\SumB[1] ), .Y(AND2_6_Y));
    AO1 AO1_17 (.A(XOR2_37_Y), .B(AO1_19_Y), .C(AND2_61_Y), .Y(
        AO1_17_Y));
    XOR3 XOR3_45 (.A(DFN1_154_Q), .B(DFN1_200_Q), .C(DFN1_51_Q), .Y(
        XOR3_45_Y));
    XOR2 \XOR2_PP6[13]  (.A(MX2_11_Y), .B(BUFF_41_Y), .Y(\PP6[13] ));
    BUFF BUFF_44 (.A(DataB[3]), .Y(BUFF_44_Y));
    XOR3 XOR3_65 (.A(DFN1_45_Q), .B(DFN1_210_Q), .C(DFN1_107_Q), .Y(
        XOR3_65_Y));
    MAJ3 MAJ3_79 (.A(XOR3_41_Y), .B(MAJ3_33_Y), .C(DFN1_97_Q), .Y(
        MAJ3_79_Y));
    AND2 AND2_189 (.A(XOR2_10_Y), .B(BUFF_13_Y), .Y(AND2_189_Y));
    DFN1 DFN1_212 (.D(XOR3_19_Y), .CLK(Clock), .Q(DFN1_212_Q));
    MAJ3 MAJ3_78 (.A(DFN1_98_Q), .B(DFN1_176_Q), .C(DFN1_38_Q), .Y(
        MAJ3_78_Y));
    MX2 MX2_49 (.A(AND2_95_Y), .B(BUFF_3_Y), .S(AO16_1_Y), .Y(MX2_49_Y)
        );
    MAJ3 MAJ3_67 (.A(DFN1_104_Q), .B(DFN1_148_Q), .C(DFN1_140_Q), .Y(
        MAJ3_67_Y));
    MAJ3 MAJ3_57 (.A(DFN1_118_Q), .B(DFN1_125_Q), .C(DFN1_91_Q), .Y(
        MAJ3_57_Y));
    XOR2 XOR2_66 (.A(\SumA[8] ), .B(\SumB[8] ), .Y(XOR2_66_Y));
    XOR2 \XOR2_PP0[5]  (.A(MX2_78_Y), .B(BUFF_28_Y), .Y(\PP0[5] ));
    AO1 AO1_42 (.A(AND2_52_Y), .B(AO1_21_Y), .C(AO1_81_Y), .Y(AO1_42_Y)
        );
    AND2 AND2_37 (.A(\SumA[27] ), .B(\SumB[27] ), .Y(AND2_37_Y));
    DFN1 DFN1_121 (.D(\PP2[3] ), .CLK(Clock), .Q(DFN1_121_Q));
    DFN1 \DFN1_SumA[25]  (.D(MAJ3_13_Y), .CLK(Clock), .Q(\SumA[25] ));
    DFN1 DFN1_234 (.D(XOR3_67_Y), .CLK(Clock), .Q(DFN1_234_Q));
    AO1 AO1_18 (.A(XOR2_23_Y), .B(AND2_229_Y), .C(AND2_39_Y), .Y(
        AO1_18_Y));
    DFN1 \DFN1_SumB[21]  (.D(XOR3_58_Y), .CLK(Clock), .Q(\SumB[21] ));
    DFN1 DFN1_156 (.D(\PP4[14] ), .CLK(Clock), .Q(DFN1_156_Q));
    DFN1 DFN1_209 (.D(\PP2[14] ), .CLK(Clock), .Q(DFN1_209_Q));
    AO1 AO1_39 (.A(XOR2_31_Y), .B(AO1_42_Y), .C(AND2_165_Y), .Y(
        AO1_39_Y));
    OR3 OR3_2 (.A(DataB[1]), .B(DataB[2]), .C(DataB[3]), .Y(OR3_2_Y));
    DFN1 DFN1_25 (.D(MAJ3_42_Y), .CLK(Clock), .Q(DFN1_25_Q));
    XOR2 \XOR2_PP2[8]  (.A(MX2_72_Y), .B(BUFF_32_Y), .Y(\PP2[8] ));
    XOR2 XOR2_41 (.A(\SumA[10] ), .B(\SumB[10] ), .Y(XOR2_41_Y));
    AO1 AO1_21 (.A(AND2_82_Y), .B(AO1_55_Y), .C(AO1_62_Y), .Y(AO1_21_Y)
        );
    AND2 AND2_194 (.A(XOR2_101_Y), .B(BUFF_38_Y), .Y(AND2_194_Y));
    XOR2 XOR2_7 (.A(DFN1_135_Q), .B(DFN1_204_Q), .Y(XOR2_7_Y));
    MAJ3 MAJ3_42 (.A(XOR3_37_Y), .B(XOR2_87_Y), .C(DFN1_128_Q), .Y(
        MAJ3_42_Y));
    XOR2 XOR2_54 (.A(BUFF_51_Y), .B(DataB[7]), .Y(XOR2_54_Y));
    BUFF BUFF_6 (.A(DataA[3]), .Y(BUFF_6_Y));
    MAJ3 MAJ3_1 (.A(XOR3_49_Y), .B(MAJ3_65_Y), .C(DFN1_168_Q), .Y(
        MAJ3_1_Y));
    AND2 AND2_157 (.A(AND2_113_Y), .B(XOR2_31_Y), .Y(AND2_157_Y));
    AND2 AND2_44 (.A(AND2_158_Y), .B(AND2_217_Y), .Y(AND2_44_Y));
    DFN1 DFN1_159 (.D(\PP4[2] ), .CLK(Clock), .Q(DFN1_159_Q));
    DFN1 \DFN1_SumB[3]  (.D(XOR3_78_Y), .CLK(Clock), .Q(\SumB[3] ));
    XOR3 XOR3_14 (.A(DFN1_208_Q), .B(DFN1_126_Q), .C(XOR2_21_Y), .Y(
        XOR3_14_Y));
    XOR2 XOR2_23 (.A(\SumA[15] ), .B(\SumB[15] ), .Y(XOR2_23_Y));
    DFN1 DFN1_95 (.D(\PP1[10] ), .CLK(Clock), .Q(DFN1_95_Q));
    AND2 AND2_175 (.A(\SumA[21] ), .B(\SumB[21] ), .Y(AND2_175_Y));
    XOR2 \XOR2_PP5[2]  (.A(MX2_1_Y), .B(BUFF_52_Y), .Y(\PP5[2] ));
    DFN1 DFN1_37 (.D(DFN1_187_Q), .CLK(Clock), .Q(DFN1_37_Q));
    AND2 AND2_191 (.A(AND2_44_Y), .B(AND2_58_Y), .Y(AND2_191_Y));
    XOR2 XOR2_33 (.A(DataB[11]), .B(DataB[12]), .Y(XOR2_33_Y));
    AND2 AND2_31 (.A(XOR2_35_Y), .B(BUFF_37_Y), .Y(AND2_31_Y));
    DFN1 DFN1_36 (.D(\PP0[2] ), .CLK(Clock), .Q(DFN1_36_Q));
    MAJ3 MAJ3_69 (.A(XOR3_23_Y), .B(MAJ3_3_Y), .C(DFN1_194_Q), .Y(
        MAJ3_69_Y));
    XOR2 \XOR2_PP2[15]  (.A(MX2_111_Y), .B(BUFF_4_Y), .Y(\PP2[15] ));
    MX2 MX2_16 (.A(AND2_219_Y), .B(BUFF_16_Y), .S(AO16_0_Y), .Y(
        MX2_16_Y));
    AND2 AND2_122 (.A(XOR2_29_Y), .B(BUFF_33_Y), .Y(AND2_122_Y));
    XOR2 XOR2_29 (.A(DataB[9]), .B(DataB[10]), .Y(XOR2_29_Y));
    MAJ3 MAJ3_59 (.A(DFN1_56_Q), .B(DFN1_151_Q), .C(DFN1_74_Q), .Y(
        MAJ3_59_Y));
    MAJ3 MAJ3_68 (.A(MAJ3_67_Y), .B(AND2_22_Y), .C(DFN1_215_Q), .Y(
        MAJ3_68_Y));
    XOR3 XOR3_40 (.A(XOR2_87_Y), .B(DFN1_128_Q), .C(XOR3_37_Y), .Y(
        XOR3_40_Y));
    AND2 AND2_64 (.A(XOR2_90_Y), .B(BUFF_1_Y), .Y(AND2_64_Y));
    XOR3 XOR3_60 (.A(AND2_22_Y), .B(DFN1_215_Q), .C(MAJ3_67_Y), .Y(
        XOR3_60_Y));
    BUFF BUFF_39 (.A(DataB[9]), .Y(BUFF_39_Y));
    MAJ3 MAJ3_58 (.A(XOR3_9_Y), .B(XOR2_81_Y), .C(DFN1_133_Q), .Y(
        MAJ3_58_Y));
    XOR2 XOR2_39 (.A(DataB[11]), .B(DataB[12]), .Y(XOR2_39_Y));
    DFN1 DFN1_107 (.D(\PP6[9] ), .CLK(Clock), .Q(DFN1_107_Q));
    XOR2 \XOR2_PP0[9]  (.A(MX2_69_Y), .B(BUFF_25_Y), .Y(\PP0[9] ));
    XOR2 \XOR2_PP3[5]  (.A(MX2_80_Y), .B(BUFF_15_Y), .Y(\PP3[5] ));
    AND2 AND2_136 (.A(AND2_221_Y), .B(AND2_35_Y), .Y(AND2_136_Y));
    AND2 AND2_170 (.A(AND2_215_Y), .B(AND2_13_Y), .Y(AND2_170_Y));
    XOR2 \XOR2_PP2[6]  (.A(MX2_42_Y), .B(BUFF_32_Y), .Y(\PP2[6] ));
    AND2 AND2_19 (.A(XOR2_71_Y), .B(BUFF_31_Y), .Y(AND2_19_Y));
    DFN1 DFN1_87 (.D(\PP6[13] ), .CLK(Clock), .Q(DFN1_87_Q));
    XOR2 \XOR2_Mult[28]  (.A(XOR2_68_Y), .B(AO1_74_Y), .Y(Mult[28]));
    DFN1 DFN1_181 (.D(\PP0[1] ), .CLK(Clock), .Q(DFN1_181_Q));
    AND2 AND2_79 (.A(XOR2_99_Y), .B(BUFF_48_Y), .Y(AND2_79_Y));
    DFN1 DFN1_86 (.D(MAJ3_8_Y), .CLK(Clock), .Q(DFN1_86_Q));
    DFN1 DFN1_211 (.D(XOR3_60_Y), .CLK(Clock), .Q(DFN1_211_Q));
    DFN1 DFN1_39 (.D(\PP2[11] ), .CLK(Clock), .Q(DFN1_39_Q));
    DFN1 DFN1_225 (.D(\PP2[4] ), .CLK(Clock), .Q(DFN1_225_Q));
    MX2 MX2_57 (.A(AND2_79_Y), .B(BUFF_13_Y), .S(AO16_9_Y), .Y(
        MX2_57_Y));
    DFN1 DFN1_71 (.D(\PP4[6] ), .CLK(Clock), .Q(DFN1_71_Q));
    XOR2 XOR2_27 (.A(DataB[7]), .B(DataB[8]), .Y(XOR2_27_Y));
    MX2 MX2_8 (.A(AND2_161_Y), .B(BUFF_10_Y), .S(AND2A_2_Y), .Y(
        MX2_8_Y));
    XOR2 XOR2_6 (.A(\SumA[22] ), .B(\SumB[22] ), .Y(XOR2_6_Y));
    AND2 AND2_227 (.A(AND2_35_Y), .B(XOR2_94_Y), .Y(AND2_227_Y));
    XOR2 XOR2_37 (.A(\SumA[28] ), .B(\SumB[28] ), .Y(XOR2_37_Y));
    DFN1 \DFN1_SumB[0]  (.D(DFN1_0_Q), .CLK(Clock), .Q(\SumB[0] ));
    MX2 MX2_97 (.A(AND2_164_Y), .B(BUFF_10_Y), .S(AO16_9_Y), .Y(
        MX2_97_Y));
    DFN1 DFN1_118 (.D(AND2_139_Y), .CLK(Clock), .Q(DFN1_118_Q));
    BUFF BUFF_13 (.A(DataA[9]), .Y(BUFF_13_Y));
    DFN1 DFN1_233 (.D(\PP5[3] ), .CLK(Clock), .Q(DFN1_233_Q));
    BUFF BUFF_11 (.A(DataA[0]), .Y(BUFF_11_Y));
    AND2 AND2_115 (.A(XOR2_39_Y), .B(BUFF_33_Y), .Y(AND2_115_Y));
    DFN1 \DFN1_SumB[26]  (.D(XOR3_59_Y), .CLK(Clock), .Q(\SumB[26] ));
    BUFF BUFF_45 (.A(DataA[15]), .Y(BUFF_45_Y));
    DFN1 DFN1_89 (.D(\PP4[0] ), .CLK(Clock), .Q(DFN1_89_Q));
    BUFF BUFF_40 (.A(DataB[7]), .Y(BUFF_40_Y));
    XOR2 XOR2_55 (.A(AND2_17_Y), .B(BUFF_28_Y), .Y(XOR2_55_Y));
    MX2 \MX2_PP0[16]  (.A(MX2_46_Y), .B(EBAR), .S(AND2A_0_Y), .Y(
        \PP0[16] ));
    XOR2 \XOR2_Mult[15]  (.A(XOR2_25_Y), .B(AO1_58_Y), .Y(Mult[15]));
    AND2A AND2A_2 (.A(DataB[0]), .B(BUFF_25_Y), .Y(AND2A_2_Y));
    DFN1 \DFN1_SumB[20]  (.D(XOR3_6_Y), .CLK(Clock), .Q(\SumB[20] ));
    AND2 AND2_104 (.A(DataB[0]), .B(BUFF_50_Y), .Y(AND2_104_Y));
    AND2 AND2_36 (.A(AND2_215_Y), .B(AND2_53_Y), .Y(AND2_36_Y));
    AND2 AND2_179 (.A(XOR2_99_Y), .B(BUFF_10_Y), .Y(AND2_179_Y));
    DFN1 DFN1_152 (.D(\PP0[8] ), .CLK(Clock), .Q(DFN1_152_Q));
    AND2 AND2_9 (.A(\SumA[3] ), .B(\SumB[3] ), .Y(AND2_9_Y));
    DFN1 DFN1_150 (.D(XOR3_5_Y), .CLK(Clock), .Q(DFN1_150_Q));
    AND2 AND2_226 (.A(XOR2_16_Y), .B(XOR2_77_Y), .Y(AND2_226_Y));
    AND2 AND2_214 (.A(AND2_107_Y), .B(XOR2_76_Y), .Y(AND2_214_Y));
    XOR3 XOR3_58 (.A(MAJ3_3_Y), .B(DFN1_194_Q), .C(XOR3_23_Y), .Y(
        XOR3_58_Y));
    XOR2 \XOR2_PP6[5]  (.A(MX2_65_Y), .B(BUFF_20_Y), .Y(\PP6[5] ));
    AND2A AND2A_1 (.A(DataB[0]), .B(BUFF_28_Y), .Y(AND2A_1_Y));
    MX2 MX2_70 (.A(AND2_127_Y), .B(BUFF_19_Y), .S(AO16_16_Y), .Y(
        MX2_70_Y));
    XOR2 \XOR2_PP6[8]  (.A(MX2_92_Y), .B(BUFF_9_Y), .Y(\PP6[8] ));
    XOR3 XOR3_15 (.A(MAJ3_65_Y), .B(DFN1_168_Q), .C(XOR3_49_Y), .Y(
        XOR3_15_Y));
    AND2 AND2_110 (.A(XOR2_100_Y), .B(BUFF_19_Y), .Y(AND2_110_Y));
    DFN1 DFN1_174 (.D(XOR2_62_Y), .CLK(Clock), .Q(DFN1_174_Q));
    BUFF BUFF_23 (.A(DataA[1]), .Y(BUFF_23_Y));
    XOR2 \XOR2_PP4[3]  (.A(MX2_81_Y), .B(BUFF_39_Y), .Y(\PP4[3] ));
    DFN1 DFN1_164 (.D(\PP3[3] ), .CLK(Clock), .Q(DFN1_164_Q));
    XOR2 \XOR2_PP4[13]  (.A(MX2_53_Y), .B(BUFF_7_Y), .Y(\PP4[13] ));
    BUFF BUFF_21 (.A(DataB[3]), .Y(BUFF_21_Y));
    MX2 MX2_60 (.A(AND2_156_Y), .B(BUFF_37_Y), .S(AO16_8_Y), .Y(
        MX2_60_Y));
    DFN1 \DFN1_SumB[11]  (.D(XOR3_68_Y), .CLK(Clock), .Q(\SumB[11] ));
    AND2 AND2_101 (.A(XOR2_39_Y), .B(BUFF_34_Y), .Y(AND2_101_Y));
    AO1 AO1_47 (.A(XOR2_59_Y), .B(AO1_68_Y), .C(AND2_131_Y), .Y(
        AO1_47_Y));
    AND2 AND2_137 (.A(AND2_5_Y), .B(AND2_205_Y), .Y(AND2_137_Y));
    DFN1 DFN1_131 (.D(\PP2[8] ), .CLK(Clock), .Q(DFN1_131_Q));
    DFN1 DFN1_34 (.D(\PP0[16] ), .CLK(Clock), .Q(DFN1_34_Q));
    DFN1 DFN1_194 (.D(XOR3_3_Y), .CLK(Clock), .Q(DFN1_194_Q));
    AND2 AND2_165 (.A(\SumA[8] ), .B(\SumB[8] ), .Y(AND2_165_Y));
    AND2 AND2_182 (.A(XOR2_27_Y), .B(BUFF_18_Y), .Y(AND2_182_Y));
    AND2 AND2_10 (.A(\SumA[17] ), .B(\SumB[17] ), .Y(AND2_10_Y));
    XOR2 \XOR2_PP6[9]  (.A(MX2_34_Y), .B(BUFF_9_Y), .Y(\PP6[9] ));
    XOR2 \XOR2_PP1[2]  (.A(MX2_31_Y), .B(BUFF_21_Y), .Y(\PP1[2] ));
    AND2 AND2_119 (.A(\SumA[7] ), .B(\SumB[7] ), .Y(AND2_119_Y));
    AND2 AND2_70 (.A(XOR2_28_Y), .B(BUFF_42_Y), .Y(AND2_70_Y));
    XOR3 XOR3_78 (.A(DFN1_42_Q), .B(DFN1_60_Q), .C(DFN1_170_Q), .Y(
        XOR3_78_Y));
    DFN1 DFN1_126 (.D(\PP3[5] ), .CLK(Clock), .Q(DFN1_126_Q));
    AOI1 \AOI1_E[0]  (.A(XOR2_83_Y), .B(OR3_1_Y), .C(AND3_1_Y), .Y(
        \E[0] ));
    XOR2 \XOR2_PP1[10]  (.A(MX2_71_Y), .B(BUFF_14_Y), .Y(\PP1[10] ));
    XOR2 \XOR2_PP3[15]  (.A(MX2_90_Y), .B(BUFF_40_Y), .Y(\PP3[15] ));
    DFN1 DFN1_22 (.D(DFN1_202_Q), .CLK(Clock), .Q(DFN1_22_Q));
    MAJ3 MAJ3_16 (.A(DFN1_61_Q), .B(DFN1_224_Q), .C(DFN1_30_Q), .Y(
        MAJ3_16_Y));
    MX2 \MX2_PP5[16]  (.A(MX2_74_Y), .B(AO1_52_Y), .S(AO16_4_Y), .Y(
        \PP5[16] ));
    AO1 AO1_48 (.A(AND2_125_Y), .B(AO1_38_Y), .C(AO1_17_Y), .Y(
        AO1_48_Y));
    AND2 AND2_205 (.A(AND2_105_Y), .B(AND2_93_Y), .Y(AND2_205_Y));
    XOR2 XOR2_42 (.A(\SumA[13] ), .B(\SumB[13] ), .Y(XOR2_42_Y));
    DFN1 DFN1_10 (.D(MAJ3_25_Y), .CLK(Clock), .Q(DFN1_10_Q));
    AO1 AO1_36 (.A(AND2_177_Y), .B(AO1_0_Y), .C(AO1_18_Y), .Y(AO1_36_Y)
        );
    XOR2 \XOR2_PP5[9]  (.A(MX2_15_Y), .B(BUFF_46_Y), .Y(\PP5[9] ));
    DFN1 DFN1_84 (.D(\PP6[6] ), .CLK(Clock), .Q(DFN1_84_Q));
    XOR2 \XOR2_Mult[21]  (.A(XOR2_19_Y), .B(AO1_15_Y), .Y(Mult[21]));
    AND2 AND2_160 (.A(AND2_151_Y), .B(XOR2_57_Y), .Y(AND2_160_Y));
    XOR3 XOR3_43 (.A(MAJ3_75_Y), .B(DFN1_117_Q), .C(XOR3_17_Y), .Y(
        XOR3_43_Y));
    XOR3 XOR3_63 (.A(DFN1_176_Q), .B(DFN1_38_Q), .C(DFN1_98_Q), .Y(
        XOR3_63_Y));
    DFN1 DFN1_129 (.D(MAJ3_16_Y), .CLK(Clock), .Q(DFN1_129_Q));
    XOR2 XOR2_50 (.A(DFN1_123_Q), .B(DFN1_43_Q), .Y(XOR2_50_Y));
    MX2 MX2_84 (.A(AND2_178_Y), .B(BUFF_1_Y), .S(AND2A_0_Y), .Y(
        MX2_84_Y));
    XOR3 XOR3_49 (.A(DFN1_132_Q), .B(DFN1_5_Q), .C(DFN1_167_Q), .Y(
        XOR3_49_Y));
    XOR2 XOR2_0 (.A(AND2_99_Y), .B(BUFF_39_Y), .Y(XOR2_0_Y));
    XOR2 XOR2_101 (.A(DataB[9]), .B(DataB[10]), .Y(XOR2_101_Y));
    XOR3 XOR3_69 (.A(DFN1_224_Q), .B(DFN1_30_Q), .C(DFN1_61_Q), .Y(
        XOR3_69_Y));
    AO1 AO1_11 (.A(AND2_48_Y), .B(AO1_20_Y), .C(AO1_71_Y), .Y(AO1_11_Y)
        );
    AND2 AND2_94 (.A(AND2_50_Y), .B(XOR2_41_Y), .Y(AND2_94_Y));
    DFN1 DFN1_92 (.D(XOR3_4_Y), .CLK(Clock), .Q(DFN1_92_Q));
    AND2 AND2_222 (.A(AND2_221_Y), .B(AND2_191_Y), .Y(AND2_222_Y));
    MX2 MX2_17 (.A(AND2_126_Y), .B(BUFF_50_Y), .S(AND2A_2_Y), .Y(
        MX2_17_Y));
    AO1 AO1_70 (.A(AND2_35_Y), .B(AO1_20_Y), .C(AO1_50_Y), .Y(AO1_70_Y)
        );
    MX2 MX2_76 (.A(AND2_189_Y), .B(BUFF_17_Y), .S(AO16_6_Y), .Y(
        MX2_76_Y));
    XOR3 XOR3_10 (.A(DFN1_29_Q), .B(DFN1_90_Q), .C(MAJ3_43_Y), .Y(
        XOR3_10_Y));
    AND2 AND2_22 (.A(DFN1_193_Q), .B(DFN1_19_Q), .Y(AND2_22_Y));
    AO1 AO1_63 (.A(AND2_160_Y), .B(AO1_10_Y), .C(AO1_61_Y), .Y(
        AO1_63_Y));
    MAJ3 MAJ3_3 (.A(DFN1_2_Q), .B(DFN1_58_Q), .C(DFN1_172_Q), .Y(
        MAJ3_3_Y));
    XOR2 \XOR2_PP6[12]  (.A(MX2_48_Y), .B(BUFF_41_Y), .Y(\PP6[12] ));
    MX2 MX2_53 (.A(AND2_181_Y), .B(BUFF_2_Y), .S(AO16_11_Y), .Y(
        MX2_53_Y));
    AND2 AND2_39 (.A(\SumA[15] ), .B(\SumB[15] ), .Y(AND2_39_Y));
    XOR2 \XOR2_PP0[1]  (.A(MX2_86_Y), .B(BUFF_28_Y), .Y(\PP0[1] ));
    XOR2 \XOR2_PP4[1]  (.A(MX2_9_Y), .B(BUFF_39_Y), .Y(\PP4[1] ));
    XOR2 \XOR2_PP5[3]  (.A(MX2_98_Y), .B(BUFF_52_Y), .Y(\PP5[3] ));
    MX2 MX2_110 (.A(AND2_182_Y), .B(BUFF_12_Y), .S(AO16_0_Y), .Y(
        MX2_110_Y));
    XOR2 XOR2_46 (.A(DataB[5]), .B(DataB[6]), .Y(XOR2_46_Y));
    MAJ3 MAJ3_41 (.A(DFN1_182_Q), .B(DFN1_196_Q), .C(DFN1_184_Q), .Y(
        MAJ3_41_Y));
    MX2 MX2_66 (.A(AND2_218_Y), .B(BUFF_30_Y), .S(AO16_15_Y), .Y(
        MX2_66_Y));
    AND2 AND2_169 (.A(\SumA[19] ), .B(\SumB[19] ), .Y(AND2_169_Y));
    DFN1 DFN1_235 (.D(\PP3[16] ), .CLK(Clock), .Q(DFN1_235_Q));
    XOR2 \XOR2_Mult[24]  (.A(XOR2_79_Y), .B(AO1_64_Y), .Y(Mult[24]));
    DFN1 \DFN1_SumB[16]  (.D(XOR3_73_Y), .CLK(Clock), .Q(\SumB[16] ));
    MX2 MX2_93 (.A(AND2_11_Y), .B(BUFF_49_Y), .S(AO16_0_Y), .Y(
        MX2_93_Y));
    XOR3 XOR3_47 (.A(DFN1_85_Q), .B(DFN1_114_Q), .C(DFN1_39_Q), .Y(
        XOR3_47_Y));
    MX2 MX2_45 (.A(AND2_106_Y), .B(BUFF_38_Y), .S(AO16_10_Y), .Y(
        MX2_45_Y));
    XOR3 XOR3_67 (.A(AND2_193_Y), .B(DFN1_113_Q), .C(XOR3_61_Y), .Y(
        XOR3_67_Y));
    DFN1 DFN1_177 (.D(MAJ3_58_Y), .CLK(Clock), .Q(DFN1_177_Q));
    DFN1 DFN1_167 (.D(DFN1_145_Q), .CLK(Clock), .Q(DFN1_167_Q));
    DFN1 DFN1_144 (.D(DFN1_52_Q), .CLK(Clock), .Q(DFN1_144_Q));
    DFN1 \DFN1_SumB[10]  (.D(XOR3_32_Y), .CLK(Clock), .Q(\SumB[10] ));
    AO1 AO1_62 (.A(XOR2_89_Y), .B(AND2_14_Y), .C(AND2_9_Y), .Y(
        AO1_62_Y));
    DFN1 DFN1_186 (.D(DFN1_199_Q), .CLK(Clock), .Q(DFN1_186_Q));
    DFN1 DFN1_28 (.D(XOR3_66_Y), .CLK(Clock), .Q(DFN1_28_Q));
    DFN1 DFN1_1 (.D(\S[0] ), .CLK(Clock), .Q(DFN1_1_Q));
    AOI1 \AOI1_E[2]  (.A(XOR2_72_Y), .B(OR3_5_Y), .C(AND3_2_Y), .Y(
        \E[2] ));
    XOR2 \XOR2_Mult[6]  (.A(XOR2_30_Y), .B(AO1_80_Y), .Y(Mult[6]));
    DFN1 DFN1_189 (.D(XOR3_14_Y), .CLK(Clock), .Q(DFN1_189_Q));
    AND2 AND2_195 (.A(\SumA[22] ), .B(\SumB[22] ), .Y(AND2_195_Y));
    DFN1 DFN1_197 (.D(\PP1[11] ), .CLK(Clock), .Q(DFN1_197_Q));
    XOR2 XOR2_103 (.A(\SumA[4] ), .B(\SumB[4] ), .Y(XOR2_103_Y));
    DFN1 DFN1_122 (.D(\PP1[6] ), .CLK(Clock), .Q(DFN1_122_Q));
    BUFF BUFF_17 (.A(DataA[8]), .Y(BUFF_17_Y));
    DFN1 DFN1_120 (.D(DFN1_88_Q), .CLK(Clock), .Q(DFN1_120_Q));
    AND2 AND2_45 (.A(AND2_30_Y), .B(AND2_82_Y), .Y(AND2_45_Y));
    AO1 AO1_75 (.A(XOR2_44_Y), .B(AND2_68_Y), .C(AND2_10_Y), .Y(
        AO1_75_Y));
    DFN1 DFN1_98 (.D(XOR3_1_Y), .CLK(Clock), .Q(DFN1_98_Q));
    MAJ3 MAJ3_2 (.A(MAJ3_50_Y), .B(DFN1_33_Q), .C(DFN1_73_Q), .Y(
        MAJ3_2_Y));
    XOR2 \XOR2_Mult[16]  (.A(XOR2_64_Y), .B(AO1_30_Y), .Y(Mult[16]));
    XOR2 XOR2_21 (.A(DFN1_175_Q), .B(DFN1_101_Q), .Y(XOR2_21_Y));
    AND2 AND2_190 (.A(DFN1_228_Q), .B(DFN1_141_Q), .Y(AND2_190_Y));
    DFN1 DFN1_45 (.D(\PP4[13] ), .CLK(Clock), .Q(DFN1_45_Q));
    XOR2 \XOR2_PP0[2]  (.A(MX2_0_Y), .B(BUFF_28_Y), .Y(\PP0[2] ));
    XOR2 XOR2_31 (.A(\SumA[8] ), .B(\SumB[8] ), .Y(XOR2_31_Y));
    AND2 AND2_172 (.A(DataB[0]), .B(BUFF_43_Y), .Y(AND2_172_Y));
    XOR2 \XOR2_PP6[3]  (.A(MX2_24_Y), .B(BUFF_20_Y), .Y(\PP6[3] ));
    AND2 AND2_128 (.A(XOR2_10_Y), .B(BUFF_48_Y), .Y(AND2_128_Y));
    DFN1 \DFN1_SumA[7]  (.D(MAJ3_1_Y), .CLK(Clock), .Q(\SumA[7] ));
    XOR2 \XOR2_PP0[11]  (.A(MX2_68_Y), .B(BUFF_25_Y), .Y(\PP0[11] ));
    AND2 AND2_65 (.A(XOR2_60_Y), .B(BUFF_50_Y), .Y(AND2_65_Y));
    XOR2 XOR2_14 (.A(DFN1_134_Q), .B(DFN1_203_Q), .Y(XOR2_14_Y));
    AO1 AO1_EBAR (.A(XOR2_83_Y), .B(OR3_1_Y), .C(AND3_1_Y), .Y(EBAR));
    DFN1 \DFN1_SumA[2]  (.D(DFN1_231_Q), .CLK(Clock), .Q(\SumA[2] ));
    BUFF BUFF_27 (.A(DataA[2]), .Y(BUFF_27_Y));
    BUFF BUFF_3 (.A(DataA[4]), .Y(BUFF_3_Y));
    AND2 AND2_30 (.A(XOR2_102_Y), .B(XOR2_65_Y), .Y(AND2_30_Y));
    MX2 MX2_22 (.A(AND2_196_Y), .B(BUFF_17_Y), .S(AO16_13_Y), .Y(
        MX2_22_Y));
    MAJ3 MAJ3_7 (.A(MAJ3_53_Y), .B(AND2_32_Y), .C(DFN1_100_Q), .Y(
        MAJ3_7_Y));
    BUFF BUFF_38 (.A(DataA[5]), .Y(BUFF_38_Y));
    DFN1 DFN1_136 (.D(\PP2[5] ), .CLK(Clock), .Q(DFN1_136_Q));
    AND2 AND2_28 (.A(AND2_30_Y), .B(AND2_82_Y), .Y(AND2_28_Y));
    MAJ3 MAJ3_15 (.A(DFN1_92_Q), .B(DFN1_230_Q), .C(DFN1_177_Q), .Y(
        MAJ3_15_Y));
    XOR2 XOR2_84 (.A(\SumA[4] ), .B(\SumB[4] ), .Y(XOR2_84_Y));
    XOR2 XOR2_53 (.A(\SumA[25] ), .B(\SumB[25] ), .Y(XOR2_53_Y));
    DFN1 DFN1_23 (.D(XOR2_1_Y), .CLK(Clock), .Q(DFN1_23_Q));
    MX2 MX2_51 (.A(AND2_201_Y), .B(BUFF_50_Y), .S(AO16_6_Y), .Y(
        MX2_51_Y));
    XOR2 \XOR2_PP5[11]  (.A(MX2_44_Y), .B(BUFF_46_Y), .Y(\PP5[11] ));
    XOR2 XOR2_4 (.A(\SumA[17] ), .B(\SumB[17] ), .Y(XOR2_4_Y));
    AO16 AO16_16 (.A(DataB[5]), .B(DataB[6]), .C(BUFF_40_Y), .Y(
        AO16_16_Y));
    AO1 AO1_53 (.A(AND2_118_Y), .B(AO1_49_Y), .C(AO1_29_Y), .Y(
        AO1_53_Y));
    XOR2 XOR2_59 (.A(\SumA[6] ), .B(\SumB[6] ), .Y(XOR2_59_Y));
    AND2 AND2_199 (.A(AND2_113_Y), .B(AND2_94_Y), .Y(AND2_199_Y));
    XOR3 XOR3_13 (.A(MAJ3_59_Y), .B(DFN1_211_Q), .C(XOR3_64_Y), .Y(
        XOR3_13_Y));
    DFN1 \DFN1_SumA[11]  (.D(MAJ3_80_Y), .CLK(Clock), .Q(\SumA[11] ));
    XOR2 \XOR2_PP1[9]  (.A(MX2_76_Y), .B(BUFF_14_Y), .Y(\PP1[9] ));
    DFN1 DFN1_139 (.D(XOR3_27_Y), .CLK(Clock), .Q(DFN1_139_Q));
    DFN1 DFN1_105 (.D(\PP3[13] ), .CLK(Clock), .Q(DFN1_105_Q));
    MX2 MX2_13 (.A(AND2_34_Y), .B(BUFF_47_Y), .S(AND2A_0_Y), .Y(
        MX2_13_Y));
    MX2 MX2_91 (.A(AND2_109_Y), .B(BUFF_6_Y), .S(AO16_1_Y), .Y(
        MX2_91_Y));
    AO1 AO1_7 (.A(AND2_13_Y), .B(AO1_32_Y), .C(AO1_35_Y), .Y(AO1_7_Y));
    DFN1 DFN1_60 (.D(DFN1_222_Q), .CLK(Clock), .Q(DFN1_60_Q));
    MX2 MX2_58 (.A(AND2_149_Y), .B(BUFF_30_Y), .S(AO16_14_Y), .Y(
        MX2_58_Y));
    DFN1 DFN1_182 (.D(XOR3_69_Y), .CLK(Clock), .Q(DFN1_182_Q));
    XOR3 XOR3_19 (.A(XOR2_81_Y), .B(DFN1_133_Q), .C(XOR3_9_Y), .Y(
        XOR3_19_Y));
    XOR2 \XOR2_PP5[6]  (.A(MX2_85_Y), .B(BUFF_46_Y), .Y(\PP5[6] ));
    DFN1 DFN1_147 (.D(\PP1[16] ), .CLK(Clock), .Q(DFN1_147_Q));
    DFN1 DFN1_180 (.D(XOR3_0_Y), .CLK(Clock), .Q(DFN1_180_Q));
    XOR2 XOR2_98 (.A(\SumA[11] ), .B(\SumB[11] ), .Y(XOR2_98_Y));
    AND2 AND2_112 (.A(XOR2_46_Y), .B(BUFF_19_Y), .Y(AND2_112_Y));
    DFN1 DFN1_93 (.D(MAJ3_56_Y), .CLK(Clock), .Q(DFN1_93_Q));
    DFN1 DFN1_103 (.D(DFN1_14_Q), .CLK(Clock), .Q(DFN1_103_Q));
    XOR2 \XOR2_PP0[14]  (.A(MX2_39_Y), .B(BUFF_0_Y), .Y(\PP0[14] ));
    DFN1 DFN1_17 (.D(\PP3[12] ), .CLK(Clock), .Q(DFN1_17_Q));
    DFN1 DFN1_16 (.D(\PP2[16] ), .CLK(Clock), .Q(DFN1_16_Q));
    MX2 MX2_77 (.A(AND2_43_Y), .B(BUFF_42_Y), .S(AO16_0_Y), .Y(
        MX2_77_Y));
    AND2 AND2_105 (.A(AND2_44_Y), .B(AND2_51_Y), .Y(AND2_105_Y));
    DFN1 DFN1_50 (.D(\PP2[1] ), .CLK(Clock), .Q(DFN1_50_Q));
    AND2 AND2_52 (.A(AND2_29_Y), .B(AND2_206_Y), .Y(AND2_52_Y));
    MX2 MX2_98 (.A(AND2_198_Y), .B(BUFF_27_Y), .S(AO16_7_Y), .Y(
        MX2_98_Y));
    AO1 AO1_52 (.A(XOR2_63_Y), .B(OR3_3_Y), .C(AND3_5_Y), .Y(AO1_52_Y));
    MAJ3 MAJ3_36 (.A(XOR3_2_Y), .B(MAJ3_48_Y), .C(DFN1_59_Q), .Y(
        MAJ3_36_Y));
    MX2 MX2_80 (.A(AND2_65_Y), .B(BUFF_43_Y), .S(AO16_15_Y), .Y(
        MX2_80_Y));
    XOR2 XOR2_57 (.A(\SumA[14] ), .B(\SumB[14] ), .Y(XOR2_57_Y));
    AO1 AO1_41 (.A(AND2_211_Y), .B(AO1_14_Y), .C(AO1_25_Y), .Y(
        AO1_41_Y));
    DFN1 DFN1_202 (.D(\PP3[0] ), .CLK(Clock), .Q(DFN1_202_Q));
    OR3 OR3_3 (.A(DataB[9]), .B(DataB[10]), .C(DataB[11]), .Y(OR3_3_Y));
    AND2 AND2_1 (.A(AND2_224_Y), .B(AND2_151_Y), .Y(AND2_1_Y));
    XOR2 \XOR2_PP4[12]  (.A(MX2_83_Y), .B(BUFF_7_Y), .Y(\PP4[12] ));
    MX2 MX2_67 (.A(BUFF_41_Y), .B(XOR2_32_Y), .S(XOR2_39_Y), .Y(
        MX2_67_Y));
    AND2 AND2_7 (.A(DFN1_11_Q), .B(DFN1_164_Q), .Y(AND2_7_Y));
    MAJ3 MAJ3_13 (.A(XOR3_17_Y), .B(MAJ3_75_Y), .C(DFN1_117_Q), .Y(
        MAJ3_13_Y));
    XOR2 \XOR2_PP5[14]  (.A(MX2_35_Y), .B(BUFF_24_Y), .Y(\PP5[14] ));
    AND2 AND2_204 (.A(XOR2_13_Y), .B(BUFF_2_Y), .Y(AND2_204_Y));
    XOR3 XOR3_17 (.A(DFN1_44_Q), .B(DFN1_62_Q), .C(DFN1_171_Q), .Y(
        XOR3_17_Y));
    MAJ3 MAJ3_47 (.A(XOR3_24_Y), .B(MAJ3_57_Y), .C(DFN1_9_Q), .Y(
        MAJ3_47_Y));
    XOR2 \XOR2_PP3[1]  (.A(MX2_107_Y), .B(BUFF_15_Y), .Y(\PP3[1] ));
    XOR2 \XOR2_PP0[6]  (.A(MX2_17_Y), .B(BUFF_25_Y), .Y(\PP0[6] ));
    AND2 AND2_100 (.A(XOR2_101_Y), .B(BUFF_3_Y), .Y(AND2_100_Y));
    DFN1 DFN1_19 (.D(\PP3[11] ), .CLK(Clock), .Q(DFN1_19_Q));
    DFN1 DFN1_214 (.D(MAJ3_46_Y), .CLK(Clock), .Q(DFN1_214_Q));
    XOR2 XOR2_15 (.A(\SumA[10] ), .B(\SumB[10] ), .Y(XOR2_15_Y));
    AND2 AND2_43 (.A(XOR2_27_Y), .B(BUFF_12_Y), .Y(AND2_43_Y));
    MAJ3 MAJ3_6 (.A(DFN1_212_Q), .B(DFN1_10_Q), .C(DFN1_96_Q), .Y(
        MAJ3_6_Y));
    AND2 AND2_223 (.A(XOR2_28_Y), .B(BUFF_49_Y), .Y(AND2_223_Y));
    AO1 AO1_67 (.A(AND2_151_Y), .B(AO1_10_Y), .C(AO1_0_Y), .Y(AO1_67_Y)
        );
    BUFF BUFF_5 (.A(DataB[7]), .Y(BUFF_5_Y));
    AND2 AND2_217 (.A(XOR2_8_Y), .B(XOR2_51_Y), .Y(AND2_217_Y));
    MX2 MX2_29 (.A(AND2_111_Y), .B(BUFF_23_Y), .S(AO16_15_Y), .Y(
        MX2_29_Y));
    MAJ3 MAJ3_5 (.A(XOR3_25_Y), .B(XOR2_2_Y), .C(DFN1_84_Q), .Y(
        MAJ3_5_Y));
    AO16 AO16_14 (.A(DataB[3]), .B(DataB[4]), .C(BUFF_36_Y), .Y(
        AO16_14_Y));
    DFN1 \DFN1_SumB[24]  (.D(XOR3_43_Y), .CLK(Clock), .Q(\SumB[24] ));
    XOR2 XOR2_85 (.A(\SumA[9] ), .B(\SumB[9] ), .Y(XOR2_85_Y));
    MX2 MX2_4 (.A(AND2_8_Y), .B(BUFF_47_Y), .S(AO16_16_Y), .Y(MX2_4_Y));
    AND2 AND2_188 (.A(AND2_30_Y), .B(XOR2_96_Y), .Y(AND2_188_Y));
    AND2 AND2_144 (.A(AND2_5_Y), .B(AND2_38_Y), .Y(AND2_144_Y));
    XOR2 \XOR2_Mult[23]  (.A(XOR2_6_Y), .B(AO1_72_Y), .Y(Mult[23]));
    AND2 AND2_162 (.A(XOR2_94_Y), .B(XOR2_53_Y), .Y(AND2_162_Y));
    AND3 AND3_4 (.A(DataB[5]), .B(DataB[6]), .C(DataB[7]), .Y(AND3_4_Y)
        );
    DFN1 DFN1_6 (.D(\PP6[1] ), .CLK(Clock), .Q(DFN1_6_Q));
    XOR2 \XOR2_PP2[2]  (.A(MX2_101_Y), .B(BUFF_36_Y), .Y(\PP2[2] ));
    AND2 AND2_231 (.A(XOR2_29_Y), .B(BUFF_45_Y), .Y(AND2_231_Y));
    AND2 AND2_216 (.A(XOR2_82_Y), .B(BUFF_23_Y), .Y(AND2_216_Y));
    AND2 AND2_63 (.A(XOR2_10_Y), .B(BUFF_17_Y), .Y(AND2_63_Y));
    XOR2 \XOR2_PP1[0]  (.A(XOR2_91_Y), .B(DataB[3]), .Y(\PP1[0] ));
    DFN1 DFN1_132 (.D(DFN1_79_Q), .CLK(Clock), .Q(DFN1_132_Q));
    BUFF BUFF_19 (.A(DataA[13]), .Y(BUFF_19_Y));
    AO1 AO1_68 (.A(XOR2_69_Y), .B(AND2_154_Y), .C(AND2_85_Y), .Y(
        AO1_68_Y));
    DFN1 DFN1_130 (.D(\PP2[9] ), .CLK(Clock), .Q(DFN1_130_Q));
    AND2 AND2_109 (.A(XOR2_35_Y), .B(BUFF_3_Y), .Y(AND2_109_Y));
    MAJ3 MAJ3_10 (.A(MAJ3_62_Y), .B(AND2_96_Y), .C(DFN1_69_Q), .Y(
        MAJ3_10_Y));
    DFN1 \DFN1_SumA[16]  (.D(MAJ3_12_Y), .CLK(Clock), .Q(\SumA[16] ));
    DFN1 DFN1_5 (.D(DFN1_121_Q), .CLK(Clock), .Q(DFN1_5_Q));
    AO16 AO16_17 (.A(DataB[1]), .B(DataB[2]), .C(BUFF_21_Y), .Y(
        AO16_17_Y));
    AND2 AND2_123 (.A(XOR2_29_Y), .B(BUFF_2_Y), .Y(AND2_123_Y));
    DFN1 \DFN1_SumA[8]  (.D(MAJ3_32_Y), .CLK(Clock), .Q(\SumA[8] ));
    MAJ3 MAJ3_26 (.A(XOR3_74_Y), .B(MAJ3_70_Y), .C(DFN1_40_Q), .Y(
        MAJ3_26_Y));
    XOR3 XOR3_41 (.A(DFN1_201_Q), .B(DFN1_81_Q), .C(DFN1_138_Q), .Y(
        XOR3_41_Y));
    MX2 MX2_32 (.A(AND2_152_Y), .B(BUFF_26_Y), .S(AND2A_0_Y), .Y(
        MX2_32_Y));
    XOR3 XOR3_61 (.A(DFN1_16_Q), .B(VCC), .C(DFN1_163_Q), .Y(XOR3_61_Y)
        );
    DFN1 \DFN1_SumA[10]  (.D(MAJ3_73_Y), .CLK(Clock), .Q(\SumA[10] ));
    AND2 AND2_141 (.A(XOR2_35_Y), .B(BUFF_27_Y), .Y(AND2_141_Y));
    AOI1 \AOI1_E[4]  (.A(XOR2_67_Y), .B(OR3_6_Y), .C(AND3_0_Y), .Y(
        \E[4] ));
    MX2 MX2_104 (.A(AND2_210_Y), .B(BUFF_11_Y), .S(AO16_7_Y), .Y(
        MX2_104_Y));
    AO1 AO1_74 (.A(AND2_205_Y), .B(AO1_46_Y), .C(AO1_23_Y), .Y(
        AO1_74_Y));
    AND2 AND2_95 (.A(XOR2_35_Y), .B(BUFF_38_Y), .Y(AND2_95_Y));
    AND3 AND3_1 (.A(GND), .B(DataB[0]), .C(DataB[1]), .Y(AND3_1_Y));
    XOR2 XOR2_22 (.A(\SumA[25] ), .B(\SumB[25] ), .Y(XOR2_22_Y));
    MX2 MX2_86 (.A(AND2_25_Y), .B(BUFF_31_Y), .S(AND2A_1_Y), .Y(
        MX2_86_Y));
    MX2 MX2_11 (.A(AND2_101_Y), .B(BUFF_2_Y), .S(AO16_3_Y), .Y(
        MX2_11_Y));
    AND2 AND2_27 (.A(XOR2_75_Y), .B(BUFF_8_Y), .Y(AND2_27_Y));
    MAJ3 MAJ3_49 (.A(DFN1_138_Q), .B(DFN1_201_Q), .C(DFN1_81_Q), .Y(
        MAJ3_49_Y));
    DFN1 DFN1_42 (.D(DFN1_206_Q), .CLK(Clock), .Q(DFN1_42_Q));
    BUFF BUFF_29 (.A(DataA[2]), .Y(BUFF_29_Y));
    XOR2 XOR2_32 (.A(BUFF_45_Y), .B(DataB[13]), .Y(XOR2_32_Y));
    MAJ3 MAJ3_48 (.A(DFN1_139_Q), .B(DFN1_214_Q), .C(DFN1_137_Q), .Y(
        MAJ3_48_Y));
    AO16 AO16_13 (.A(DataB[3]), .B(DataB[4]), .C(BUFF_32_Y), .Y(
        AO16_13_Y));
    AND2 AND2_14 (.A(\SumA[2] ), .B(\SumB[2] ), .Y(AND2_14_Y));
    MAJ3 MAJ3_76 (.A(DFN1_167_Q), .B(DFN1_132_Q), .C(DFN1_5_Q), .Y(
        MAJ3_76_Y));
    XOR2 \XOR2_Mult[20]  (.A(XOR2_92_Y), .B(AO1_34_Y), .Y(Mult[20]));
    XOR2 \XOR2_PP6[1]  (.A(MX2_79_Y), .B(BUFF_20_Y), .Y(\PP6[1] ));
    AND2 AND2_74 (.A(XOR2_33_Y), .B(BUFF_38_Y), .Y(AND2_74_Y));
    DFN1 DFN1_14 (.D(\PP1[4] ), .CLK(Clock), .Q(DFN1_14_Q));
    AND2 AND2_82 (.A(XOR2_96_Y), .B(XOR2_89_Y), .Y(AND2_82_Y));
    AND2 AND2_58 (.A(AND2_118_Y), .B(XOR2_16_Y), .Y(AND2_58_Y));
    XOR2 XOR2_10 (.A(DataB[1]), .B(DataB[2]), .Y(XOR2_10_Y));
    MX2 MX2_18 (.A(AND2_202_Y), .B(BUFF_10_Y), .S(AO16_6_Y), .Y(
        MX2_18_Y));
    DFN1 DFN1_218 (.D(\PP5[7] ), .CLK(Clock), .Q(DFN1_218_Q));
    XOR3 XOR3_28 (.A(AND2_72_Y), .B(DFN1_157_Q), .C(MAJ3_60_Y), .Y(
        XOR3_28_Y));
    DFN1 DFN1_201 (.D(AND2_62_Y), .CLK(Clock), .Q(DFN1_201_Q));
    XOR2 \XOR2_PP3[6]  (.A(MX2_52_Y), .B(BUFF_5_Y), .Y(\PP3[6] ));
    AO1 AO1_20 (.A(AND2_211_Y), .B(AO1_14_Y), .C(AO1_25_Y), .Y(
        AO1_20_Y));
    DFN1 DFN1_213 (.D(\PP1[7] ), .CLK(Clock), .Q(DFN1_213_Q));
    DFN1 DFN1_70 (.D(\PP0[14] ), .CLK(Clock), .Q(DFN1_70_Q));
    XOR2 \XOR2_PP1[13]  (.A(MX2_12_Y), .B(BUFF_44_Y), .Y(\PP1[13] ));
    XOR3 XOR3_38 (.A(DFN1_103_Q), .B(DFN1_110_Q), .C(DFN1_186_Q), .Y(
        XOR3_38_Y));
    XOR2 XOR2_80 (.A(\SumA[27] ), .B(\SumB[27] ), .Y(XOR2_80_Y));
    DFN1 DFN1_108 (.D(XOR3_10_Y), .CLK(Clock), .Q(DFN1_108_Q));
    XOR2 \XOR2_Mult[22]  (.A(XOR2_61_Y), .B(AO1_37_Y), .Y(Mult[22]));
    MX2 MX2_73 (.A(AND2_59_Y), .B(BUFF_33_Y), .S(AO16_11_Y), .Y(
        MX2_73_Y));
    AND2 \AND2_S[4]  (.A(XOR2_0_Y), .B(DataB[9]), .Y(\S[4] ));
    XOR2 XOR2_26 (.A(\SumA[21] ), .B(\SumB[21] ), .Y(XOR2_26_Y));
    AO1 AO1_79 (.A(XOR2_94_Y), .B(AO1_50_Y), .C(AND2_16_Y), .Y(
        AO1_79_Y));
    AND2 AND2_212 (.A(XOR2_100_Y), .B(BUFF_1_Y), .Y(AND2_212_Y));
    XOR2 \XOR2_PP2[1]  (.A(MX2_40_Y), .B(BUFF_36_Y), .Y(\PP2[1] ));
    XOR2 XOR2_36 (.A(\SumA[28] ), .B(\SumB[28] ), .Y(XOR2_36_Y));
    MX2 MX2_44 (.A(AND2_145_Y), .B(BUFF_12_Y), .S(AO16_5_Y), .Y(
        MX2_44_Y));
    AND2 AND2_21 (.A(AND2_162_Y), .B(AND2_84_Y), .Y(AND2_21_Y));
    BUFF BUFF_34 (.A(DataA[13]), .Y(BUFF_34_Y));
    MAJ3 MAJ3_35 (.A(DFN1_170_Q), .B(DFN1_42_Q), .C(DFN1_60_Q), .Y(
        MAJ3_35_Y));
    XOR2 \XOR2_PP2[10]  (.A(MX2_105_Y), .B(BUFF_32_Y), .Y(\PP2[10] ));
    AO1 AO1_57 (.A(XOR2_96_Y), .B(AO1_55_Y), .C(AND2_14_Y), .Y(
        AO1_57_Y));
    MX2 MX2_63 (.A(AND2_146_Y), .B(BUFF_13_Y), .S(AND2A_2_Y), .Y(
        MX2_63_Y));
    DFN1 DFN1_175 (.D(\PP1[9] ), .CLK(Clock), .Q(DFN1_175_Q));
    MX2 MX2_39 (.A(AND2_103_Y), .B(BUFF_19_Y), .S(AND2A_0_Y), .Y(
        MX2_39_Y));
    MX2 MX2_101 (.A(AND2_67_Y), .B(BUFF_23_Y), .S(AO16_14_Y), .Y(
        MX2_101_Y));
    DFN1 DFN1_165 (.D(DFN1_50_Q), .CLK(Clock), .Q(DFN1_165_Q));
    AND2 AND2_192 (.A(AND2_221_Y), .B(AND2_227_Y), .Y(AND2_192_Y));
    XOR3 XOR3_54 (.A(MAJ3_70_Y), .B(DFN1_40_Q), .C(XOR3_74_Y), .Y(
        XOR3_54_Y));
    DFN1 DFN1_67 (.D(XOR3_11_Y), .CLK(Clock), .Q(DFN1_67_Q));
    AND2 AND2_3 (.A(\SumA[20] ), .B(\SumB[20] ), .Y(AND2_3_Y));
    XOR2 \XOR2_PP1[6]  (.A(MX2_51_Y), .B(BUFF_14_Y), .Y(\PP1[6] ));
    DFN1 DFN1_66 (.D(\PP3[8] ), .CLK(Clock), .Q(DFN1_66_Q));
    AND2 \AND2_S[6]  (.A(XOR2_3_Y), .B(DataB[13]), .Y(\S[6] ));
    AND2 AND2_220 (.A(\SumA[10] ), .B(\SumB[10] ), .Y(AND2_220_Y));
    DFN1 DFN1_173 (.D(\PP0[3] ), .CLK(Clock), .Q(DFN1_173_Q));
    DFN1 \DFN1_SumB[7]  (.D(XOR3_36_Y), .CLK(Clock), .Q(\SumB[7] ));
    XOR2 XOR2_102 (.A(\SumA[0] ), .B(\SumB[0] ), .Y(XOR2_102_Y));
    DFN1 DFN1_111 (.D(DFN1_48_Q), .CLK(Clock), .Q(DFN1_111_Q));
    DFN1 DFN1_48 (.D(\PP6[15] ), .CLK(Clock), .Q(DFN1_48_Q));
    DFN1 DFN1_163 (.D(\PP3[14] ), .CLK(Clock), .Q(DFN1_163_Q));
    DFN1 \DFN1_SumB[14]  (.D(XOR3_53_Y), .CLK(Clock), .Q(\SumB[14] ));
    DFN1 DFN1_57 (.D(DFN1_161_Q), .CLK(Clock), .Q(DFN1_57_Q));
    AND2 AND2_183 (.A(XOR2_90_Y), .B(BUFF_51_Y), .Y(AND2_183_Y));
    DFN1 DFN1_56 (.D(XOR3_40_Y), .CLK(Clock), .Q(DFN1_56_Q));
    MAJ3 MAJ3_66 (.A(XOR3_80_Y), .B(MAJ3_29_Y), .C(DFN1_78_Q), .Y(
        MAJ3_66_Y));
    AND2 AND2_178 (.A(DataB[0]), .B(BUFF_51_Y), .Y(AND2_178_Y));
    MAJ3 MAJ3_56 (.A(AND2_209_Y), .B(DFN1_127_Q), .C(DFN1_49_Q), .Y(
        MAJ3_56_Y));
    AO1 AO1_58 (.A(AND2_1_Y), .B(AO1_32_Y), .C(AO1_67_Y), .Y(AO1_58_Y));
    XOR2 \XOR2_PP3[4]  (.A(MX2_66_Y), .B(BUFF_15_Y), .Y(\PP3[4] ));
    AO1 AO1_25 (.A(AND2_83_Y), .B(AO1_10_Y), .C(AO1_36_Y), .Y(AO1_25_Y)
        );
    DFN1 DFN1_220 (.D(\PP4[4] ), .CLK(Clock), .Q(DFN1_220_Q));
    DFN1 DFN1_195 (.D(\PP3[9] ), .CLK(Clock), .Q(DFN1_195_Q));
    DFN1 \DFN1_SumB[27]  (.D(MAJ3_23_Y), .CLK(Clock), .Q(\SumB[27] ));
    XOR2 XOR2_78 (.A(AND2_133_Y), .B(BUFF_52_Y), .Y(XOR2_78_Y));
    DFN1 DFN1_7 (.D(\PP6[16] ), .CLK(Clock), .Q(DFN1_7_Q));
    DFN1 DFN1_69 (.D(\PP5[9] ), .CLK(Clock), .Q(DFN1_69_Q));
    DFN1 DFN1_193 (.D(\PP4[9] ), .CLK(Clock), .Q(DFN1_193_Q));
    DFN1 \DFN1_SumB[22]  (.D(XOR3_70_Y), .CLK(Clock), .Q(\SumB[22] ));
    AND2 AND2_93 (.A(AND2_162_Y), .B(XOR2_5_Y), .Y(AND2_93_Y));
    DFN1 \DFN1_SumB[19]  (.D(XOR3_18_Y), .CLK(Clock), .Q(\SumB[19] ));
    AND2A AND2A_0 (.A(DataB[0]), .B(BUFF_0_Y), .Y(AND2A_0_Y));
    DFN1 DFN1_59 (.D(XOR3_46_Y), .CLK(Clock), .Q(DFN1_59_Q));
    XOR3 XOR3_74 (.A(DFN1_10_Q), .B(DFN1_96_Q), .C(DFN1_212_Q), .Y(
        XOR3_74_Y));
    XOR2 XOR2_51 (.A(\SumA[19] ), .B(\SumB[19] ), .Y(XOR2_51_Y));
    AND2 AND2_26 (.A(AND2_158_Y), .B(AND2_217_Y), .Y(AND2_26_Y));
    XOR3 XOR3_9 (.A(DFN1_109_Q), .B(DFN1_70_Q), .C(DFN1_227_Q), .Y(
        XOR3_9_Y));
    MAJ3 MAJ3_33 (.A(DFN1_21_Q), .B(DFN1_179_Q), .C(DFN1_23_Q), .Y(
        MAJ3_33_Y));
    DFN1 DFN1_35 (.D(\PP4[8] ), .CLK(Clock), .Q(DFN1_35_Q));
    XOR2 XOR2_104 (.A(\SumA[11] ), .B(\SumB[11] ), .Y(XOR2_104_Y));
    AND2 AND2_88 (.A(DataB[0]), .B(BUFF_17_Y), .Y(AND2_88_Y));
    MAJ3 MAJ3_25 (.A(MAJ3_22_Y), .B(DFN1_55_Q), .C(DFN1_233_Q), .Y(
        MAJ3_25_Y));
    AND2 AND2_228 (.A(XOR2_35_Y), .B(BUFF_6_Y), .Y(AND2_228_Y));
    XOR2 \XOR2_PP4[8]  (.A(MX2_93_Y), .B(BUFF_35_Y), .Y(\PP4[8] ));
    DFN1 \DFN1_SumA[9]  (.D(MAJ3_47_Y), .CLK(Clock), .Q(\SumA[9] ));
    XOR3 XOR3_11 (.A(DFN1_75_Q), .B(DFN1_158_Q), .C(DFN1_159_Q), .Y(
        XOR3_11_Y));
    AND2 \AND2_S[0]  (.A(XOR2_55_Y), .B(DataB[1]), .Y(\S[0] ));
    AO16 AO16_8 (.A(DataB[11]), .B(DataB[12]), .C(BUFF_20_Y), .Y(
        AO16_8_Y));
    MX2 MX2_109 (.A(AND2_141_Y), .B(BUFF_37_Y), .S(AO16_1_Y), .Y(
        MX2_109_Y));
    XOR3 XOR3_42 (.A(MAJ3_11_Y), .B(DFN1_67_Q), .C(XOR3_52_Y), .Y(
        XOR3_42_Y));
    DFN1 DFN1_85 (.D(\PP1[13] ), .CLK(Clock), .Q(DFN1_85_Q));
    XOR3 XOR3_62 (.A(DFN1_214_Q), .B(DFN1_137_Q), .C(DFN1_139_Q), .Y(
        XOR3_62_Y));
    AND2 AND2_118 (.A(XOR2_74_Y), .B(XOR2_26_Y), .Y(AND2_118_Y));
    XOR2 XOR2_13 (.A(DataB[7]), .B(DataB[8]), .Y(XOR2_13_Y));
    DFN1 DFN1_43 (.D(\PP0[7] ), .CLK(Clock), .Q(DFN1_43_Q));
    XOR2 XOR2_2 (.A(DFN1_53_Q), .B(DFN1_17_Q), .Y(XOR2_2_Y));
    MX2 MX2_87 (.A(AND2_88_Y), .B(BUFF_8_Y), .S(AND2A_2_Y), .Y(
        MX2_87_Y));
    XOR3 XOR3_55 (.A(DFN1_213_Q), .B(DFN1_142_Q), .C(DFN1_136_Q), .Y(
        XOR3_55_Y));
    BUFF BUFF_42 (.A(DataA[9]), .Y(BUFF_42_Y));
    XOR2 \XOR2_Mult[19]  (.A(XOR2_73_Y), .B(AO1_45_Y), .Y(Mult[19]));
    AND2 AND2_57 (.A(XOR2_33_Y), .B(BUFF_3_Y), .Y(AND2_57_Y));
    MX2 MX2_71 (.A(AND2_128_Y), .B(BUFF_13_Y), .S(AO16_6_Y), .Y(
        MX2_71_Y));
    MAJ3 MAJ3_75 (.A(DFN1_174_Q), .B(DFN1_232_Q), .C(DFN1_146_Q), .Y(
        MAJ3_75_Y));
    DFN1 \DFN1_SumB[2]  (.D(XOR2_38_Y), .CLK(Clock), .Q(\SumB[2] ));
    AND2 AND2_34 (.A(DataB[0]), .B(BUFF_26_Y), .Y(AND2_34_Y));
    XOR2 XOR2_3 (.A(AND2_90_Y), .B(BUFF_20_Y), .Y(XOR2_3_Y));
    DFN1 DFN1_215 (.D(\PP5[8] ), .CLK(Clock), .Q(DFN1_215_Q));
    XOR2 XOR2_19 (.A(\SumA[20] ), .B(\SumB[20] ), .Y(XOR2_19_Y));
    AND2 AND2_102 (.A(AND2_113_Y), .B(AND2_24_Y), .Y(AND2_102_Y));
    AO1 AO1_2 (.A(AND2_38_Y), .B(AO1_46_Y), .C(AO1_48_Y), .Y(AO1_2_Y));
    XOR2 \XOR2_PP3[7]  (.A(MX2_97_Y), .B(BUFF_5_Y), .Y(\PP3[7] ));
    XOR2 XOR2_83 (.A(BUFF_51_Y), .B(DataB[1]), .Y(XOR2_83_Y));
    MAJ3 MAJ3_30 (.A(MAJ3_43_Y), .B(DFN1_29_Q), .C(DFN1_90_Q), .Y(
        MAJ3_30_Y));
    XOR2 \XOR2_Mult[27]  (.A(XOR2_18_Y), .B(AO1_11_Y), .Y(Mult[27]));
    AO1 AO1_61 (.A(XOR2_57_Y), .B(AO1_0_Y), .C(AND2_229_Y), .Y(
        AO1_61_Y));
    DFN1 DFN1_227 (.D(\PP2[10] ), .CLK(Clock), .Q(DFN1_227_Q));
    XOR2 XOR2_68 (.A(\SumA[27] ), .B(\SumB[27] ), .Y(XOR2_68_Y));
    MX2 MX2_61 (.A(AND2_223_Y), .B(BUFF_16_Y), .S(AO16_5_Y), .Y(
        MX2_61_Y));
    XOR2 \XOR2_PP0[4]  (.A(MX2_75_Y), .B(BUFF_28_Y), .Y(\PP0[4] ));
    MX2 MX2_78 (.A(AND2_104_Y), .B(BUFF_43_Y), .S(AND2A_1_Y), .Y(
        MX2_78_Y));
    DFN1 DFN1_145 (.D(\S[3] ), .CLK(Clock), .Q(DFN1_145_Q));
    XOR2 XOR2_89 (.A(\SumA[3] ), .B(\SumB[3] ), .Y(XOR2_89_Y));
    XOR2 \XOR2_PP3[10]  (.A(MX2_57_Y), .B(BUFF_5_Y), .Y(\PP3[10] ));
    XOR2 \XOR2_PP1[8]  (.A(MX2_56_Y), .B(BUFF_14_Y), .Y(\PP1[8] ));
    DFN1 DFN1_64 (.D(MAJ3_52_Y), .CLK(Clock), .Q(DFN1_64_Q));
    BUFF BUFF_9 (.A(DataB[13]), .Y(BUFF_9_Y));
    MAJ3 MAJ3_23 (.A(AND2_197_Y), .B(DFN1_111_Q), .C(DFN1_120_Q), .Y(
        MAJ3_23_Y));
    AO1 AO1_33 (.A(AND2_121_Y), .B(AO1_78_Y), .C(AO1_54_Y), .Y(
        AO1_33_Y));
    BUFF BUFF_35 (.A(DataB[9]), .Y(BUFF_35_Y));
    XOR2 \XOR2_PP3[9]  (.A(MX2_59_Y), .B(BUFF_5_Y), .Y(\PP3[9] ));
    DFN1 DFN1_143 (.D(\PP5[4] ), .CLK(Clock), .Q(DFN1_143_Q));
    AND2 AND2_126 (.A(DataB[0]), .B(BUFF_10_Y), .Y(AND2_126_Y));
    DFN1 \DFN1_Mult[0]  (.D(DFN1_37_Q), .CLK(Clock), .Q(Mult[0]));
    DFN1 \DFN1_SumA[28]  (.D(DFN1_57_Q), .CLK(Clock), .Q(\SumA[28] ));
    BUFF BUFF_30 (.A(DataA[3]), .Y(BUFF_30_Y));
    XOR3 XOR3_46 (.A(DFN1_55_Q), .B(DFN1_233_Q), .C(MAJ3_22_Y), .Y(
        XOR3_46_Y));
    XOR2 \XOR2_PP6[11]  (.A(MX2_38_Y), .B(BUFF_9_Y), .Y(\PP6[11] ));
    XOR3 XOR3_66 (.A(DFN1_102_Q), .B(DFN1_26_Q), .C(DFN1_20_Q), .Y(
        XOR3_66_Y));
    MX2 MX2_68 (.A(AND2_77_Y), .B(BUFF_48_Y), .S(AND2A_2_Y), .Y(
        MX2_68_Y));
    MX2 MX2_25 (.A(BUFF_40_Y), .B(XOR2_54_Y), .S(XOR2_46_Y), .Y(
        MX2_25_Y));
    DFN1 DFN1_54 (.D(\PP6[12] ), .CLK(Clock), .Q(DFN1_54_Q));
    XOR2 XOR2_17 (.A(DFN1_11_Q), .B(DFN1_164_Q), .Y(XOR2_17_Y));
    XOR3 XOR3_75 (.A(MAJ3_48_Y), .B(DFN1_59_Q), .C(XOR3_2_Y), .Y(
        XOR3_75_Y));
    DFN1 DFN1_154 (.D(\PP4[15] ), .CLK(Clock), .Q(DFN1_154_Q));
    AND2 AND2_207 (.A(XOR2_33_Y), .B(BUFF_6_Y), .Y(AND2_207_Y));
    XOR2 \XOR2_PP0[15]  (.A(MX2_84_Y), .B(BUFF_0_Y), .Y(\PP0[15] ));
    AND2 AND2_154 (.A(\SumA[4] ), .B(\SumB[4] ), .Y(AND2_154_Y));
    DFN1 DFN1_77 (.D(\PP3[2] ), .CLK(Clock), .Q(DFN1_77_Q));
    AND2 AND2_145 (.A(XOR2_28_Y), .B(BUFF_18_Y), .Y(AND2_145_Y));
    AND2 AND2_168 (.A(XOR2_13_Y), .B(BUFF_33_Y), .Y(AND2_168_Y));
    AND2 AND2_51 (.A(AND2_118_Y), .B(AND2_226_Y), .Y(AND2_51_Y));
    DFN1 DFN1_226 (.D(\E[0] ), .CLK(Clock), .Q(DFN1_226_Q));
    AO1 AO1_10 (.A(AND2_121_Y), .B(AO1_78_Y), .C(AO1_54_Y), .Y(
        AO1_10_Y));
    DFN1 DFN1_76 (.D(MAJ3_9_Y), .CLK(Clock), .Q(DFN1_76_Q));
    DFN1 DFN1_0 (.D(DFN1_1_Q), .CLK(Clock), .Q(DFN1_0_Q));
    OR3 OR3_1 (.A(GND), .B(DataB[0]), .C(DataB[1]), .Y(OR3_1_Y));
    XOR2 XOR2_87 (.A(DFN1_193_Q), .B(DFN1_19_Q), .Y(XOR2_87_Y));
    AO1 AO1_32 (.A(AND2_52_Y), .B(AO1_21_Y), .C(AO1_81_Y), .Y(AO1_32_Y)
        );
    XOR2 \XOR2_PP5[8]  (.A(MX2_33_Y), .B(BUFF_46_Y), .Y(\PP5[8] ));
    MAJ3 MAJ3_73 (.A(XOR3_52_Y), .B(MAJ3_11_Y), .C(DFN1_67_Q), .Y(
        MAJ3_73_Y));
    DFN1 DFN1_178 (.D(\PP6[10] ), .CLK(Clock), .Q(DFN1_178_Q));
    XOR2 \XOR2_PP6[7]  (.A(MX2_95_Y), .B(BUFF_9_Y), .Y(\PP6[7] ));
    AO1 AO1_76 (.A(AND2_50_Y), .B(AO1_42_Y), .C(AO1_78_Y), .Y(AO1_76_Y)
        );
    DFN1 DFN1_168 (.D(XOR2_50_Y), .CLK(Clock), .Q(DFN1_168_Q));
    DFN1 \DFN1_SumB[23]  (.D(XOR3_44_Y), .CLK(Clock), .Q(\SumB[23] ));
    BUFF BUFF_1 (.A(DataA[14]), .Y(BUFF_1_Y));
    MAJ3 MAJ3_14 (.A(XOR3_61_Y), .B(AND2_193_Y), .C(DFN1_113_Q), .Y(
        MAJ3_14_Y));
    AND2 AND2_173 (.A(XOR2_82_Y), .B(BUFF_50_Y), .Y(AND2_173_Y));
    AND2 AND2_29 (.A(XOR2_84_Y), .B(XOR2_69_Y), .Y(AND2_29_Y));
    AND2 AND2_206 (.A(XOR2_59_Y), .B(XOR2_47_Y), .Y(AND2_206_Y));
    BUFF BUFF_18 (.A(DataA[11]), .Y(BUFF_18_Y));
    XOR2 \XOR2_PP5[15]  (.A(MX2_14_Y), .B(BUFF_24_Y), .Y(\PP5[15] ));
    DFN1 \DFN1_SumB[17]  (.D(XOR3_13_Y), .CLK(Clock), .Q(\SumB[17] ));
    MX2 MX2_40 (.A(AND2_116_Y), .B(BUFF_31_Y), .S(AO16_14_Y), .Y(
        MX2_40_Y));
    AND2 AND2_140 (.A(AND2_208_Y), .B(AND2_184_Y), .Y(AND2_140_Y));
    XOR2 \XOR2_PP1[5]  (.A(MX2_108_Y), .B(BUFF_21_Y), .Y(\PP1[5] ));
    MAJ3 MAJ3_20 (.A(XOR3_48_Y), .B(XOR2_20_Y), .C(DFN1_82_Q), .Y(
        MAJ3_20_Y));
    MAJ3 MAJ3_65 (.A(DFN1_186_Q), .B(DFN1_103_Q), .C(DFN1_110_Q), .Y(
        MAJ3_65_Y));
    AND2 AND2_151 (.A(XOR2_93_Y), .B(XOR2_42_Y), .Y(AND2_151_Y));
    MAJ3 MAJ3_55 (.A(DFN1_156_Q), .B(DFN1_235_Q), .C(VCC), .Y(
        MAJ3_55_Y));
    XOR3 XOR3_50 (.A(DFN1_41_Q), .B(DFN1_34_Q), .C(DFN1_183_Q), .Y(
        XOR3_50_Y));
    AND2 AND2_213 (.A(DFN1_217_Q), .B(DFN1_153_Q), .Y(AND2_213_Y));
    DFN1 \DFN1_SumA[0]  (.D(DFN1_72_Q), .CLK(Clock), .Q(\SumA[0] ));
    DFN1 DFN1_79 (.D(\PP3[1] ), .CLK(Clock), .Q(DFN1_79_Q));
    MX2 MX2_108 (.A(AND2_173_Y), .B(BUFF_43_Y), .S(AO16_17_Y), .Y(
        MX2_108_Y));
    XOR2 \XOR2_PP6[14]  (.A(MX2_23_Y), .B(BUFF_41_Y), .Y(\PP6[14] ));
    DFN1 \DFN1_SumB[12]  (.D(XOR3_75_Y), .CLK(Clock), .Q(\SumB[12] ));
    DFN1 DFN1_230 (.D(MAJ3_51_Y), .CLK(Clock), .Q(DFN1_230_Q));
    XOR2 \XOR2_PP1[3]  (.A(MX2_47_Y), .B(BUFF_21_Y), .Y(\PP1[3] ));
    XOR2 \XOR2_PP2[5]  (.A(MX2_27_Y), .B(BUFF_36_Y), .Y(\PP2[5] ));
    DFN1 DFN1_198 (.D(\PP0[5] ), .CLK(Clock), .Q(DFN1_198_Q));
    DFN1 DFN1_116 (.D(DFN1_80_Q), .CLK(Clock), .Q(DFN1_116_Q));
    XOR2 \XOR2_PP2[7]  (.A(MX2_100_Y), .B(BUFF_32_Y), .Y(\PP2[7] ));
    DFN1 DFN1_21 (.D(MAJ3_44_Y), .CLK(Clock), .Q(DFN1_21_Q));
    BUFF BUFF_2 (.A(DataA[12]), .Y(BUFF_2_Y));
    AND2 AND2_15 (.A(XOR2_39_Y), .B(BUFF_2_Y), .Y(AND2_15_Y));
    AND2 AND2_87 (.A(AND2_215_Y), .B(AND2_1_Y), .Y(AND2_87_Y));
    BUFF BUFF_28 (.A(DataB[1]), .Y(BUFF_28_Y));
    DFN1 \DFN1_SumB[25]  (.D(XOR3_72_Y), .CLK(Clock), .Q(\SumB[25] ));
    XOR2 \XOR2_PP4[4]  (.A(MX2_91_Y), .B(BUFF_39_Y), .Y(\PP4[4] ));
    AND2 AND2_75 (.A(DataB[0]), .B(BUFF_30_Y), .Y(AND2_75_Y));
    AND2 AND2_127 (.A(XOR2_46_Y), .B(BUFF_1_Y), .Y(AND2_127_Y));
    AO1 AO1_24 (.A(XOR2_76_Y), .B(AO1_56_Y), .C(AND2_68_Y), .Y(
        AO1_24_Y));
    BUFF BUFF_0 (.A(DataB[1]), .Y(BUFF_0_Y));
    MAJ3 MAJ3_70 (.A(DFN1_155_Q), .B(DFN1_93_Q), .C(DFN1_86_Q), .Y(
        MAJ3_70_Y));
    AO16 AO16_3 (.A(DataB[11]), .B(DataB[12]), .C(BUFF_41_Y), .Y(
        AO16_3_Y));
    AND2 AND2_56 (.A(XOR2_9_Y), .B(BUFF_18_Y), .Y(AND2_56_Y));
    DFN1 DFN1_119 (.D(\PP2[15] ), .CLK(Clock), .Q(DFN1_119_Q));
    BUFF BUFF_50 (.A(DataA[5]), .Y(BUFF_50_Y));
    XOR2 \XOR2_PP2[9]  (.A(MX2_22_Y), .B(BUFF_32_Y), .Y(\PP2[9] ));
    AND2 AND2_149 (.A(XOR2_71_Y), .B(BUFF_43_Y), .Y(AND2_149_Y));
    XOR2 \XOR2_PP1[12]  (.A(MX2_3_Y), .B(BUFF_44_Y), .Y(\PP1[12] ));
    AND2 AND2_113 (.A(AND2_45_Y), .B(AND2_52_Y), .Y(AND2_113_Y));
    XOR2 XOR2_52 (.A(DFN1_228_Q), .B(DFN1_141_Q), .Y(XOR2_52_Y));
    DFN1 \DFN1_SumA[14]  (.D(MAJ3_26_Y), .CLK(Clock), .Q(\SumA[14] ));
    AO1 AO1_15 (.A(AND2_26_Y), .B(AO1_41_Y), .C(AO1_49_Y), .Y(AO1_15_Y)
        );
    DFN1 DFN1_32 (.D(MAJ3_17_Y), .CLK(Clock), .Q(DFN1_32_Q));
    DFN1 DFN1_91 (.D(DFN1_77_Q), .CLK(Clock), .Q(DFN1_91_Q));
    XOR3 XOR3_70 (.A(MAJ3_33_Y), .B(DFN1_97_Q), .C(XOR3_41_Y), .Y(
        XOR3_70_Y));
    MX2 MX2_83 (.A(AND2_204_Y), .B(BUFF_18_Y), .S(AO16_11_Y), .Y(
        MX2_83_Y));
    AO1 AO1_51 (.A(XOR2_16_Y), .B(AO1_29_Y), .C(AND2_195_Y), .Y(
        AO1_51_Y));
    XOR3 XOR3_12 (.A(DFN1_33_Q), .B(DFN1_73_Q), .C(MAJ3_50_Y), .Y(
        XOR3_12_Y));
    BUFF BUFF_46 (.A(DataB[11]), .Y(BUFF_46_Y));
    MAJ3 MAJ3_63 (.A(DFN1_130_Q), .B(DFN1_197_Q), .C(DFN1_216_Q), .Y(
        MAJ3_63_Y));
    XOR3 XOR3_4 (.A(XOR2_86_Y), .B(DFN1_169_Q), .C(XOR3_47_Y), .Y(
        XOR3_4_Y));
    AND2 AND2_186 (.A(XOR2_27_Y), .B(BUFF_42_Y), .Y(AND2_186_Y));
    MAJ3 MAJ3_53 (.A(DFN1_39_Q), .B(DFN1_85_Q), .C(DFN1_114_Q), .Y(
        MAJ3_53_Y));
    XOR3 XOR3_6 (.A(MAJ3_29_Y), .B(DFN1_78_Q), .C(XOR3_80_Y), .Y(
        XOR3_6_Y));
    XOR2 XOR2_94 (.A(\SumA[24] ), .B(\SumB[24] ), .Y(XOR2_94_Y));
    AO1 AO1_81 (.A(AND2_206_Y), .B(AO1_68_Y), .C(AO1_12_Y), .Y(
        AO1_81_Y));
    DFN1 DFN1_82 (.D(\PP6[7] ), .CLK(Clock), .Q(DFN1_82_Q));
    DFN1 DFN1_157 (.D(\PP5[5] ), .CLK(Clock), .Q(DFN1_157_Q));
    AOI1 \AOI1_E[6]  (.A(XOR2_32_Y), .B(OR3_0_Y), .C(AND3_3_Y), .Y(
        \E[6] ));
    DFN1 \DFN1_SumA[19]  (.D(MAJ3_34_Y), .CLK(Clock), .Q(\SumA[19] ));
    AND2 AND2_202 (.A(XOR2_10_Y), .B(BUFF_8_Y), .Y(AND2_202_Y));
    AND2 AND2_81 (.A(XOR2_9_Y), .B(BUFF_12_Y), .Y(AND2_81_Y));
    AND2 AND2_198 (.A(XOR2_101_Y), .B(BUFF_6_Y), .Y(AND2_198_Y));
    MX2 MX2_46 (.A(BUFF_0_Y), .B(XOR2_83_Y), .S(DataB[0]), .Y(MX2_46_Y)
        );
    AND2 AND2_20 (.A(XOR2_9_Y), .B(BUFF_49_Y), .Y(AND2_20_Y));
    AND2 AND2_134 (.A(XOR2_100_Y), .B(BUFF_51_Y), .Y(AND2_134_Y));
    DFN1 DFN1_74 (.D(MAJ3_38_Y), .CLK(Clock), .Q(DFN1_74_Q));
    MX2 MX2_35 (.A(AND2_122_Y), .B(BUFF_34_Y), .S(AO16_4_Y), .Y(
        MX2_35_Y));
    AO1 AO1_29 (.A(XOR2_26_Y), .B(AND2_3_Y), .C(AND2_175_Y), .Y(
        AO1_29_Y));
    AO16 AO16_5 (.A(DataB[9]), .B(DataB[10]), .C(BUFF_46_Y), .Y(
        AO16_5_Y));
    XOR2 XOR2_56 (.A(\SumA[16] ), .B(\SumB[16] ), .Y(XOR2_56_Y));
    DFN1 DFN1_148 (.D(\PP1[15] ), .CLK(Clock), .Q(DFN1_148_Q));
    DFN1 DFN1_204 (.D(VCC), .CLK(Clock), .Q(DFN1_204_Q));
    DFN1 \DFN1_SumB[1]  (.D(DFN1_229_Q), .CLK(Clock), .Q(\SumB[1] ));
    AND2 AND2_163 (.A(DFN1_134_Q), .B(DFN1_203_Q), .Y(AND2_163_Y));
    MAJ3 MAJ3_4 (.A(XOR2_21_Y), .B(DFN1_208_Q), .C(DFN1_126_Q), .Y(
        MAJ3_4_Y));
    XOR3 XOR3_16 (.A(DFN1_197_Q), .B(DFN1_216_Q), .C(DFN1_130_Q), .Y(
        XOR3_16_Y));
    MAJ3 MAJ3_60 (.A(DFN1_227_Q), .B(DFN1_109_Q), .C(DFN1_70_Q), .Y(
        MAJ3_60_Y));
    XOR2 \XOR2_PP2[0]  (.A(XOR2_34_Y), .B(DataB[5]), .Y(\PP2[0] ));
    MAJ3 MAJ3_50 (.A(DFN1_163_Q), .B(DFN1_16_Q), .C(VCC), .Y(MAJ3_50_Y)
        );
    AO16 AO16_0 (.A(DataB[7]), .B(DataB[8]), .C(BUFF_35_Y), .Y(
        AO16_0_Y));
    AO1 AO1_1 (.A(AND2_21_Y), .B(AO1_38_Y), .C(AO1_19_Y), .Y(AO1_1_Y));
    AND2 AND2_131 (.A(\SumA[6] ), .B(\SumB[6] ), .Y(AND2_131_Y));
    XOR2 \XOR2_PP4[11]  (.A(MX2_110_Y), .B(BUFF_35_Y), .Y(\PP4[11] ));
    DFN1 \DFN1_SumB[13]  (.D(XOR3_54_Y), .CLK(Clock), .Q(\SumB[13] ));
    DFN1 DFN1_112 (.D(XOR3_71_Y), .CLK(Clock), .Q(DFN1_112_Q));
    DFN1 DFN1_38 (.D(MAJ3_5_Y), .CLK(Clock), .Q(DFN1_38_Q));
    DFN1 DFN1_110 (.D(DFN1_27_Q), .CLK(Clock), .Q(DFN1_110_Q));
    DFN1 DFN1_236 (.D(\S[1] ), .CLK(Clock), .Q(DFN1_236_Q));
    DFN1 DFN1_124 (.D(\S[4] ), .CLK(Clock), .Q(DFN1_124_Q));
    AO1 AO1_37 (.A(AND2_73_Y), .B(AO1_41_Y), .C(AO1_5_Y), .Y(AO1_37_Y));
    XOR2 XOR2_100 (.A(DataB[1]), .B(DataB[2]), .Y(XOR2_100_Y));
    XOR3 XOR3_53 (.A(MAJ3_6_Y), .B(DFN1_223_Q), .C(XOR3_57_Y), .Y(
        XOR3_53_Y));
    MX2 MX2_2 (.A(AND2_186_Y), .B(BUFF_22_Y), .S(AO16_0_Y), .Y(MX2_2_Y)
        );
    XOR2 \XOR2_PP4[9]  (.A(MX2_2_Y), .B(BUFF_35_Y), .Y(\PP4[9] ));
    AND2 AND2_187 (.A(DFN1_35_Q), .B(DFN1_149_Q), .Y(AND2_187_Y));
    XOR2 \XOR2_PP2[13]  (.A(MX2_26_Y), .B(BUFF_4_Y), .Y(\PP2[13] ));
    AND2 AND2_13 (.A(AND2_24_Y), .B(XOR2_93_Y), .Y(AND2_13_Y));
    AND2 AND2_210 (.A(XOR2_101_Y), .B(BUFF_37_Y), .Y(AND2_210_Y));
    AND2 AND2_86 (.A(\SumA[26] ), .B(\SumB[26] ), .Y(AND2_86_Y));
    AND2 AND2_73 (.A(AND2_26_Y), .B(XOR2_74_Y), .Y(AND2_73_Y));
    AND2 AND2_59 (.A(XOR2_13_Y), .B(BUFF_45_Y), .Y(AND2_59_Y));
    XOR3 XOR3_59 (.A(DFN1_111_Q), .B(DFN1_120_Q), .C(AND2_197_Y), .Y(
        XOR3_59_Y));
    DFN1 DFN1_88 (.D(\E[5] ), .CLK(Clock), .Q(DFN1_88_Q));
    AO1 AO1_40 (.A(AND2_227_Y), .B(AO1_20_Y), .C(AO1_79_Y), .Y(
        AO1_40_Y));
    XOR2 XOR2_95 (.A(\SumA[24] ), .B(\SumB[24] ), .Y(XOR2_95_Y));
    AO16 AO16_9 (.A(DataB[5]), .B(DataB[6]), .C(BUFF_5_Y), .Y(AO16_9_Y)
        );
    DFN1 \DFN1_SumB[15]  (.D(XOR3_76_Y), .CLK(Clock), .Q(\SumB[15] ));
    AO1 AO1_38 (.A(AND2_51_Y), .B(AO1_26_Y), .C(AO1_3_Y), .Y(AO1_38_Y));
    AO1 AO1_9 (.A(AND2_89_Y), .B(AO1_46_Y), .C(AO1_1_Y), .Y(AO1_9_Y));
    XOR2 XOR2_11 (.A(\SumA[2] ), .B(\SumB[2] ), .Y(XOR2_11_Y));
    MX2 MX2_81 (.A(AND2_228_Y), .B(BUFF_27_Y), .S(AO16_1_Y), .Y(
        MX2_81_Y));
    MX2 MX2_52 (.A(AND2_179_Y), .B(BUFF_50_Y), .S(AO16_9_Y), .Y(
        MX2_52_Y));
    XOR2 \XOR2_PP4[14]  (.A(MX2_96_Y), .B(BUFF_7_Y), .Y(\PP4[14] ));
    AND2 AND2_35 (.A(AND2_44_Y), .B(AND2_51_Y), .Y(AND2_35_Y));
    AND2 AND2_108 (.A(XOR2_101_Y), .B(BUFF_27_Y), .Y(AND2_108_Y));
    XOR2 XOR2_48 (.A(AND2_129_Y), .B(BUFF_15_Y), .Y(XOR2_48_Y));
    AO16 AO16_12 (.A(DataB[1]), .B(DataB[2]), .C(BUFF_44_Y), .Y(
        AO16_12_Y));
    XOR2 \XOR2_PP3[3]  (.A(MX2_28_Y), .B(BUFF_15_Y), .Y(\PP3[3] ));
    MAJ3 MAJ3_34 (.A(XOR3_63_Y), .B(MAJ3_37_Y), .C(DFN1_190_Q), .Y(
        MAJ3_34_Y));
    XOR3 XOR3_57 (.A(DFN1_230_Q), .B(DFN1_177_Q), .C(DFN1_92_Q), .Y(
        XOR3_57_Y));
    MX2 MX2_92 (.A(AND2_166_Y), .B(BUFF_49_Y), .S(AO16_10_Y), .Y(
        MX2_92_Y));
    XOR2 XOR2_81 (.A(DFN1_71_Q), .B(DFN1_66_Q), .Y(XOR2_81_Y));
    XOR3 XOR3_73 (.A(MAJ3_40_Y), .B(DFN1_63_Q), .C(XOR3_7_Y), .Y(
        XOR3_73_Y));
    XOR2 \XOR2_PP3[8]  (.A(MX2_88_Y), .B(BUFF_5_Y), .Y(\PP3[8] ));
    AOI1 \AOI1_E[1]  (.A(XOR2_45_Y), .B(OR3_2_Y), .C(AND3_6_Y), .Y(
        \E[1] ));
    DFN1 DFN1_229 (.D(DFN1_192_Q), .CLK(Clock), .Q(DFN1_229_Q));
    DFN1 DFN1_208 (.D(\PP5[1] ), .CLK(Clock), .Q(DFN1_208_Q));
    XOR2 \XOR2_PP0[3]  (.A(MX2_30_Y), .B(BUFF_28_Y), .Y(\PP0[3] ));
    MX2 MX2_88 (.A(AND2_132_Y), .B(BUFF_8_Y), .S(AO16_9_Y), .Y(
        MX2_88_Y));
    BUFF BUFF_14 (.A(DataB[3]), .Y(BUFF_14_Y));
    XOR3 XOR3_24 (.A(DFN1_4_Q), .B(DFN1_83_Q), .C(DFN1_76_Q), .Y(
        XOR3_24_Y));
    AND2 AND2_218 (.A(XOR2_60_Y), .B(BUFF_43_Y), .Y(AND2_218_Y));
    DFN1 \DFN1_SumA[17]  (.D(MAJ3_71_Y), .CLK(Clock), .Q(\SumA[17] ));
    DFN1 DFN1_15 (.D(\E[1] ), .CLK(Clock), .Q(DFN1_15_Q));
    XOR3 XOR3_79 (.A(DFN1_185_Q), .B(DFN1_64_Q), .C(DFN1_99_Q), .Y(
        XOR3_79_Y));
    DFN1 DFN1_203 (.D(DFN1_198_Q), .CLK(Clock), .Q(DFN1_203_Q));
    AO16 AO16_11 (.A(DataB[7]), .B(DataB[8]), .C(BUFF_7_Y), .Y(
        AO16_11_Y));
    DFN1 DFN1_33 (.D(\PP5[11] ), .CLK(Clock), .Q(DFN1_33_Q));
    XOR2 XOR2_5 (.A(\SumA[26] ), .B(\SumB[26] ), .Y(XOR2_5_Y));
    AND2 AND2_176 (.A(AND2_28_Y), .B(XOR2_84_Y), .Y(AND2_176_Y));
    MAJ3 MAJ3_8 (.A(XOR3_30_Y), .B(DFN1_24_Q), .C(DFN1_220_Q), .Y(
        MAJ3_8_Y));
    XOR2 \XOR2_PP4[6]  (.A(MX2_62_Y), .B(BUFF_35_Y), .Y(\PP4[6] ));
    XOR2 \XOR2_PP0[8]  (.A(MX2_87_Y), .B(BUFF_25_Y), .Y(\PP0[8] ));
    XOR3 XOR3_34 (.A(XOR2_43_Y), .B(DFN1_6_Q), .C(XOR3_16_Y), .Y(
        XOR3_34_Y));
    DFN1 DFN1_184 (.D(AND2_7_Y), .CLK(Clock), .Q(DFN1_184_Q));
    DFN1 \DFN1_SumA[12]  (.D(MAJ3_28_Y), .CLK(Clock), .Q(\SumA[12] ));
    XOR2 \XOR2_Mult[25]  (.A(XOR2_95_Y), .B(AO1_70_Y), .Y(Mult[25]));
    AND2 AND2_193 (.A(DFN1_207_Q), .B(DFN1_105_Q), .Y(AND2_193_Y));
    XOR3 XOR3_1 (.A(XOR2_20_Y), .B(DFN1_82_Q), .C(XOR3_48_Y), .Y(
        XOR3_1_Y));
    AO1 AO1_14 (.A(AND2_52_Y), .B(AO1_21_Y), .C(AO1_81_Y), .Y(AO1_14_Y)
        );
    XOR3 XOR3_80 (.A(DFN1_58_Q), .B(DFN1_172_Q), .C(DFN1_2_Q), .Y(
        XOR3_80_Y));
    MX2 MX2_103 (.A(AND2_112_Y), .B(BUFF_26_Y), .S(AO16_16_Y), .Y(
        MX2_103_Y));
    AO1 AO1_45 (.A(AND2_158_Y), .B(AO1_56_Y), .C(AO1_75_Y), .Y(
        AO1_45_Y));
    DFN1 DFN1_83 (.D(DFN1_124_Q), .CLK(Clock), .Q(DFN1_83_Q));
    AND2 AND2_155 (.A(XOR2_75_Y), .B(BUFF_10_Y), .Y(AND2_155_Y));
    BUFF BUFF_24 (.A(DataB[11]), .Y(BUFF_24_Y));
    AND2 AND2_142 (.A(AND2_113_Y), .B(AND2_50_Y), .Y(AND2_142_Y));
    XOR3 XOR3_77 (.A(DFN1_116_Q), .B(DFN1_165_Q), .C(XOR2_14_Y), .Y(
        XOR3_77_Y));
    XOR2 \XOR2_PP0[7]  (.A(MX2_8_Y), .B(BUFF_25_Y), .Y(\PP0[7] ));
    MX2 MX2_47 (.A(AND2_69_Y), .B(BUFF_29_Y), .S(AO16_17_Y), .Y(
        MX2_47_Y));
    XOR2 XOR2_90 (.A(DataB[3]), .B(DataB[4]), .Y(XOR2_90_Y));
    AND2 AND2_50 (.A(XOR2_31_Y), .B(XOR2_24_Y), .Y(AND2_50_Y));
    XOR2 \XOR2_Mult[1]  (.A(\SumA[0] ), .B(\SumB[0] ), .Y(Mult[1]));
    DFN1 DFN1_127 (.D(\PP5[2] ), .CLK(Clock), .Q(DFN1_127_Q));
    MX2 MX2_24 (.A(AND2_207_Y), .B(BUFF_27_Y), .S(AO16_8_Y), .Y(
        MX2_24_Y));
    DFN1 DFN1_101 (.D(\PP0[11] ), .CLK(Clock), .Q(DFN1_101_Q));
    AO16 AO16_6 (.A(DataB[1]), .B(DataB[2]), .C(BUFF_14_Y), .Y(
        AO16_6_Y));
    AND2 AND2_150 (.A(XOR2_9_Y), .B(BUFF_42_Y), .Y(AND2_150_Y));
    MX2 MX2_59 (.A(AND2_23_Y), .B(BUFF_17_Y), .S(AO16_9_Y), .Y(
        MX2_59_Y));
    MAJ3 MAJ3_24 (.A(DFN1_51_Q), .B(DFN1_154_Q), .C(DFN1_200_Q), .Y(
        MAJ3_24_Y));
    AND2 AND2_89 (.A(AND2_105_Y), .B(AND2_21_Y), .Y(AND2_89_Y));
    AND2 AND2_116 (.A(XOR2_71_Y), .B(BUFF_23_Y), .Y(AND2_116_Y));
    XOR2 \XOR2_PP3[13]  (.A(MX2_103_Y), .B(BUFF_40_Y), .Y(\PP3[13] ));
    MAJ3 MAJ3_46 (.A(DFN1_20_Q), .B(DFN1_102_Q), .C(DFN1_26_Q), .Y(
        MAJ3_46_Y));
    MX2 MX2_3 (.A(AND2_18_Y), .B(BUFF_47_Y), .S(AO16_12_Y), .Y(MX2_3_Y)
        );
    AO1 AO1_26 (.A(AND2_217_Y), .B(AO1_75_Y), .C(AO1_6_Y), .Y(AO1_26_Y)
        );
    MX2 MX2_99 (.A(AND2_194_Y), .B(BUFF_3_Y), .S(AO16_7_Y), .Y(
        MX2_99_Y));
    AND2 AND2_203 (.A(XOR2_10_Y), .B(BUFF_47_Y), .Y(AND2_203_Y));
    XOR2 XOR2_74 (.A(\SumA[20] ), .B(\SumB[20] ), .Y(XOR2_74_Y));
    AO1 AO1_19 (.A(AND2_84_Y), .B(AO1_59_Y), .C(AO1_31_Y), .Y(AO1_19_Y)
        );
    AND2 AND2_177 (.A(XOR2_57_Y), .B(XOR2_23_Y), .Y(AND2_177_Y));
    XOR3 XOR3_25 (.A(DFN1_147_Q), .B(DFN1_140_Q), .C(DFN1_209_Q), .Y(
        XOR3_25_Y));
    DFN1 DFN1_134 (.D(DFN1_65_Q), .CLK(Clock), .Q(DFN1_134_Q));
    AND2 AND2_42 (.A(XOR2_82_Y), .B(BUFF_29_Y), .Y(AND2_42_Y));
    MAJ3 MAJ3_74 (.A(DFN1_183_Q), .B(DFN1_41_Q), .C(DFN1_34_Q), .Y(
        MAJ3_74_Y));
    AND2 AND2_33 (.A(DFN1_8_Q), .B(VCC), .Y(AND2_33_Y));
    XOR3 XOR3_35 (.A(AND2_96_Y), .B(DFN1_69_Q), .C(MAJ3_62_Y), .Y(
        XOR3_35_Y));
    AO1 AO1_4 (.A(XOR2_67_Y), .B(OR3_6_Y), .C(AND3_0_Y), .Y(AO1_4_Y));
    AND2 AND2_159 (.A(AND2_208_Y), .B(AND2_26_Y), .Y(AND2_159_Y));
    MX2 MX2_12 (.A(AND2_110_Y), .B(BUFF_26_Y), .S(AO16_12_Y), .Y(
        MX2_12_Y));
    AND2 AND2_2 (.A(XOR2_90_Y), .B(BUFF_26_Y), .Y(AND2_2_Y));
    MX2 MX2_102 (.A(AND2_2_Y), .B(BUFF_47_Y), .S(AO16_2_Y), .Y(
        MX2_102_Y));
    DFN1 DFN1_41 (.D(\PP1[14] ), .CLK(Clock), .Q(DFN1_41_Q));
    AND2 AND2_221 (.A(AND2_225_Y), .B(AND2_211_Y), .Y(AND2_221_Y));
    BUFF BUFF_43 (.A(DataA[4]), .Y(BUFF_43_Y));
    AND2 AND2_62 (.A(DFN1_178_Q), .B(DFN1_191_Q), .Y(AND2_62_Y));
    BUFF BUFF_41 (.A(DataB[13]), .Y(BUFF_41_Y));
    AND2 AND2_103 (.A(DataB[0]), .B(BUFF_1_Y), .Y(AND2_103_Y));
    XOR2 \XOR2_PP5[0]  (.A(XOR2_78_Y), .B(DataB[11]), .Y(\PP5[0] ));
    XOR2 \XOR2_PP6[15]  (.A(MX2_5_Y), .B(BUFF_41_Y), .Y(\PP6[15] ));
    AND3 AND3_2 (.A(DataB[3]), .B(DataB[4]), .C(DataB[5]), .Y(AND3_2_Y)
        );
    DFN1 DFN1_187 (.D(\PP0[0] ), .CLK(Clock), .Q(DFN1_187_Q));
    AND2 AND2_166 (.A(XOR2_9_Y), .B(BUFF_22_Y), .Y(AND2_166_Y));
    MX2 MX2_111 (.A(AND2_183_Y), .B(BUFF_1_Y), .S(AO16_2_Y), .Y(
        MX2_111_Y));
    DFN1 \DFN1_SumA[13]  (.D(MAJ3_36_Y), .CLK(Clock), .Q(\SumA[13] ));
    BUFF BUFF_15 (.A(DataB[7]), .Y(BUFF_15_Y));
    DFN1 \DFN1_SumB[6]  (.D(XOR3_15_Y), .CLK(Clock), .Q(\SumB[6] ));
    BUFF BUFF_10 (.A(DataA[6]), .Y(BUFF_10_Y));
    XOR2 XOR2_12 (.A(\SumA[13] ), .B(\SumB[13] ), .Y(XOR2_12_Y));
    DFN1 DFN1_205 (.D(\PP5[14] ), .CLK(Clock), .Q(DFN1_205_Q));
    AND2 AND2_117 (.A(XOR2_46_Y), .B(BUFF_51_Y), .Y(AND2_117_Y));
    AND2 AND2_229 (.A(\SumA[14] ), .B(\SumB[14] ), .Y(AND2_229_Y));
    AND2 AND2_135 (.A(XOR2_28_Y), .B(BUFF_16_Y), .Y(AND2_135_Y));
    XOR2 XOR2_64 (.A(\SumA[15] ), .B(\SumB[15] ), .Y(XOR2_64_Y));
    AND2 AND2_80 (.A(AND2_5_Y), .B(AND2_89_Y), .Y(AND2_80_Y));
    XOR2 XOR2_82 (.A(DataB[1]), .B(DataB[2]), .Y(XOR2_82_Y));
    AO16 AO16_2 (.A(DataB[3]), .B(DataB[4]), .C(BUFF_4_Y), .Y(AO16_2_Y)
        );
    XOR2 XOR2_75 (.A(DataB[3]), .B(DataB[4]), .Y(XOR2_75_Y));
    XOR2 \XOR2_Mult[5]  (.A(XOR2_103_Y), .B(AO1_43_Y), .Y(Mult[5]));
    BUFF BUFF_25 (.A(DataB[1]), .Y(BUFF_25_Y));
    DFN1 DFN1_12 (.D(\E[4] ), .CLK(Clock), .Q(DFN1_12_Q));
    BUFF BUFF_20 (.A(DataB[13]), .Y(BUFF_20_Y));
    DFN1 DFN1_155 (.D(XOR3_34_Y), .CLK(Clock), .Q(DFN1_155_Q));
    DFN1 \DFN1_SumA[15]  (.D(MAJ3_61_Y), .CLK(Clock), .Q(\SumA[15] ));
    MAJ3 MAJ3_64 (.A(XOR3_31_Y), .B(MAJ3_49_Y), .C(DFN1_46_Q), .Y(
        MAJ3_64_Y));
    XOR3 XOR3_20 (.A(AND2_187_Y), .B(DFN1_218_Q), .C(MAJ3_74_Y), .Y(
        XOR3_20_Y));
    MAJ3 MAJ3_54 (.A(XOR3_8_Y), .B(MAJ3_78_Y), .C(DFN1_108_Q), .Y(
        MAJ3_54_Y));
    MAJ3 MAJ3_12 (.A(XOR3_79_Y), .B(MAJ3_15_Y), .C(DFN1_180_Q), .Y(
        MAJ3_12_Y));
    AND2 AND2_130 (.A(XOR2_75_Y), .B(BUFF_17_Y), .Y(AND2_130_Y));
    DFN1 DFN1_65 (.D(\PP1[3] ), .CLK(Clock), .Q(DFN1_65_Q));
    MX2 MX2_34 (.A(AND2_150_Y), .B(BUFF_22_Y), .S(AO16_10_Y), .Y(
        MX2_34_Y));
    AO1 AO1_31 (.A(XOR2_80_Y), .B(AND2_86_Y), .C(AND2_37_Y), .Y(
        AO1_31_Y));
    XOR2 \XOR2_Mult[7]  (.A(XOR2_49_Y), .B(AO1_44_Y), .Y(Mult[7]));
    XOR2 XOR2_93 (.A(\SumA[12] ), .B(\SumB[12] ), .Y(XOR2_93_Y));
    DFN1 DFN1_153 (.D(\PP3[7] ), .CLK(Clock), .Q(DFN1_153_Q));
    MX2 MX2_19 (.A(BUFF_4_Y), .B(XOR2_72_Y), .S(XOR2_90_Y), .Y(
        MX2_19_Y));
    MX2 MX2_43 (.A(AND2_216_Y), .B(BUFF_31_Y), .S(AO16_17_Y), .Y(
        MX2_43_Y));
    XOR3 XOR3_30 (.A(DFN1_95_Q), .B(DFN1_219_Q), .C(DFN1_131_Q), .Y(
        XOR3_30_Y));
    XOR2 XOR2_16 (.A(\SumA[22] ), .B(\SumB[22] ), .Y(XOR2_16_Y));
    DFN1 DFN1_55 (.D(\S[6] ), .CLK(Clock), .Q(DFN1_55_Q));
    XOR2 XOR2_99 (.A(DataB[5]), .B(DataB[6]), .Y(XOR2_99_Y));
    XOR2 \XOR2_PP4[2]  (.A(MX2_109_Y), .B(BUFF_39_Y), .Y(\PP4[2] ));
    XOR3 XOR3_51 (.A(XOR2_2_Y), .B(DFN1_84_Q), .C(XOR3_25_Y), .Y(
        XOR3_51_Y));
    AND2 AND2_24 (.A(AND2_50_Y), .B(AND2_121_Y), .Y(AND2_24_Y));
    XOR2 \XOR2_PP2[12]  (.A(MX2_102_Y), .B(BUFF_4_Y), .Y(\PP2[12] ));
    AND2 AND2_48 (.A(AND2_35_Y), .B(AND2_162_Y), .Y(AND2_48_Y));
    XOR2 \XOR2_Mult[26]  (.A(XOR2_22_Y), .B(AO1_40_Y), .Y(Mult[26]));
    DFN1 DFN1_137 (.D(MAJ3_4_Y), .CLK(Clock), .Q(DFN1_137_Q));
    AO1 AO1_44 (.A(AND2_29_Y), .B(AO1_43_Y), .C(AO1_68_Y), .Y(AO1_44_Y)
        );
    XOR2 XOR2_86 (.A(DFN1_115_Q), .B(DFN1_195_Q), .Y(XOR2_86_Y));
    AND2 AND2_167 (.A(XOR2_71_Y), .B(BUFF_50_Y), .Y(AND2_167_Y));
    XOR2 \XOR2_Mult[18]  (.A(XOR2_4_Y), .B(AO1_24_Y), .Y(Mult[18]));
    DFN1 \DFN1_SumA[6]  (.D(MAJ3_27_Y), .CLK(Clock), .Q(\SumA[6] ));
    DFN1 DFN1_210 (.D(\E[2] ), .CLK(Clock), .Q(DFN1_210_Q));
    AO1 AO1_60 (.A(XOR2_8_Y), .B(AO1_75_Y), .C(AND2_46_Y), .Y(AO1_60_Y)
        );
    AND2 AND2_200 (.A(AND2_221_Y), .B(AND2_48_Y), .Y(AND2_200_Y));
    AND2 AND2_139 (.A(DFN1_123_Q), .B(DFN1_43_Q), .Y(AND2_139_Y));
    MAJ3 MAJ3_45 (.A(MAJ3_0_Y), .B(XOR2_7_Y), .C(DFN1_166_Q), .Y(
        MAJ3_45_Y));
    DFN1 \DFN1_SumA[21]  (.D(MAJ3_66_Y), .CLK(Clock), .Q(\SumA[21] ));
    MX2 MX2_20 (.A(AND2_57_Y), .B(BUFF_6_Y), .S(AO16_8_Y), .Y(MX2_20_Y)
        );
    XOR2 XOR2_97 (.A(\SumA[7] ), .B(\SumB[7] ), .Y(XOR2_97_Y));
    AND2 AND2_68 (.A(\SumA[16] ), .B(\SumB[16] ), .Y(AND2_68_Y));
    DFN1 DFN1_106 (.D(\PP5[15] ), .CLK(Clock), .Q(DFN1_106_Q));
    DFN1 DFN1_171 (.D(DFN1_87_Q), .CLK(Clock), .Q(DFN1_171_Q));
    DFN1 DFN1_20 (.D(\S[5] ), .CLK(Clock), .Q(DFN1_20_Q));
    AND2 AND2_196 (.A(XOR2_75_Y), .B(BUFF_13_Y), .Y(AND2_196_Y));
    DFN1 DFN1_161 (.D(\E[6] ), .CLK(Clock), .Q(DFN1_161_Q));
    XOR2 XOR2_65 (.A(\SumA[1] ), .B(\SumB[1] ), .Y(XOR2_65_Y));
    XOR2 \XOR2_PP6[0]  (.A(XOR2_3_Y), .B(DataB[13]), .Y(\PP6[0] ));
    MX2 \MX2_PP2[16]  (.A(MX2_19_Y), .B(AO1_16_Y), .S(AO16_2_Y), .Y(
        \PP2[16] ));
    XOR2 \XOR2_PP0[10]  (.A(MX2_63_Y), .B(BUFF_25_Y), .Y(\PP0[10] ));
    DFN1 DFN1_18 (.D(\PP6[14] ), .CLK(Clock), .Q(DFN1_18_Q));
    XOR3 XOR3_71 (.A(DFN1_122_Q), .B(DFN1_152_Q), .C(DFN1_225_Q), .Y(
        XOR3_71_Y));
    XOR2 XOR2_70 (.A(\SumA[1] ), .B(\SumB[1] ), .Y(XOR2_70_Y));
    DFN1 DFN1_109 (.D(\PP1[12] ), .CLK(Clock), .Q(DFN1_109_Q));
    XOR2 \XOR2_PP6[2]  (.A(MX2_60_Y), .B(BUFF_20_Y), .Y(\PP6[2] ));
    AO1 AO1_49 (.A(AND2_217_Y), .B(AO1_75_Y), .C(AO1_6_Y), .Y(AO1_49_Y)
        );
    AO1 AO1_16 (.A(XOR2_72_Y), .B(OR3_5_Y), .C(AND3_2_Y), .Y(AO1_16_Y));
    AO1 AO1_73 (.A(XOR2_41_Y), .B(AO1_78_Y), .C(AND2_220_Y), .Y(
        AO1_73_Y));
    MX2 MX2_72 (.A(AND2_130_Y), .B(BUFF_8_Y), .S(AO16_13_Y), .Y(
        MX2_72_Y));
    AND2 AND2_5 (.A(AND2_225_Y), .B(AND2_211_Y), .Y(AND2_5_Y));
    AND2 AND2_92 (.A(AND2_28_Y), .B(AND2_29_Y), .Y(AND2_92_Y));
    DFN1 DFN1_90 (.D(\PP4[12] ), .CLK(Clock), .Q(DFN1_90_Q));
    XOR2 XOR2_28 (.A(DataB[9]), .B(DataB[10]), .Y(XOR2_28_Y));
    DFN1 DFN1_191 (.D(\PP5[12] ), .CLK(Clock), .Q(DFN1_191_Q));
    AND2 AND2_208 (.A(AND2_225_Y), .B(AND2_211_Y), .Y(AND2_208_Y));
    XOR2 \XOR2_PP5[10]  (.A(MX2_106_Y), .B(BUFF_46_Y), .Y(\PP5[10] ));
    BUFF BUFF_32 (.A(DataB[5]), .Y(BUFF_32_Y));
    XOR2 XOR2_38 (.A(DFN1_144_Q), .B(DFN1_221_Q), .Y(XOR2_38_Y));
    MX2 MX2_62 (.A(AND2_78_Y), .B(BUFF_38_Y), .S(AO16_0_Y), .Y(
        MX2_62_Y));
    MAJ3 MAJ3_43 (.A(DFN1_119_Q), .B(DFN1_15_Q), .C(DFN1_226_Q), .Y(
        MAJ3_43_Y));
    AO1 AO1_65 (.A(XOR2_45_Y), .B(OR3_2_Y), .C(AND3_6_Y), .Y(AO1_65_Y));
    XOR2 \XOR2_PP4[15]  (.A(MX2_73_Y), .B(BUFF_7_Y), .Y(\PP4[15] ));
    XOR2 \XOR2_PP1[11]  (.A(MX2_50_Y), .B(BUFF_14_Y), .Y(\PP1[11] ));
    DFN1 DFN1_217 (.D(\PP4[5] ), .CLK(Clock), .Q(DFN1_217_Q));
    AND2 AND2_148 (.A(\SumA[11] ), .B(\SumB[11] ), .Y(AND2_148_Y));
    AO1 AO1_72 (.A(AND2_12_Y), .B(AO1_41_Y), .C(AO1_53_Y), .Y(AO1_72_Y)
        );
    AND2 AND2_152 (.A(DataB[0]), .B(BUFF_19_Y), .Y(AND2_152_Y));
    XOR2 XOR2_1 (.A(DFN1_178_Q), .B(DFN1_191_Q), .Y(XOR2_1_Y));
    MX2 MX2_41 (.A(AND2_81_Y), .B(BUFF_42_Y), .S(AO16_10_Y), .Y(
        MX2_41_Y));
    BUFF BUFF_47 (.A(DataA[11]), .Y(BUFF_47_Y));
    DFN1 \DFN1_SumB[4]  (.D(XOR3_77_Y), .CLK(Clock), .Q(\SumB[4] ));
    XOR3 XOR3_23 (.A(DFN1_179_Q), .B(DFN1_23_Q), .C(DFN1_21_Q), .Y(
        XOR3_23_Y));
    DFN1 DFN1_2 (.D(XOR3_12_Y), .CLK(Clock), .Q(DFN1_2_Q));
    XOR2 \XOR2_PP1[7]  (.A(MX2_18_Y), .B(BUFF_14_Y), .Y(\PP1[7] ));
    XOR2 XOR2_8 (.A(\SumA[18] ), .B(\SumB[18] ), .Y(XOR2_8_Y));
    DFN1 \DFN1_SumA[26]  (.D(MAJ3_45_Y), .CLK(Clock), .Q(\SumA[26] ));
    AND2 AND2_197 (.A(DFN1_135_Q), .B(DFN1_204_Q), .Y(AND2_197_Y));
    MX2 MX2_26 (.A(AND2_143_Y), .B(BUFF_26_Y), .S(AO16_2_Y), .Y(
        MX2_26_Y));
    DFN1 DFN1_75 (.D(\PP2[6] ), .CLK(Clock), .Q(DFN1_75_Q));
    XOR3 XOR3_29 (.A(XOR2_58_Y), .B(DFN1_94_Q), .C(XOR3_50_Y), .Y(
        XOR3_29_Y));
    MX2 MX2_55 (.A(AND2_230_Y), .B(BUFF_30_Y), .S(AO16_17_Y), .Y(
        MX2_55_Y));
    MX2 MX2_48 (.A(AND2_15_Y), .B(BUFF_18_Y), .S(AO16_3_Y), .Y(
        MX2_48_Y));
    XOR3 XOR3_33 (.A(MAJ3_37_Y), .B(DFN1_190_Q), .C(XOR3_63_Y), .Y(
        XOR3_33_Y));
    XOR2 \XOR2_PP3[12]  (.A(MX2_4_Y), .B(BUFF_40_Y), .Y(\PP3[12] ));
    DFN1 DFN1_13 (.D(MAJ3_31_Y), .CLK(Clock), .Q(DFN1_13_Q));
    XOR2 \XOR2_Mult[11]  (.A(XOR2_15_Y), .B(AO1_76_Y), .Y(Mult[11]));
    DFN1 \DFN1_SumA[20]  (.D(MAJ3_54_Y), .CLK(Clock), .Q(\SumA[20] ));
    XOR2 XOR2_60 (.A(DataB[5]), .B(DataB[6]), .Y(XOR2_60_Y));
    DFN1 DFN1_216 (.D(\PP0[13] ), .CLK(Clock), .Q(DFN1_216_Q));
    DFN1 DFN1_158 (.D(\PP0[10] ), .CLK(Clock), .Q(DFN1_158_Q));
    MAJ3 MAJ3_40 (.A(DFN1_99_Q), .B(DFN1_185_Q), .C(DFN1_64_Q), .Y(
        MAJ3_40_Y));
    XOR3 XOR3_39 (.A(DFN1_13_Q), .B(DFN1_129_Q), .C(DFN1_189_Q), .Y(
        XOR3_39_Y));
    AND2 AND2_106 (.A(XOR2_9_Y), .B(BUFF_16_Y), .Y(AND2_106_Y));
    MX2 MX2_95 (.A(AND2_20_Y), .B(BUFF_16_Y), .S(AO16_10_Y), .Y(
        MX2_95_Y));
    DFN1 DFN1_125 (.D(DFN1_89_Q), .CLK(Clock), .Q(DFN1_125_Q));
    XOR2 \XOR2_PP5[5]  (.A(MX2_99_Y), .B(BUFF_52_Y), .Y(\PP5[5] ));
    AO1 AO1_50 (.A(AND2_51_Y), .B(AO1_26_Y), .C(AO1_3_Y), .Y(AO1_50_Y));
    XOR2 \XOR2_PP1[14]  (.A(MX2_6_Y), .B(BUFF_44_Y), .Y(\PP1[14] ));
    DFN1 DFN1_9 (.D(XOR3_55_Y), .CLK(Clock), .Q(DFN1_9_Q));
    DFN1 DFN1_102 (.D(\PP4[3] ), .CLK(Clock), .Q(DFN1_102_Q));
    AND2 AND2_47 (.A(XOR2_33_Y), .B(BUFF_37_Y), .Y(AND2_47_Y));
    DFN1 DFN1_62 (.D(DFN1_12_Q), .CLK(Clock), .Q(DFN1_62_Q));
    XOR2 \XOR2_Mult[9]  (.A(XOR2_66_Y), .B(AO1_42_Y), .Y(Mult[9]));
    DFN1 DFN1_100 (.D(\PP5[6] ), .CLK(Clock), .Q(DFN1_100_Q));
    MX2 MX2_79 (.A(AND2_47_Y), .B(BUFF_11_Y), .S(AO16_8_Y), .Y(
        MX2_79_Y));
    DFN1 DFN1_123 (.D(\PP1[5] ), .CLK(Clock), .Q(DFN1_123_Q));
    AO1 AO1_80 (.A(XOR2_84_Y), .B(AO1_43_Y), .C(AND2_154_Y), .Y(
        AO1_80_Y));
    DFN1 DFN1_141 (.D(VCC), .CLK(Clock), .Q(DFN1_141_Q));
    MX2 MX2_30 (.A(AND2_75_Y), .B(BUFF_29_Y), .S(AND2A_1_Y), .Y(
        MX2_30_Y));
    XOR3 XOR3_27 (.A(DFN1_24_Q), .B(DFN1_220_Q), .C(XOR3_30_Y), .Y(
        XOR3_27_Y));
    AND2 AND2_54 (.A(AND2_107_Y), .B(AND2_158_Y), .Y(AND2_54_Y));
    DFN1 DFN1_52 (.D(\PP1[1] ), .CLK(Clock), .Q(DFN1_52_Q));
    AO1 AO1_6 (.A(XOR2_51_Y), .B(AND2_46_Y), .C(AND2_169_Y), .Y(
        AO1_6_Y));
    BUFF BUFF_52 (.A(DataB[11]), .Y(BUFF_52_Y));
    XOR2 \XOR2_PP4[5]  (.A(MX2_49_Y), .B(BUFF_39_Y), .Y(\PP4[5] ));
    MX2 MX2_69 (.A(AND2_180_Y), .B(BUFF_17_Y), .S(AND2A_2_Y), .Y(
        MX2_69_Y));
    XOR3 XOR3_52 (.A(DFN1_196_Q), .B(DFN1_184_Q), .C(DFN1_182_Q), .Y(
        XOR3_52_Y));
    AND2 \AND2_S[5]  (.A(XOR2_78_Y), .B(DataB[11]), .Y(\S[5] ));
    XOR2 \XOR2_PP3[2]  (.A(MX2_29_Y), .B(BUFF_15_Y), .Y(\PP3[2] ));
    XOR3 XOR3_37 (.A(DFN1_148_Q), .B(DFN1_140_Q), .C(DFN1_104_Q), .Y(
        XOR3_37_Y));
    AND2 AND2_67 (.A(XOR2_71_Y), .B(BUFF_29_Y), .Y(AND2_67_Y));
    XOR2 \XOR2_Mult[14]  (.A(XOR2_12_Y), .B(AO1_7_Y), .Y(Mult[14]));
    MAJ3 MAJ3_32 (.A(XOR3_26_Y), .B(MAJ3_76_Y), .C(DFN1_112_Q), .Y(
        MAJ3_32_Y));
    DFN1 DFN1_222 (.D(\PP0[4] ), .CLK(Clock), .Q(DFN1_222_Q));
    XOR2 \XOR2_PP5[7]  (.A(MX2_61_Y), .B(BUFF_46_Y), .Y(\PP5[7] ));
    AND3 AND3_5 (.A(DataB[9]), .B(DataB[10]), .C(DataB[11]), .Y(
        AND3_5_Y));
    AND2 AND2_8 (.A(XOR2_46_Y), .B(BUFF_26_Y), .Y(AND2_8_Y));
    MAJ3 MAJ3_0 (.A(DFN1_171_Q), .B(DFN1_44_Q), .C(DFN1_62_Q), .Y(
        MAJ3_0_Y));
    AND2 AND2_98 (.A(DataB[0]), .B(BUFF_29_Y), .Y(AND2_98_Y));
    MAJ3 MAJ3_11 (.A(DFN1_76_Q), .B(DFN1_4_Q), .C(DFN1_83_Q), .Y(
        MAJ3_11_Y));
    XOR2 XOR2_73 (.A(\SumA[18] ), .B(\SumB[18] ), .Y(XOR2_73_Y));
    AND2 AND2_41 (.A(AND2_28_Y), .B(AND2_60_Y), .Y(AND2_41_Y));
    XOR2 XOR2_79 (.A(\SumA[23] ), .B(\SumB[23] ), .Y(XOR2_79_Y));
    XOR2 XOR2_44 (.A(\SumA[17] ), .B(\SumB[17] ), .Y(XOR2_44_Y));
    DFN1 DFN1_31 (.D(DFN1_36_Q), .CLK(Clock), .Q(DFN1_31_Q));
    OR3 OR3_5 (.A(DataB[3]), .B(DataB[4]), .C(DataB[5]), .Y(OR3_5_Y));
    MX2 MX2_106 (.A(AND2_120_Y), .B(BUFF_42_Y), .S(AO16_5_Y), .Y(
        MX2_106_Y));
    AND2 \AND2_S[1]  (.A(XOR2_91_Y), .B(DataB[3]), .Y(\S[1] ));
    AO1 AO1_55 (.A(XOR2_65_Y), .B(AND2_91_Y), .C(AND2_6_Y), .Y(
        AO1_55_Y));
    AND2 AND2_132 (.A(XOR2_99_Y), .B(BUFF_17_Y), .Y(AND2_132_Y));
    XOR3 XOR3_56 (.A(MAJ3_57_Y), .B(DFN1_9_Q), .C(XOR3_24_Y), .Y(
        XOR3_56_Y));
    AND2 AND2_107 (.A(AND2_215_Y), .B(AND2_211_Y), .Y(AND2_107_Y));
    DFN1 DFN1_176 (.D(MAJ3_68_Y), .CLK(Clock), .Q(DFN1_176_Q));
    XOR2 \XOR2_PP1[4]  (.A(MX2_55_Y), .B(BUFF_21_Y), .Y(\PP1[4] ));
    XOR3 XOR3_72 (.A(XOR2_7_Y), .B(DFN1_166_Q), .C(MAJ3_0_Y), .Y(
        XOR3_72_Y));
    DFN1 DFN1_185 (.D(MAJ3_72_Y), .CLK(Clock), .Q(DFN1_185_Q));
    MX2 MX2_105 (.A(AND2_0_Y), .B(BUFF_13_Y), .S(AO16_13_Y), .Y(
        MX2_105_Y));
    DFN1 DFN1_166 (.D(DFN1_18_Q), .CLK(Clock), .Q(DFN1_166_Q));
    XOR3 XOR3_48 (.A(DFN1_15_Q), .B(DFN1_226_Q), .C(DFN1_119_Q), .Y(
        XOR3_48_Y));
    DFN1 DFN1_27 (.D(\PP0[6] ), .CLK(Clock), .Q(DFN1_27_Q));
    XOR3 XOR3_68 (.A(MAJ3_21_Y), .B(DFN1_150_Q), .C(XOR3_62_Y), .Y(
        XOR3_68_Y));
    DFN1 DFN1_68 (.D(XOR3_51_Y), .CLK(Clock), .Q(DFN1_68_Q));
    BUFF BUFF_36 (.A(DataB[5]), .Y(BUFF_36_Y));
    DFN1 DFN1_26 (.D(\PP2[7] ), .CLK(Clock), .Q(DFN1_26_Q));
    AND2 AND2_211 (.A(AND2_224_Y), .B(AND2_83_Y), .Y(AND2_211_Y));
    DFN1 DFN1_183 (.D(\PP2[12] ), .CLK(Clock), .Q(DFN1_183_Q));
    AND2 AND2_61 (.A(\SumA[28] ), .B(\SumB[28] ), .Y(AND2_61_Y));
    MAJ3 MAJ3_80 (.A(XOR3_39_Y), .B(MAJ3_41_Y), .C(DFN1_28_Q), .Y(
        MAJ3_80_Y));
    AND2 AND2_143 (.A(XOR2_90_Y), .B(BUFF_19_Y), .Y(AND2_143_Y));
    AND3 AND3_3 (.A(DataB[11]), .B(DataB[12]), .C(DataB[13]), .Y(
        AND3_3_Y));
    DFN1 DFN1_81 (.D(DFN1_162_Q), .CLK(Clock), .Q(DFN1_81_Q));
    DFN1 DFN1_179 (.D(MAJ3_2_Y), .CLK(Clock), .Q(DFN1_179_Q));
    XOR2 XOR2_77 (.A(\SumA[23] ), .B(\SumB[23] ), .Y(XOR2_77_Y));
    DFN1 DFN1_58 (.D(MAJ3_30_Y), .CLK(Clock), .Q(DFN1_58_Q));
    AO1 AO1_46 (.A(AND2_211_Y), .B(AO1_14_Y), .C(AO1_25_Y), .Y(
        AO1_46_Y));
    XOR2 XOR2_91 (.A(AND2_71_Y), .B(BUFF_21_Y), .Y(XOR2_91_Y));
    DFN1 DFN1_169 (.D(\PP6[3] ), .CLK(Clock), .Q(DFN1_169_Q));
    MAJ3 MAJ3_22 (.A(DFN1_131_Q), .B(DFN1_95_Q), .C(DFN1_219_Q), .Y(
        MAJ3_22_Y));
    MX2 MX2_36 (.A(AND2_134_Y), .B(BUFF_1_Y), .S(AO16_12_Y), .Y(
        MX2_36_Y));
    AO16 AO16_10 (.A(DataB[11]), .B(DataB[12]), .C(BUFF_9_Y), .Y(
        AO16_10_Y));
    AO1 AO1_77 (.A(XOR2_5_Y), .B(AO1_59_Y), .C(AND2_86_Y), .Y(AO1_77_Y)
        );
    DFN1 DFN1_196 (.D(MAJ3_18_Y), .CLK(Clock), .Q(DFN1_196_Q));
    DFN1 DFN1_97 (.D(XOR3_45_Y), .CLK(Clock), .Q(DFN1_97_Q));
    MX2 MX2_15 (.A(AND2_70_Y), .B(BUFF_22_Y), .S(AO16_5_Y), .Y(
        MX2_15_Y));
    DFN1 DFN1_29 (.D(\PP6[8] ), .CLK(Clock), .Q(DFN1_29_Q));
    DFN1 DFN1_96 (.D(MAJ3_39_Y), .CLK(Clock), .Q(DFN1_96_Q));
    BUFF BUFF_49 (.A(DataA[7]), .Y(BUFF_49_Y));
    AND2 AND2_219 (.A(XOR2_27_Y), .B(BUFF_49_Y), .Y(AND2_219_Y));
    AND2 AND2_25 (.A(DataB[0]), .B(BUFF_23_Y), .Y(AND2_25_Y));
    AOI1 \AOI1_E[3]  (.A(XOR2_54_Y), .B(OR3_4_Y), .C(AND3_4_Y), .Y(
        \E[3] ));
    AO1 AO1_64 (.A(AND2_191_Y), .B(AO1_20_Y), .C(AO1_27_Y), .Y(
        AO1_64_Y));
    AND2 \AND2_S[2]  (.A(XOR2_34_Y), .B(DataB[5]), .Y(\S[2] ));
    XOR2 XOR2_63 (.A(BUFF_45_Y), .B(DataB[11]), .Y(XOR2_63_Y));
    AND2 AND2_46 (.A(\SumA[18] ), .B(\SumB[18] ), .Y(AND2_46_Y));
    XOR3 XOR3_76 (.A(MAJ3_15_Y), .B(DFN1_180_Q), .C(XOR3_79_Y), .Y(
        XOR3_76_Y));
    AND2 AND2_84 (.A(XOR2_5_Y), .B(XOR2_80_Y), .Y(AND2_84_Y));
    DFN1 DFN1_199 (.D(\PP2[2] ), .CLK(Clock), .Q(DFN1_199_Q));
    MX2 \MX2_PP4[16]  (.A(MX2_37_Y), .B(AO1_4_Y), .S(AO16_11_Y), .Y(
        \PP4[16] ));
    XOR2 XOR2_69 (.A(\SumA[5] ), .B(\SumB[5] ), .Y(XOR2_69_Y));
    MX2 MX2_27 (.A(AND2_167_Y), .B(BUFF_43_Y), .S(AO16_14_Y), .Y(
        MX2_27_Y));
    MAJ3 MAJ3_72 (.A(MAJ3_60_Y), .B(AND2_72_Y), .C(DFN1_157_Q), .Y(
        MAJ3_72_Y));
    DFN1 DFN1_221 (.D(DFN1_173_Q), .CLK(Clock), .Q(DFN1_221_Q));
    AO1 AO1_78 (.A(XOR2_24_Y), .B(AND2_165_Y), .C(AND2_66_Y), .Y(
        AO1_78_Y));
    AO1 AO1_5 (.A(XOR2_74_Y), .B(AO1_49_Y), .C(AND2_3_Y), .Y(AO1_5_Y));
    AND2 AND2_124 (.A(XOR2_28_Y), .B(BUFF_22_Y), .Y(AND2_124_Y));
    DFN1 DFN1_99 (.D(XOR3_29_Y), .CLK(Clock), .Q(DFN1_99_Q));
    DFN1 DFN1_72 (.D(DFN1_181_Q), .CLK(Clock), .Q(DFN1_72_Q));
    XOR2 XOR2_45 (.A(BUFF_51_Y), .B(DataB[3]), .Y(XOR2_45_Y));
    DFN1 DFN1_114 (.D(\PP0[15] ), .CLK(Clock), .Q(DFN1_114_Q));
    DFN1 DFN1_135 (.D(DFN1_188_Q), .CLK(Clock), .Q(DFN1_135_Q));
    AND2 AND2_66 (.A(\SumA[9] ), .B(\SumB[9] ), .Y(AND2_66_Y));
    DFN1 \DFN1_SumB[28]  (.D(AND2_190_Y), .CLK(Clock), .Q(\SumB[28] ));
    AO1 AO1_8 (.A(XOR2_77_Y), .B(AND2_195_Y), .C(AND2_153_Y), .Y(
        AO1_8_Y));
    DFN1 DFN1_128 (.D(\PP6[5] ), .CLK(Clock), .Q(DFN1_128_Q));
    XOR2 \XOR2_PP2[3]  (.A(MX2_64_Y), .B(BUFF_36_Y), .Y(\PP2[3] ));
    DFN1 DFN1_63 (.D(XOR3_20_Y), .CLK(Clock), .Q(DFN1_63_Q));
    AOI1 \AOI1_E[5]  (.A(XOR2_63_Y), .B(OR3_3_Y), .C(AND3_5_Y), .Y(
        \E[5] ));
    AND3 AND3_6 (.A(DataB[1]), .B(DataB[2]), .C(DataB[3]), .Y(AND3_6_Y)
        );
    MX2 MX2_5 (.A(AND2_40_Y), .B(BUFF_33_Y), .S(AO16_3_Y), .Y(MX2_5_Y));
    DFN1 \DFN1_SumA[3]  (.D(AND2_138_Y), .CLK(Clock), .Q(\SumA[3] ));
    DFN1 DFN1_133 (.D(\PP6[2] ), .CLK(Clock), .Q(DFN1_133_Q));
    XOR2 XOR2_67 (.A(BUFF_45_Y), .B(DataB[9]), .Y(XOR2_67_Y));
    DFN1 DFN1_53 (.D(\PP4[10] ), .CLK(Clock), .Q(DFN1_53_Q));
    XOR3 XOR3_0 (.A(AND2_32_Y), .B(DFN1_100_Q), .C(MAJ3_53_Y), .Y(
        XOR3_0_Y));
    AND2 AND2_121 (.A(XOR2_41_Y), .B(XOR2_104_Y), .Y(AND2_121_Y));
    MX2 MX2_9 (.A(AND2_31_Y), .B(BUFF_11_Y), .S(AO16_1_Y), .Y(MX2_9_Y));
    MX2 MX2_82 (.A(AND2_76_Y), .B(BUFF_48_Y), .S(AO16_9_Y), .Y(
        MX2_82_Y));
    XOR2 \XOR2_Mult[4]  (.A(XOR2_88_Y), .B(AO1_57_Y), .Y(Mult[4]));
    AO1 AO1_69 (.A(XOR2_32_Y), .B(OR3_0_Y), .C(AND3_3_Y), .Y(AO1_69_Y));
    AND2 AND2_97 (.A(XOR2_75_Y), .B(BUFF_47_Y), .Y(AND2_97_Y));
    DFN1 DFN1_172 (.D(MAJ3_14_Y), .CLK(Clock), .Q(DFN1_172_Q));
    XOR3 XOR3_5 (.A(DFN1_127_Q), .B(DFN1_49_Q), .C(AND2_209_Y), .Y(
        XOR3_5_Y));
    DFN1 DFN1_170 (.D(DFN1_3_Q), .CLK(Clock), .Q(DFN1_170_Q));
    DFN1 DFN1_162 (.D(\PP6[11] ), .CLK(Clock), .Q(DFN1_162_Q));
    DFN1 DFN1_232 (.D(DFN1_54_Q), .CLK(Clock), .Q(DFN1_232_Q));
    GND GND_power_inst1 (.Y(GND_power_net1));
    VCC VCC_power_inst1 (.Y(VCC_power_net1));
    
endmodule

// _Disclaimer: Please leave the following comments in the file, they are for internal purposes only._


// _GEN_File_Contents_

// Version:11.9.6.7
// ACTGENU_CALL:1
// BATCH:T
// FAM:PA3
// OUTFORMAT:Verilog
// LPMTYPE:LPM_MULT
// LPM_HINT:XBOOTHMULT
// INSERT_PAD:NO
// INSERT_IOREG:NO
// GEN_BHV_VHDL_VAL:F
// GEN_BHV_VERILOG_VAL:F
// MGNTIMER:F
// MGNCMPL:T
// DESDIR:C:/Users/aamar/Documents/SeniorSem2/4806-MDE/FullSystem/FullSystem/smartgen\mult_16x14_3p
// GEN_BEHV_MODULE:F
// SMARTGEN_DIE:IT10X10M3
// SMARTGEN_PACKAGE:pq208
// AGENIII_IS_SUBPROJECT_LIBERO:T
// WIDTHA:16
// WIDTHB:14
// REPRESENTATION:SIGNED
// CLK_EDGE:RISE
// MAXPGEN:0
// PIPES:3
// INST_FA:1
// HYBRID:0
// DEBUG:0

// _End_Comments_


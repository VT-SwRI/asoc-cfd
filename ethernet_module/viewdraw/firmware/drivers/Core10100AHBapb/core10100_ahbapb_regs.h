/***************************************************************************//**
 * (c) Copyright 2012-2015 Microsemi SoC Products Group.  All rights reserved.
 *
 * IP core registers definitions. This file contains the definitions required
 * for accessing the IP core through the hardware abstraction layer (HAL).
 *
 * SVN $Revision: 7708 $
 * SVN $Date: 2015-08-28 15:31:15 +0530 (Fri, 28 Aug 2015) $
 *
 *******************************************************************************/
#ifndef CORE10100_AHBAPB_REGISTERS_H_
#define CORE10100_AHBAPB_REGISTERS_H_

#ifdef __cplusplus
extern "C" {
#endif 

/*******************************************************************************
 * CSR0 register:
 *------------------------------------------------------------------------------
 * CSR0 - Bus Mode Register
 */
#define CSR0_REG_OFFSET    0x00U

/*------------------------------------------------------------------------------
 * CSR0_DBO:
 *   DBO field of register CSR0.
 *------------------------------------------------------------------------------
 * Descriptor byte ordering mode
 */
#define CSR0_DBO_OFFSET   0x00U
#define CSR0_DBO_MASK     0x00100000U
#define CSR0_DBO_SHIFT    20U

/*
 * Allowed values for CSR0_DBO:
 *------------------------------------------------------------------------------
 * LITTLEENDIAN:   Little endian mode used for data descriptors
 * BIGENDIAN:      Big endian mode used for data descriptors
 */
#define LITTLEENDIAN    0U
#define BIGENDIAN       1U

/*------------------------------------------------------------------------------
 * CSR0_TAP:
 *   TAP field of register CSR0.
 *------------------------------------------------------------------------------
 * Transmit automatic polling
 */
#define CSR0_TAP_OFFSET   0x00U
#define CSR0_TAP_MASK     0x000E0000U
#define CSR0_TAP_SHIFT    17U

/*
 * Allowed values for CSR0_TAP:
 *------------------------------------------------------------------------------
 * TAP_DISABLED:   TAP disabled
 * TAP_819US:      TAP 819/81.9us
 * TAP_2450US:     TAP 2450/245us
 * TAP_5730US:     TAP 5730/573us
 * TAP_51_2US:     TAP 51.2/5.12us
 * TAP_102_4US:    TAP 102.4/10.24us
 * TAP_153_6US:    TAP 156.6/15.26us
 * TAP_358_4US:    TAP 358.4/35.84us
 */
#define TAP_DISABLED    0x0
#define TAP_819US       0x1
#define TAP_2450US      0x2
#define TAP_5730US      0x3
#define TAP_51_2US      0x4
#define TAP_102_4US     0x5
#define TAP_153_6US     0x6
#define TAP_358_4US     0x7

/*------------------------------------------------------------------------------
 * CSR0_PBL:
 *   PBL field of register CSR0.
 *------------------------------------------------------------------------------
 * Programmable burst length
 */
#define CSR0_PBL_OFFSET   0x00U
#define CSR0_PBL_MASK     0x00003F00U
#define CSR0_PBL_SHIFT    8U

/*------------------------------------------------------------------------------
 * CSR0_BLE:
 *   BLE field of register CSR0.
 *------------------------------------------------------------------------------
 * Big/little endian
 */
#define CSR0_BLE_OFFSET   0x00U
#define CSR0_BLE_MASK     0x00000080U
#define CSR0_BLE_SHIFT    7U

/*------------------------------------------------------------------------------
 * CSR0_DSL:
 *   DSL field of register CSR0.
 *------------------------------------------------------------------------------
 * Descriptor skip length
 */
#define CSR0_DSL_OFFSET   0x00U
#define CSR0_DSL_MASK     0x0000007CU
#define CSR0_DSL_SHIFT    2U

/*------------------------------------------------------------------------------
 * CSR0_BAR:
 *   BAR field of register CSR0.
 *------------------------------------------------------------------------------
 * Bus arbitration scheme
 */
#define CSR0_BAR_OFFSET   0x00U
#define CSR0_BAR_MASK     0x00000002U
#define CSR0_BAR_SHIFT    1U

/*------------------------------------------------------------------------------
 * CSR0_SWR:
 *   SWR field of register CSR0.
 *------------------------------------------------------------------------------
 * Software reset
 */
#define CSR0_SWR_OFFSET   0x00U
#define CSR0_SWR_MASK     0x00000001U
#define CSR0_SWR_SHIFT    0U

/*******************************************************************************
 * CSR1 register:
 *------------------------------------------------------------------------------
 * CSR1 - Transmit Poll Demand Register
 */
#define CSR1_REG_OFFSET    0x08U

/*------------------------------------------------------------------------------
 * CSR1_TPD3:
 *   TPD3 field of register CSR1.
 *------------------------------------------------------------------------------
 * TPD(31..24)
 */
#define CSR1_TPD3_OFFSET   0x08U
#define CSR1_TPD3_MASK     0xFF000000U
#define CSR1_TPD3_SHIFT    24U

/*------------------------------------------------------------------------------
 * CSR1_TPD2:
 *   TPD2 field of register CSR1.
 *------------------------------------------------------------------------------
 * TPD(23..16)
 */
#define CSR1_TPD2_OFFSET   0x08U
#define CSR1_TPD2_MASK     0x00FF0000U
#define CSR1_TPD2_SHIFT    16U

/*------------------------------------------------------------------------------
 * CSR1_TPD1:
 *   TPD1 field of register CSR1.
 *------------------------------------------------------------------------------
 * TPD(15..8)
 */
#define CSR1_TPD1_OFFSET   0x08U
#define CSR1_TPD1_MASK     0x0000FF00U
#define CSR1_TPD1_SHIFT    8U

/*------------------------------------------------------------------------------
 * CSR1_TPD0:
 *   TPD0 field of register CSR1.
 *------------------------------------------------------------------------------
 * TPD(7..0)
 */
#define CSR1_TPD0_OFFSET   0x08U
#define CSR1_TPD0_MASK     0x000000FFU
#define CSR1_TPD0_SHIFT    0U

/*******************************************************************************
 * CSR2 register:
 *------------------------------------------------------------------------------
 * CSR2 - Receive Poll Demand Register
 */
#define CSR2_REG_OFFSET    0x10U

/*------------------------------------------------------------------------------
 * CSR2_RPD3:
 *   RPD3 field of register CSR2.
 *------------------------------------------------------------------------------
 * RPD(31..24)
 */
#define CSR2_RPD3_OFFSET   0x10U
#define CSR2_RPD3_MASK     0xFF000000U
#define CSR2_RPD3_SHIFT    24U

/*------------------------------------------------------------------------------
 * CSR2_RPD2:
 *   RPD2 field of register CSR2.
 *------------------------------------------------------------------------------
 * RPD(23..16)
 */
#define CSR2_RPD2_OFFSET   0x10U
#define CSR2_RPD2_MASK     0x00FF0000U
#define CSR2_RPD2_SHIFT    16U

/*------------------------------------------------------------------------------
 * CSR2_RPD1:
 *   RPD1 field of register CSR2.
 *------------------------------------------------------------------------------
 * RPD(15..8)
 */
#define CSR2_RPD1_OFFSET   0x10U
#define CSR2_RPD1_MASK     0x0000FF00U
#define CSR2_RPD1_SHIFT    8U

/*------------------------------------------------------------------------------
 * CSR2_RPD0:
 *   RPD0 field of register CSR2.
 *------------------------------------------------------------------------------
 * RPD(7..0)
 */
#define CSR2_RPD0_OFFSET   0x10U
#define CSR2_RPD0_MASK     0x000000FFU
#define CSR2_RPD0_SHIFT    0U

/*******************************************************************************
 * CSR3 register:
 *------------------------------------------------------------------------------
 * CSR3 - Receive Descriptor List Base Address Register
 */
#define CSR3_REG_OFFSET    0x18U

/*------------------------------------------------------------------------------
 * CSR3_RLA3:
 *   RLA3 field of register CSR3.
 *------------------------------------------------------------------------------
 * RLA(31..24)
 */
#define CSR3_RLA3_OFFSET   0x18U
#define CSR3_RLA3_MASK     0xFF000000U
#define CSR3_RLA3_SHIFT    24U

/*------------------------------------------------------------------------------
 * CSR3_RLA2:
 *   RLA2 field of register CSR3.
 *------------------------------------------------------------------------------
 * RLA(23..16)
 */
#define CSR3_RLA2_OFFSET   0x18U
#define CSR3_RLA2_MASK     0x00FF0000U
#define CSR3_RLA2_SHIFT    16U

/*------------------------------------------------------------------------------
 * CSR3_RLA1:
 *   RLA1 field of register CSR3.
 *------------------------------------------------------------------------------
 * RLA(15..8)
 */
#define CSR3_RLA1_OFFSET   0x18U
#define CSR3_RLA1_MASK     0x0000FF00U
#define CSR3_RLA1_SHIFT    8U

/*------------------------------------------------------------------------------
 * CSR3_RLA0:
 *   RLA0 field of register CSR3.
 *------------------------------------------------------------------------------
 * RLA(7..0)
 */
#define CSR3_RLA0_OFFSET   0x18U
#define CSR3_RLA0_MASK     0x000000FFU
#define CSR3_RLA0_SHIFT    0U

/*******************************************************************************
 * CSR4 register:
 *------------------------------------------------------------------------------
 * CSR4 - Transmit Descriptor List Base Address Register
 */
#define CSR4_REG_OFFSET    0x20U

/*------------------------------------------------------------------------------
 * CSR4_TLA3:
 *   TLA3 field of register CSR4.
 *------------------------------------------------------------------------------
 * TLA(31..24)
 */
#define CSR4_TLA3_OFFSET   0x20U
#define CSR4_TLA3_MASK     0xFF000000U
#define CSR4_TLA3_SHIFT    24U

/*------------------------------------------------------------------------------
 * CSR4_TLA2:
 *   TLA2 field of register CSR4.
 *------------------------------------------------------------------------------
 * TLA(23..16)
 */
#define CSR4_TLA2_OFFSET   0x20U
#define CSR4_TLA2_MASK     0x00FF0000U
#define CSR4_TLA2_SHIFT    16U

/*------------------------------------------------------------------------------
 * CSR4_TLA1:
 *   TLA1 field of register CSR4.
 *------------------------------------------------------------------------------
 * TLA(15..8)
 */
#define CSR4_TLA1_OFFSET   0x20U
#define CSR4_TLA1_MASK     0x0000FF00U
#define CSR4_TLA1_SHIFT    8U

/*------------------------------------------------------------------------------
 * CSR4_TLA0:
 *   TLA0 field of register CSR4.
 *------------------------------------------------------------------------------
 * TLA(7..0)
 */
#define CSR4_TLA0_OFFSET   0x20U
#define CSR4_TLA0_MASK     0x000000FFU
#define CSR4_TLA0_SHIFT    0U

/*******************************************************************************
 * CSR5 register:
 *------------------------------------------------------------------------------
 * CSR5 - Status Register
 */
#define CSR5_REG_OFFSET    0x28U
#define CSR5_INT_BITS    (CSR5_NIS_MASK | CSR5_AIS_MASK | CSR5_ERI_MASK | \
    CSR5_GTE_MASK | CSR5_ETI_MASK | CSR5_RPS_MASK | CSR5_RU_MASK | \
    CSR5_RI_MASK | CSR5_UNF_MASK | CSR5_TU_MASK | CSR5_TPS_MASK | CSR5_TI_MASK)

/*------------------------------------------------------------------------------
 * CSR5_TS:
 *   TS field of register CSR5.
 *------------------------------------------------------------------------------
 * Transmit process state
 */
#define CSR5_TS_OFFSET   0x28U
#define CSR5_TS_MASK     0x00700000U
#define CSR5_TS_SHIFT    20U

/** 000 - Stopped; RESET or STOP TRANSMIT command issued.             */
#define CSR5_TS_STOPPED         0U
/** 001 - Running, fetching the transmit descriptor.                  */
#define CSR5_TS_RUNNING_FD      1U
/** 010 - Running, waiting for end of transmission.                   */
#define CSR5_TS_RUNNING_WT      2U
/** 011 - Running, transferring data buffer from host memory to FIFO. */
#define CSR5_TS_RUNNING_TD      3U
/** 101 - Running, setup packet.                                      */
#define CSR5_TS_RUNNING_SP      5U
/** 110 - Suspended; FIFO underflow or unavailable descriptor.        */
#define CSR5_TS_SUSPENDED       6U
/** 111 - Running, closing transmit descriptor.                       */
#define CSR5_TS_RUNNING_CD      7U

/*------------------------------------------------------------------------------
 * CSR5_RS:
 *   RS field of register CSR5.
 *------------------------------------------------------------------------------
 * Receive process state
 */
#define CSR5_RS_OFFSET   0x28U
#define CSR5_RS_MASK     0x00060000U
#define CSR5_RS_SHIFT    17U

/** 000 - Stopped; RESET or STOP RECEIVE command issued.                      */
#define CSR5_RS_STOPPED         0U
/** 001 - Running, fetching the receive descriptor.                           */
#define CSR5_RS_RUNNING_FD      1U
/** 010 - Running, waiting for the end-of-receive packet before prefetch of the
 *next descriptor. */
#define CSR5_RS_RUNNING_WR      2U
/** 011 - Running, waiting for the receive packet.                            */
#define CSR5_RS_RUNNING_RB      3U
/** 100 - Suspended, unavailable receive buffer.                              */
#define CSR5_RS_SUSPENDED       4U
/** 101 - Running, closing the receive descriptor.                            */
#define CSR5_RS_RUNNING_CD      5U
/** 111 - Running, transferring data from FIFO to host memory.                */
#define CSR5_RS_RUNNING_TD      7U

/*------------------------------------------------------------------------------
 * CSR5_NIS:
 *   NIS field of register CSR5.
 *------------------------------------------------------------------------------
 * Normal interrupt summary
 */
#define CSR5_NIS_OFFSET   0x28U
#define CSR5_NIS_MASK     0x00010000U
#define CSR5_NIS_SHIFT    16U

/*------------------------------------------------------------------------------
 * CSR5_AIS:
 *   AIS field of register CSR5.
 *------------------------------------------------------------------------------
 * Abnormal interrupt summary
 */
#define CSR5_AIS_OFFSET   0x28U
#define CSR5_AIS_MASK     0x00008000U
#define CSR5_AIS_SHIFT    15U

/*------------------------------------------------------------------------------
 * CSR5_ERI:
 *   ERI field of register CSR5.
 *------------------------------------------------------------------------------
 * Early receive interrupt
 */
#define CSR5_ERI_OFFSET   0x28U
#define CSR5_ERI_MASK     0x00004000U
#define CSR5_ERI_SHIFT    14U

/*------------------------------------------------------------------------------
 * CSR5_GTE:
 *   GTE field of register CSR5.
 *------------------------------------------------------------------------------
 * General-purpose timer expiration
 */
#define CSR5_GTE_OFFSET   0x28U
#define CSR5_GTE_MASK     0x00000800U
#define CSR5_GTE_SHIFT    11U

/*------------------------------------------------------------------------------
 * CSR5_ETI:
 *   ETI field of register CSR5.
 *------------------------------------------------------------------------------
 * Early transmit interrupt
 */
#define CSR5_ETI_OFFSET   0x28U
#define CSR5_ETI_MASK     0x00000400U
#define CSR5_ETI_SHIFT    10U

/*------------------------------------------------------------------------------
 * CSR5_RPS:
 *   RPS field of register CSR5.
 *------------------------------------------------------------------------------
 * Receive process stopped
 */
#define CSR5_RPS_OFFSET   0x28U
#define CSR5_RPS_MASK     0x00000100U
#define CSR5_RPS_SHIFT    8U

/*------------------------------------------------------------------------------
 * CSR5_RU:
 *   RU field of register CSR5.
 *------------------------------------------------------------------------------
 * Receive buffer unavailable
 */
#define CSR5_RU_OFFSET   0x28U
#define CSR5_RU_MASK     0x00000080U
#define CSR5_RU_SHIFT    7U

/*------------------------------------------------------------------------------
 * CSR5_RI:
 *   RI field of register CSR5.
 *------------------------------------------------------------------------------
 * Receive interrupt
 */
#define CSR5_RI_OFFSET   0x28U
#define CSR5_RI_MASK     0x00000040U
#define CSR5_RI_SHIFT    6U

/*------------------------------------------------------------------------------
 * CSR5_UNF:
 *   UNF field of register CSR5.
 *------------------------------------------------------------------------------
 * Transmit underflow
 */
#define CSR5_UNF_OFFSET   0x28U
#define CSR5_UNF_MASK     0x00000020U
#define CSR5_UNF_SHIFT    5U

/*------------------------------------------------------------------------------
 * CSR5_TU:
 *   TU field of register CSR5.
 *------------------------------------------------------------------------------
 * Transmit buffer unavailable
 */
#define CSR5_TU_OFFSET   0x28U
#define CSR5_TU_MASK     0x00000004U
#define CSR5_TU_SHIFT    2U

/*------------------------------------------------------------------------------
 * CSR5_TPS:
 *   TPS field of register CSR5.
 *------------------------------------------------------------------------------
 * Transmit process stopped
 */
#define CSR5_TPS_OFFSET   0x28U
#define CSR5_TPS_MASK     0x00000002U
#define CSR5_TPS_SHIFT    1U

/*------------------------------------------------------------------------------
 * CSR5_TI:
 *   TI field of register CSR5.
 *------------------------------------------------------------------------------
 * Transmit interrupt
 */
#define CSR5_TI_OFFSET   0x28U
#define CSR5_TI_MASK     0x00000001U
#define CSR5_TI_SHIFT    0U

/*******************************************************************************
 * CSR6 register:
 *------------------------------------------------------------------------------
 * CSR6 - Operation Mode Register
 */
#define CSR6_REG_OFFSET    0x30U

/*------------------------------------------------------------------------------
 * CSR6_RA:
 *   RA field of register CSR6.
 *------------------------------------------------------------------------------
 * Receive all
 */
#define CSR6_RA_OFFSET   0x30U
#define CSR6_RA_MASK     0x40000000U
#define CSR6_RA_SHIFT    30U

/*------------------------------------------------------------------------------
 * CSR6_TTM:
 *   TTM field of register CSR6.
 *------------------------------------------------------------------------------
 * Transmit threshold mode
 */
#define CSR6_TTM_OFFSET   0x30U
#define CSR6_TTM_MASK     0x00400000U
#define CSR6_TTM_SHIFT    22U

/*------------------------------------------------------------------------------
 * CSR6_SF:
 *   SF field of register CSR6.
 *------------------------------------------------------------------------------
 * Store and forward
 */
#define CSR6_SF_OFFSET   0x30U
#define CSR6_SF_MASK     0x00200000U
#define CSR6_SF_SHIFT    21U

/*------------------------------------------------------------------------------
 * CSR6_TR:
 *   TR field of register CSR6.
 *------------------------------------------------------------------------------
 * Threshold control bits
 */
#define CSR6_TR_OFFSET   0x30U
#define CSR6_TR_MASK     0x0000C000U
#define CSR6_TR_SHIFT    14U

/*------------------------------------------------------------------------------
 * CSR6_ST:
 *   ST field of register CSR6.
 *------------------------------------------------------------------------------
 * Start/stop transmit command
 */
#define CSR6_ST_OFFSET   0x30U
#define CSR6_ST_MASK     0x00002000U
#define CSR6_ST_SHIFT    13U

/*------------------------------------------------------------------------------
 * CSR6_FD:
 *   FD field of register CSR6.
 *------------------------------------------------------------------------------
 * Full-duplex mode
 */
#define CSR6_FD_OFFSET   0x30U
#define CSR6_FD_MASK     0x00000200U
#define CSR6_FD_SHIFT    9U

/*------------------------------------------------------------------------------
 * CSR6_PM:
 *   PM field of register CSR6.
 *------------------------------------------------------------------------------
 * Pass all multicast
 */
#define CSR6_PM_OFFSET   0x30U
#define CSR6_PM_MASK     0x00000080U
#define CSR6_PM_SHIFT    7U

/*------------------------------------------------------------------------------
 * CSR6_PR:
 *   PR field of register CSR6.
 *------------------------------------------------------------------------------
 * Promiscuous mode
 */
#define CSR6_PR_OFFSET   0x30U
#define CSR6_PR_MASK     0x00000040U
#define CSR6_PR_SHIFT    6U

/*------------------------------------------------------------------------------
 * CSR6_IF:
 *   IF field of register CSR6.
 *------------------------------------------------------------------------------
 * Inverse filtering
 */
#define CSR6_IF_OFFSET   0x30U
#define CSR6_IF_MASK     0x00000010U
#define CSR6_IF_SHIFT    4U

/*------------------------------------------------------------------------------
 * CSR6_PB:
 *   PB field of register CSR6.
 *------------------------------------------------------------------------------
 * Pass bad frames
 */
#define CSR6_PB_OFFSET   0x30U
#define CSR6_PB_MASK     0x00000008U
#define CSR6_PB_SHIFT    3U

/*------------------------------------------------------------------------------
 * CSR6_HO:
 *   HO field of register CSR6.
 *------------------------------------------------------------------------------
 * Hash-only filtering mode
 */
#define CSR6_HO_OFFSET   0x30U
#define CSR6_HO_MASK     0x00000004U
#define CSR6_HO_SHIFT    2U

/*------------------------------------------------------------------------------
 * CSR6_SR:
 *   SR field of register CSR6.
 *------------------------------------------------------------------------------
 * Start/stop receive command
 */
#define CSR6_SR_OFFSET   0x30U
#define CSR6_SR_MASK     0x00000002U
#define CSR6_SR_SHIFT    1U

/*------------------------------------------------------------------------------
 * CSR6_HP:
 *   HP field of register CSR6.
 *------------------------------------------------------------------------------
 * Hash/perfect receive filtering mode
 */
#define CSR6_HP_OFFSET   0x30U
#define CSR6_HP_MASK     0x00000001U
#define CSR6_HP_SHIFT    0U

/*******************************************************************************
 * CSR7 register:
 *------------------------------------------------------------------------------
 * CSR7 - Interrupt Enable Register
 */
#define CSR7_REG_OFFSET    0x38U

/*------------------------------------------------------------------------------
 * CSR7_NIE:
 *   NIE field of register CSR7.
 *------------------------------------------------------------------------------
 * Normal interrupt summary enable
 */
#define CSR7_NIE_OFFSET   0x38U
#define CSR7_NIE_MASK     0x00010000U
#define CSR7_NIE_SHIFT    16U

/*------------------------------------------------------------------------------
 * CSR7_AIE:
 *   AIE field of register CSR7.
 *------------------------------------------------------------------------------
 * Abnormal interrupt summary enable
 */
#define CSR7_AIE_OFFSET   0x38U
#define CSR7_AIE_MASK     0x00008000U
#define CSR7_AIE_SHIFT    15U

/*------------------------------------------------------------------------------
 * CSR7_ERE:
 *   ERE field of register CSR7.
 *------------------------------------------------------------------------------
 * Early receive interrupt enable
 */
#define CSR7_ERE_OFFSET   0x38U
#define CSR7_ERE_MASK     0x00004000U
#define CSR7_ERE_SHIFT    14U

/*------------------------------------------------------------------------------
 * CSR7_GTE:
 *   GTE field of register CSR7.
 *------------------------------------------------------------------------------
 * General-purpose timer overflow enable
 */
#define CSR7_GTE_OFFSET   0x38U
#define CSR7_GTE_MASK     0x00000800U
#define CSR7_GTE_SHIFT    11U

/*------------------------------------------------------------------------------
 * CSR7_ETE:
 *   ETE field of register CSR7.
 *------------------------------------------------------------------------------
 * Early transmit interrupt enable
 */
#define CSR7_ETE_OFFSET   0x38U
#define CSR7_ETE_MASK     0x00000400U
#define CSR7_ETE_SHIFT    10U

/*------------------------------------------------------------------------------
 * CSR7_RSE:
 *   RSE field of register CSR7.
 *------------------------------------------------------------------------------
 * Receive stopped enable
 */
#define CSR7_RSE_OFFSET   0x38U
#define CSR7_RSE_MASK     0x00000100U
#define CSR7_RSE_SHIFT    8U

/*------------------------------------------------------------------------------
 * CSR7_RUE:
 *   RUE field of register CSR7.
 *------------------------------------------------------------------------------
 * Receive buffer unavailable enable
 */
#define CSR7_RUE_OFFSET   0x38U
#define CSR7_RUE_MASK     0x00000080U
#define CSR7_RUE_SHIFT    7U

/*------------------------------------------------------------------------------
 * CSR7_RIE:
 *   RIE field of register CSR7.
 *------------------------------------------------------------------------------
 * Receive interrupt enable
 */
#define CSR7_RIE_OFFSET   0x38U
#define CSR7_RIE_MASK     0x00000040U
#define CSR7_RIE_SHIFT    6U

/*------------------------------------------------------------------------------
 * CSR7_UNE:
 *   UNE field of register CSR7.
 *------------------------------------------------------------------------------
 * Underflow interrupt enable
 */
#define CSR7_UNE_OFFSET   0x38U
#define CSR7_UNE_MASK     0x00000020U
#define CSR7_UNE_SHIFT    5U

/*------------------------------------------------------------------------------
 * CSR7_TUE:
 *   TUE field of register CSR7.
 *------------------------------------------------------------------------------
 * Transmit buffer unavailable enable
 */
#define CSR7_TUE_OFFSET   0x38U
#define CSR7_TUE_MASK     0x00000004U
#define CSR7_TUE_SHIFT    2U

/*------------------------------------------------------------------------------
 * CSR7_TSE:
 *   TSE field of register CSR7.
 *------------------------------------------------------------------------------
 * Transmit stopped enable
 */
#define CSR7_TSE_OFFSET   0x38U
#define CSR7_TSE_MASK     0x00000002U
#define CSR7_TSE_SHIFT    1U

/*------------------------------------------------------------------------------
 * CSR7_TIE:
 *   TIE field of register CSR7.
 *------------------------------------------------------------------------------
 * Transmit interrupt enable
 */
#define CSR7_TIE_OFFSET   0x38U
#define CSR7_TIE_MASK     0x00000001U
#define CSR7_TIE_SHIFT    0U

/*******************************************************************************
 * CSR8 register:
 *------------------------------------------------------------------------------
 * CSR8 - Missed Frames and Overflow Counter Register
 */
#define CSR8_REG_OFFSET    0x40U

/*------------------------------------------------------------------------------
 * CSR8_OCO:
 *   OCO field of register CSR8.
 *------------------------------------------------------------------------------
 * Overflow counter overflow
 */
#define CSR8_OCO_OFFSET   0x40U
#define CSR8_OCO_MASK     0x10000000U
#define CSR8_OCO_SHIFT    28U

/*------------------------------------------------------------------------------
 * CSR8_FOC:
 *   FOC field of register CSR8.
 *------------------------------------------------------------------------------
 * FIFO overflow counter
 */
#define CSR8_FOC_OFFSET   0x40U
#define CSR8_FOC_MASK     0x0FFE0000U
#define CSR8_FOC_SHIFT    17U

/*------------------------------------------------------------------------------
 * CSR8_MFO:
 *   MFO field of register CSR8.
 *------------------------------------------------------------------------------
 * Missed frame overflow
 */
#define CSR8_MFO_OFFSET   0x40U
#define CSR8_MFO_MASK     0x00010000U
#define CSR8_MFO_SHIFT    16U

/*------------------------------------------------------------------------------
 * CSR8_MFC:
 *   MFC field of register CSR8.
 *------------------------------------------------------------------------------
 * Missed frame counter
 */
#define CSR8_MFC_OFFSET   0x40U
#define CSR8_MFC_MASK     0x0000FFFFU
#define CSR8_MFC_SHIFT    0U

/*******************************************************************************
 * CSR9 register:
 *------------------------------------------------------------------------------
 * CSR9 - MII Management and Serial ROM Interface Register
 */
#define CSR9_REG_OFFSET    0x48U

/*------------------------------------------------------------------------------
 * CSR9_MDI:
 *   MDI field of register CSR9.
 *------------------------------------------------------------------------------
 * MII management data in signal
 */
#define CSR9_MDI_OFFSET   0x48U
#define CSR9_MDI_MASK     0x00080000U
#define CSR9_MDI_SHIFT    19U

/*------------------------------------------------------------------------------
 * CSR9_MII:
 *   MII field of register CSR9.
 *------------------------------------------------------------------------------
 * MII management operation mode
 */
#define CSR9_MII_OFFSET   0x48U
#define CSR9_MII_MASK     0x00040000U
#define CSR9_MII_SHIFT    18U

/*------------------------------------------------------------------------------
 * CSR9_MDO:
 *   MDO field of register CSR9.
 *------------------------------------------------------------------------------
 * MII management write data
 */
#define CSR9_MDO_OFFSET   0x48U
#define CSR9_MDO_MASK     0x00020000U
#define CSR9_MDO_SHIFT    17U

/*------------------------------------------------------------------------------
 * CSR9_MDC:
 *   MDC field of register CSR9.
 *------------------------------------------------------------------------------
 * MII management clock
 */
#define CSR9_MDC_OFFSET   0x48U
#define CSR9_MDC_MASK     0x00010000U
#define CSR9_MDC_SHIFT    16U

/*------------------------------------------------------------------------------
 * CSR9_SDO:
 *   SDO field of register CSR9.
 *------------------------------------------------------------------------------
 * Serial ROM data output
 */
#define CSR9_SDO_OFFSET   0x48U
#define CSR9_SDO_MASK     0x00000008U
#define CSR9_SDO_SHIFT    3U

/*------------------------------------------------------------------------------
 * CSR9_SDI:
 *   SDI field of register CSR9.
 *------------------------------------------------------------------------------
 * Serial ROM data input
 */
#define CSR9_SDI_OFFSET   0x48U
#define CSR9_SDI_MASK     0x00000004U
#define CSR9_SDI_SHIFT    2U

/*------------------------------------------------------------------------------
 * CSR9_SCLK:
 *   SCLK field of register CSR9.
 *------------------------------------------------------------------------------
 * Serial ROM clock
 */
#define CSR9_SCLK_OFFSET   0x48U
#define CSR9_SCLK_MASK     0x00000002U
#define CSR9_SCLK_SHIFT    1U

/*------------------------------------------------------------------------------
 * CSR9_SCS:
 *   SCS field of register CSR9.
 *------------------------------------------------------------------------------
 * Serial ROM chip select
 */
#define CSR9_SCS_OFFSET   0x48U
#define CSR9_SCS_MASK     0x00000001U
#define CSR9_SCS_SHIFT    0U

/*******************************************************************************
 * CSR11 register:
 *------------------------------------------------------------------------------
 * CSR11 - General-Purpose Timer and Interrupt Mitigation Control Register
 */
#define CSR11_REG_OFFSET    0x58U

/*------------------------------------------------------------------------------
 * CSR11_CS:
 *   CS field of register CSR11.
 *------------------------------------------------------------------------------
 * Cycle size
 */
#define CSR11_CS_OFFSET   0x58U
#define CSR11_CS_MASK     0x80000000U
#define CSR11_CS_SHIFT    31U

/*------------------------------------------------------------------------------
 * CSR11_TT:
 *   TT field of register CSR11.
 *------------------------------------------------------------------------------
 * Transmit timer
 */
#define CSR11_TT_OFFSET   0x58U
#define CSR11_TT_MASK     0x78000000U
#define CSR11_TT_SHIFT    27U

/*------------------------------------------------------------------------------
 * CSR11_NTP:
 *   NTP field of register CSR11.
 *------------------------------------------------------------------------------
 * Number of transmit packets
 */
#define CSR11_NTP_OFFSET   0x58U
#define CSR11_NTP_MASK     0x07000000U
#define CSR11_NTP_SHIFT    24U

/*------------------------------------------------------------------------------
 * CSR11_RT:
 *   RT field of register CSR11.
 *------------------------------------------------------------------------------
 * Receive timer
 */
#define CSR11_RT_OFFSET   0x58U
#define CSR11_RT_MASK     0x00F00000U
#define CSR11_RT_SHIFT    20U

/*------------------------------------------------------------------------------
 * CSR11_NRP:
 *   NRP field of register CSR11.
 *------------------------------------------------------------------------------
 * Number of receive packets
 */
#define CSR11_NRP_OFFSET   0x58U
#define CSR11_NRP_MASK     0x000E0000U
#define CSR11_NRP_SHIFT    17U

/*------------------------------------------------------------------------------
 * CSR11_CON:
 *   CON field of register CSR11.
 *------------------------------------------------------------------------------
 * Continuous mode
 */
#define CSR11_CON_OFFSET   0x58U
#define CSR11_CON_MASK     0x00010000U
#define CSR11_CON_SHIFT    16U

/*------------------------------------------------------------------------------
 * CSR11_TIM:
 *   TIM field of register CSR11.
 *------------------------------------------------------------------------------
 * Timer value
 */
#define CSR11_TIM_OFFSET   0x58U
#define CSR11_TIM_MASK     0x0000FFFFU
#define CSR11_TIM_SHIFT    0U

#ifdef __cplusplus
}
#endif

#endif /* CORE10100_AHBAPB_REGISTERS_H_*/

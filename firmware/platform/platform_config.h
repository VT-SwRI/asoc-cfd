#pragma once
/**
 * platform_config.h
 *
 * Target-specific configuration for the ASoC FPGA/firmware prototype.
 *
 * This file is intentionally the only place you should need to edit when
 * moving between platforms (A3PE soft CPU, other MCU, host/mock build, etc.).
 */

/* ------------------------------ Target select ------------------------------ */
/* Exactly ONE of these should be set to 1. */
#ifndef PLATFORM_TARGET_A3PE
#define PLATFORM_TARGET_A3PE 0
#endif

#ifndef PLATFORM_TARGET_MOCK
#define PLATFORM_TARGET_MOCK 1
#endif

#if (PLATFORM_TARGET_A3PE + PLATFORM_TARGET_MOCK) != 1
#error "Select exactly one target: PLATFORM_TARGET_A3PE or PLATFORM_TARGET_MOCK"
#endif

/* ------------------------------- CPU / clock ------------------------------ */
#ifndef PLATFORM_CPU_HZ
/* For Cortex-M1 soft core this is often 50-100 MHz depending on your Libero design. */
#define PLATFORM_CPU_HZ 50000000u
#endif

/* ------------------------------ Debug / UART ------------------------------ */
#ifndef PLATFORM_UART_BAUD
#define PLATFORM_UART_BAUD 115200u
#endif

/* ------------------------------- SPI / serial ----------------------------- */
#ifndef PLATFORM_SPI_HZ
/* Conservative default; update to match your CoreSPI or bit-banged implementation. */
#define PLATFORM_SPI_HZ 1000000u
#endif

/* -------------------------- Custom FPGA register block --------------------- */
/**
 * Base address of the FPGA control/status register block.
 * In a Libero SoC design this is the APB slave base address of your custom core.
 *
 * For mock builds this can be any value; the mock platform ignores it.
 */
#ifndef FPGA_REG_BASE
#define FPGA_REG_BASE 0x40000000u
#endif

/* --------------------------- Build-time feature toggles -------------------- */
#ifndef ASOC_ENABLE_CFD
#define ASOC_ENABLE_CFD 1
#endif

#ifndef ASOC_ENABLE_CRC32
#define ASOC_ENABLE_CRC32 1
#endif

/**
 * If set, the firmware maintains a shadow copy of ASIC registers because not all
 * boards expose readback for every register (common in Nalu hardware/software). 
 */
#ifndef ASOC_SHADOW_REGISTERS
#define ASOC_SHADOW_REGISTERS 1
#endif

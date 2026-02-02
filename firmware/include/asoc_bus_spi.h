#pragma once
#include "asoc_bus.h"

/**
 * Simple SPI register portal.
 *
 * Assumed transaction format (common pattern):
 *   WRITE: [0x80 | addr_hi] [addr_lo] [payload...]
 *   READ : [0x00 | addr_hi] [addr_lo] then read back [payload...]
 *
 * You should update this to match the actual ASoC/FPGA serial protocol you use.
 * naludaq supports both parallel and serial register access depending on board.
 */
typedef struct {
  uint8_t addr_hi_mask;
} asoc_bus_spi_ctx_t;

asoc_bus_t asoc_bus_spi_make(asoc_bus_spi_ctx_t *ctx);

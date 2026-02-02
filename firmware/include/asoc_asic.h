#pragma once
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "asoc_bus.h"
#include "asoc_error.h"

/**
 * High-level ASIC control API.
 *
 * Notes:
 * - The concrete register addresses/meanings are board/firmware dependent.
 * - naludaq maintains a software state because some registers are not readable.
 *   We mirror that approach via ASOC_SHADOW_REGISTERS.
 */

typedef struct {
  asoc_bus_t bus;

#if ASOC_SHADOW_REGISTERS
  /* 16-bit address space shadow (sparse); implement as a simple fixed table for now. */
  struct { uint16_t addr; uint32_t val; } shadow[128];
  size_t shadow_len;
#endif
} asoc_asic_t;

void asoc_asic_init(asoc_asic_t *a, asoc_bus_t bus);

/* Basic register IO (little-endian payloads). */
asoc_status_t asoc_asic_write_u32(asoc_asic_t *a, uint16_t addr, uint32_t v);
asoc_status_t asoc_asic_read_u32 (asoc_asic_t *a, uint16_t addr, uint32_t *out);

/* Typical sequencing helpers (fill in real register writes as you learn them). */
asoc_status_t asoc_asic_reset(asoc_asic_t *a);
asoc_status_t asoc_asic_apply_default_config(asoc_asic_t *a);

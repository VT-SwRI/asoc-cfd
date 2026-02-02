#pragma once
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "platform_config.h"

/**
 * Platform abstraction layer.
 *
 * The rest of the firmware should never touch raw addresses or vendor-specific
 * peripheral register layouts directly.
 */

/* ------------------------------ MMIO helpers ------------------------------ */
static inline void platform_mmio_write32(uint32_t addr, uint32_t value) {
  volatile uint32_t *p = (volatile uint32_t *) (uintptr_t) addr;
  *p = value;
}

static inline uint32_t platform_mmio_read32(uint32_t addr) {
  volatile uint32_t *p = (volatile uint32_t *) (uintptr_t) addr;
  return *p;
}

/* ------------------------------ Lifecycle -------------------------------- */
void platform_init(void);

/* ------------------------------- Time ------------------------------------- */
void platform_delay_us(uint32_t us);
uint32_t platform_millis(void);

/* ------------------------------- UART ------------------------------------- */
void platform_uart_write(const char *s);
void platform_uart_write_n(const char *s, size_t n);
int  platform_uart_read_byte(uint8_t *out); /* non-blocking; returns 1 if byte read */

/* -------------------------------- SPI ------------------------------------- */
/**
 * Full-duplex SPI transfer.
 * - tx may be NULL (send 0xFF)
 * - rx may be NULL (discard)
 * Returns 0 on success, negative on error.
 */
int platform_spi_transfer(const uint8_t *tx, uint8_t *rx, size_t len);

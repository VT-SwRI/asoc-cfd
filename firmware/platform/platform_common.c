#include "platform.h"
#include <stdarg.h>
#include <stdio.h>

#if PLATFORM_TARGET_MOCK
#include <time.h>
#endif

static uint32_t s_ms = 0;

void platform_init(void) {
#if PLATFORM_TARGET_MOCK
  s_ms = 0;
#else
  /* TODO(A3PE): initialize CoreUARTapb / timer / SPI cores here. */
#endif
}

void platform_delay_us(uint32_t us) {
#if PLATFORM_TARGET_MOCK
  /* For unit tests we don't need real delays. */
  s_ms += us / 1000u;
#else
  /* TODO(A3PE): implement using a hardware timer or a calibrated loop. */
  (void)us;
#endif
}

uint32_t platform_millis(void) {
  return s_ms;
}

void platform_uart_write(const char *s) {
#if PLATFORM_TARGET_MOCK
  fputs(s, stdout);
  fflush(stdout);
#else
  /* TODO(A3PE): write to CoreUARTapb TX FIFO. */
  (void)s;
#endif
}

void platform_uart_write_n(const char *s, size_t n) {
#if PLATFORM_TARGET_MOCK
  fwrite(s, 1, n, stdout);
  fflush(stdout);
#else
  /* TODO(A3PE): write bytes to UART. */
  (void)s; (void)n;
#endif
}

int platform_uart_read_byte(uint8_t *out) {
#if PLATFORM_TARGET_MOCK
  /* No stdin polling by default. Return 0 (no data). */
  (void)out;
  return 0;
#else
  /* TODO(A3PE): non-blocking RX from CoreUARTapb. */
  (void)out;
  return 0;
#endif
}

int platform_spi_transfer(const uint8_t *tx, uint8_t *rx, size_t len) {
#if PLATFORM_TARGET_MOCK
  /* Mock SPI does nothing: it returns 0x00 for all received bytes. */
  if (rx) {
    for (size_t i = 0; i < len; i++) rx[i] = 0x00;
  }
  (void)tx;
  return 0;
#else
  /* TODO(A3PE): implement via CoreSPI (APB) or bit-banged GPIO. */
  (void)tx; (void)rx; (void)len;
  return -1;
#endif
}

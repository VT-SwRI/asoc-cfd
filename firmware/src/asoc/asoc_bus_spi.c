#include "asoc_bus_spi.h"
#include "platform/platform.h"

static asoc_status_t bus_spi_write(asoc_bus_t *bus, uint16_t addr, const uint8_t *data, size_t n) {
  asoc_bus_spi_ctx_t *ctx = (asoc_bus_spi_ctx_t*)bus->ctx;
  uint8_t hdr[2];
  hdr[0] = (uint8_t)(0x80u | ((addr >> 8) & ctx->addr_hi_mask));
  hdr[1] = (uint8_t)(addr & 0xFFu);

  if (platform_spi_transfer(hdr, NULL, sizeof(hdr)) != 0) return ASOC_EIO;
  if (platform_spi_transfer(data, NULL, n) != 0) return ASOC_EIO;
  return ASOC_OK;
}

static asoc_status_t bus_spi_read(asoc_bus_t *bus, uint16_t addr, uint8_t *data, size_t n) {
  asoc_bus_spi_ctx_t *ctx = (asoc_bus_spi_ctx_t*)bus->ctx;
  uint8_t hdr[2];
  hdr[0] = (uint8_t)(0x00u | ((addr >> 8) & ctx->addr_hi_mask));
  hdr[1] = (uint8_t)(addr & 0xFFu);

  if (platform_spi_transfer(hdr, NULL, sizeof(hdr)) != 0) return ASOC_EIO;
  if (platform_spi_transfer(NULL, data, n) != 0) return ASOC_EIO;
  return ASOC_OK;
}

asoc_bus_t asoc_bus_spi_make(asoc_bus_spi_ctx_t *ctx) {
  asoc_bus_t b;
  b.ctx = ctx;
  b.write = bus_spi_write;
  b.read  = bus_spi_read;
  return b;
}

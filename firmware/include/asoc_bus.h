#pragma once
#include <stddef.h>
#include <stdint.h>
#include "asoc_error.h"

typedef struct asoc_bus asoc_bus_t;

typedef asoc_status_t (*asoc_bus_write_fn)(asoc_bus_t *bus, uint16_t addr, const uint8_t *data, size_t n);
typedef asoc_status_t (*asoc_bus_read_fn) (asoc_bus_t *bus, uint16_t addr, uint8_t *data, size_t n);

struct asoc_bus {
  void *ctx;
  asoc_bus_write_fn write;
  asoc_bus_read_fn  read;
};

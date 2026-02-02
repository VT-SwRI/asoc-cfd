#pragma once
#include <stdint.h>

typedef enum {
  ASOC_OK = 0,
  ASOC_EINVAL = -1,
  ASOC_ETIMEOUT = -2,
  ASOC_EIO = -3,
  ASOC_ESTATE = -4,
  ASOC_ENOTSUP = -5,
} asoc_status_t;

static inline const char* asoc_status_str(asoc_status_t s) {
  switch (s) {
    case ASOC_OK: return "OK";
    case ASOC_EINVAL: return "EINVAL";
    case ASOC_ETIMEOUT: return "ETIMEOUT";
    case ASOC_EIO: return "EIO";
    case ASOC_ESTATE: return "ESTATE";
    case ASOC_ENOTSUP: return "ENOTSUP";
    default: return "UNKNOWN";
  }
}

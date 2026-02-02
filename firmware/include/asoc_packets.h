#pragma once
#include <stddef.h>
#include <stdint.h>
#include "asoc_error.h"

/* A compact, endian-stable packet header for streaming over FT60x / UART / etc. */
typedef struct __attribute__((packed)) {
  uint32_t magic;      /* 'ASOC' */
  uint16_t version;    /* packet version */
  uint16_t type;       /* 1=waveform, 2=features, 3=log, ... */
  uint32_t seq;        /* monotonically increasing */
  uint32_t payload_len;
  uint32_t crc32;      /* CRC over header (crc32 field treated as 0) + payload */
} asoc_pkt_hdr_t;

typedef enum {
  ASOC_PKT_WAVEFORM = 1,
  ASOC_PKT_FEATURES = 2,
  ASOC_PKT_LOG      = 3,
} asoc_pkt_type_t;

#define ASOC_PKT_MAGIC 0x434F5341u /* 'ASOC' little-endian */
#define ASOC_PKT_VERSION 1u

asoc_status_t asoc_pkt_build(asoc_pkt_hdr_t *hdr,
                             asoc_pkt_type_t type,
                             uint32_t seq,
                             const void *payload,
                             size_t payload_len);

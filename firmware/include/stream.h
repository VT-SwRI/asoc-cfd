#pragma once
#include <stddef.h>
#include <stdint.h>
#include "asoc_error.h"
#include "ringbuf.h"
#include "asoc_packets.h"

/**
 * Byte-stream egress helper.
 *
 * On real hardware, this module should be backed by your highest bandwidth link
 * (e.g., FT60x FIFO interface in the FPGA) rather than UART. The current default
 * implementation flushes via platform UART for simplicity.
 */
typedef struct {
  ringbuf_t rb;
  uint8_t *storage;
  size_t storage_len;
  uint32_t seq;
} stream_t;

void stream_init(stream_t *s, uint8_t *storage, size_t storage_len);

/* Queue a packet header + payload. */
asoc_status_t stream_send(stream_t *s, asoc_pkt_type_t type, const void *payload, size_t payload_len);

/* Flush any queued bytes to the platform output. Call often from the main loop. */
void stream_service(stream_t *s);

#include "stream.h"
#include "platform/platform.h"
#include <string.h>

void stream_init(stream_t *s, uint8_t *storage, size_t storage_len) {
  s->storage = storage;
  s->storage_len = storage_len;
  s->seq = 0;
  ringbuf_init(&s->rb, storage, storage_len);
}

asoc_status_t stream_send(stream_t *s, asoc_pkt_type_t type, const void *payload, size_t payload_len) {
  asoc_pkt_hdr_t hdr;
  asoc_status_t st = asoc_pkt_build(&hdr, type, s->seq++, payload, payload_len);
  if (st != ASOC_OK) return st;

  if (!ringbuf_push(&s->rb, (const uint8_t*)&hdr, sizeof(hdr))) return ASOC_EIO;
  if (payload_len) {
    if (!ringbuf_push(&s->rb, (const uint8_t*)payload, payload_len)) return ASOC_EIO;
  }
  return ASOC_OK;
}

void stream_service(stream_t *s) {
  uint8_t tmp[64];
  size_t n = ringbuf_pop(&s->rb, tmp, sizeof(tmp));
  if (n) platform_uart_write_n((const char*)tmp, n);
}

#include "ringbuf.h"

static inline size_t rb_mask(const ringbuf_t *rb) { return rb->cap - 1u; }

void ringbuf_init(ringbuf_t *rb, uint8_t *storage, size_t capacity) {
  rb->buf = storage;
  rb->cap = capacity;
  rb->head = 0;
  rb->tail = 0;
}

size_t ringbuf_available(const ringbuf_t *rb) {
  return (rb->head - rb->tail) & rb_mask(rb);
}

size_t ringbuf_free(const ringbuf_t *rb) {
  return (rb->cap - 1u) - ringbuf_available(rb);
}

bool ringbuf_push(ringbuf_t *rb, const uint8_t *data, size_t n) {
  if (ringbuf_free(rb) < n) return false;
  for (size_t i = 0; i < n; i++) {
    rb->buf[rb->head] = data[i];
    rb->head = (rb->head + 1u) & rb_mask(rb);
  }
  return true;
}

size_t ringbuf_pop(ringbuf_t *rb, uint8_t *out, size_t n) {
  size_t avail = ringbuf_available(rb);
  if (n > avail) n = avail;
  for (size_t i = 0; i < n; i++) {
    out[i] = rb->buf[rb->tail];
    rb->tail = (rb->tail + 1u) & rb_mask(rb);
  }
  return n;
}

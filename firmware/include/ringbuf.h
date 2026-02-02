#pragma once
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef struct {
  uint8_t *buf;
  size_t cap;    /* capacity in bytes (must be power of 2 for fastest path) */
  size_t head;   /* write index */
  size_t tail;   /* read index */
} ringbuf_t;

void ringbuf_init(ringbuf_t *rb, uint8_t *storage, size_t capacity);
size_t ringbuf_available(const ringbuf_t *rb); /* bytes readable */
size_t ringbuf_free(const ringbuf_t *rb);      /* bytes writable */
bool ringbuf_push(ringbuf_t *rb, const uint8_t *data, size_t n);
size_t ringbuf_pop(ringbuf_t *rb, uint8_t *out, size_t n);

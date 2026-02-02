#include "asoc_asic.h"

static void shadow_set(asoc_asic_t *a, uint16_t addr, uint32_t v) {
#if ASOC_SHADOW_REGISTERS
  for (size_t i = 0; i < a->shadow_len; i++) {
    if (a->shadow[i].addr == addr) { a->shadow[i].val = v; return; }
  }
  if (a->shadow_len < (sizeof(a->shadow)/sizeof(a->shadow[0]))) {
    a->shadow[a->shadow_len].addr = addr;
    a->shadow[a->shadow_len].val  = v;
    a->shadow_len++;
  }
#else
  (void)a; (void)addr; (void)v;
#endif
}

static bool shadow_get(const asoc_asic_t *a, uint16_t addr, uint32_t *out) {
#if ASOC_SHADOW_REGISTERS
  for (size_t i = 0; i < a->shadow_len; i++) {
    if (a->shadow[i].addr == addr) { *out = a->shadow[i].val; return true; }
  }
#else
  (void)a; (void)addr; (void)out;
#endif
  return false;
}

void asoc_asic_init(asoc_asic_t *a, asoc_bus_t bus) {
  a->bus = bus;
#if ASOC_SHADOW_REGISTERS
  a->shadow_len = 0;
#endif
}

asoc_status_t asoc_asic_write_u32(asoc_asic_t *a, uint16_t addr, uint32_t v) {
  uint8_t le[4] = { (uint8_t)(v & 0xFFu), (uint8_t)((v>>8)&0xFFu), (uint8_t)((v>>16)&0xFFu), (uint8_t)((v>>24)&0xFFu) };
  if (!a->bus.write) return ASOC_ENOTSUP;
  asoc_status_t st = a->bus.write(&a->bus, addr, le, sizeof(le));
  if (st == ASOC_OK) shadow_set(a, addr, v);
  return st;
}

asoc_status_t asoc_asic_read_u32(asoc_asic_t *a, uint16_t addr, uint32_t *out) {
  if (a->bus.read) {
    uint8_t le[4] = {0};
    asoc_status_t st = a->bus.read(&a->bus, addr, le, sizeof(le));
    if (st != ASOC_OK) return st;
    *out = (uint32_t)le[0] | ((uint32_t)le[1]<<8) | ((uint32_t)le[2]<<16) | ((uint32_t)le[3]<<24);
    shadow_set(a, addr, *out);
    return ASOC_OK;
  }
  /* No readback: fall back to shadow */
  if (shadow_get(a, addr, out)) return ASOC_OK;
  return ASOC_ENOTSUP;
}

asoc_status_t asoc_asic_reset(asoc_asic_t *a) {
  /* Placeholder: on real hardware this may be a dedicated pin or a specific register. */
  (void)a;
  return ASOC_OK;
}

asoc_status_t asoc_asic_apply_default_config(asoc_asic_t *a) {
  /* Placeholder defaults. Replace with the actual NALU register set for your board. */
  (void)a;
  return ASOC_OK;
}

#include "asoc_packets.h"
#include "crc32.h"
#include <string.h>

asoc_status_t asoc_pkt_build(asoc_pkt_hdr_t *hdr,
                             asoc_pkt_type_t type,
                             uint32_t seq,
                             const void *payload,
                             size_t payload_len) {
  if (!hdr) return ASOC_EINVAL;

  hdr->magic = ASOC_PKT_MAGIC;
  hdr->version = (uint16_t)ASOC_PKT_VERSION;
  hdr->type = (uint16_t)type;
  hdr->seq = seq;
  hdr->payload_len = (uint32_t)payload_len;
  hdr->crc32 = 0;

#if ASOC_ENABLE_CRC32
  uint32_t crc = 0;
  crc = crc32_ieee(hdr, sizeof(*hdr), crc);
  if (payload && payload_len) crc = crc32_ieee(payload, payload_len, crc);
  hdr->crc32 = crc;
#else
  (void)payload; (void)payload_len;
#endif

  return ASOC_OK;
}

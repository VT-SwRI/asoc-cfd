#pragma once
#include <stddef.h>
#include <stdint.h>

/* Ethernet/ZIP CRC-32 (poly 0x04C11DB7, reflected 0xEDB88320). */
uint32_t crc32_ieee(const void *data, size_t len, uint32_t seed);

/***************************************************************************//**
 * (c) Copyright 2012-2015 Microsemi SoC Products Group.  All rights reserved.
 * crc32 header file.
 *
 * SVN $Revision: 7708 $
 * SVN $Date: 2015-08-28 15:31:15 +0530 (Fri, 28 Aug 2015) $
 *
 ******************************************************************************/
 
#ifndef ETHERNET_MAC_CRC32_H
#define ETHERNET_MAC_CRC32_H    1

#include <cpu_types.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Calculates 32 bits CRC value of given data.
 */
uint32_t
MAC_crc32
(
    const uint32_t value,
    const uint8_t * data,
    const uint32_t data_length
);

/**
 * Calculates 32 bits CRC value of given data, using standard Ethernet CRC 
 * function.
 */
uint32_t
MAC_ethernet_crc
(
    const uint8_t * ethernet_data,
    const uint32_t eth_data_length
);

#ifdef __cplusplus
}
#endif

#endif    /* ETHERNET_MAC_CRC32_H */

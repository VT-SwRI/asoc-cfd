/***************************************************************************//**
 * (c) Copyright 2012-2015 Microsemi SoC Products Group.  All rights reserved.
 *
 * PHY MDIO access methods.
 *
 *
 * SVN $Revision: 7708 $
 * SVN $Date: 2015-08-28 15:31:15 +0530 (Fri, 28 Aug 2015) $
 *
 ******************************************************************************/
#ifndef PHY_MDIO_H
#define PHY_MDIO_H      1

#ifdef __cplusplus
extern "C" {
#endif

uint16_t
MAC_MDIO_read
(
    const uint32_t mac_base_addr,
    const uint8_t phy_addr,
    const uint8_t regad
);

void
MAC_MDIO_write
(
    const uint32_t mac_base_addr,
    const uint8_t phy_addr,
    const uint8_t regad,
    const uint16_t data
);

#ifdef __cplusplus
}
#endif

#endif  /* PHY_MDIO_H */

/***************************************************************************//**
 * (c) Copyright 2012-2015 Microsemi SoC Products Group.  All rights reserved.
 *
 * PHY access methods.
 *
 *
 * SVN $Revision: 7708 $
 * SVN $Date: 2015-08-28 15:31:15 +0530 (Fri, 28 Aug 2015) $
 *
 ******************************************************************************/

#ifndef PHY_H
#define PHY_H    1

#include "core10100_ahbapb.h"

#ifdef __cplusplus
extern "C" {
#endif 

/***************************************************************************//**
 * Initialize the PHY.
 */
void
MAC_phy_init
(
    const uint32_t mac_base_addr,
    const uint8_t phy_addr,
    const uint8_t allowed_link_speeds
);

/***************************************************************************//**
 * Returns link status.
 *
 * @return #MAC_LINK_STATUS_LINK if link is up.
 */
uint8_t
MAC_phy_get_link_status
(
    const uint32_t mac_base_addr,
    const uint8_t phy_addr,
    mac_speed_t * speed,
    uint8_t * fullduplex
);

/***************************************************************************//**
 * Sets/Clears the phy loop back mode, based on the enable value
 */
void
MAC_phy_set_loopback
(
    const uint32_t mac_base_addr,
    const uint8_t phy_addr
);

#ifdef __cplusplus
}
#endif

#endif /* PHY_H */

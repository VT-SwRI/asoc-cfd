/***************************************************************************//**
 * (c) Copyright 2012-2015 Microsemi SoC Products Group.  All rights reserved.
 *
 * PHY access methods for Micrel KSZ8051MNL.
 *
 * SVN $Revision: 7719 $
 * SVN $Date: 2015-09-01 19:25:45 +0530 (Tue, 01 Sep 2015) $
 *
 ******************************************************************************/

#include "hal.h"
#include "hal_assert.h"

#include "phy.h"
#include "phy_mdio.h"
#include "core10100_ahbapb.h"

/*
 * PHY registers.
 */
#define PHYREG_MIIMCR           ((uint8_t)0x00U)    /**< MII Management Control Register */

#define MIIMCR_RESET                       (1U << 15U)
#define MIIMCR_LOOPBACK                    (1U << 14U)
#define MIIMCR_SPEED_SELECT                (1U << 13U)
#define MIIMCR_ENABLE_AUTONEGOTIATION      (1U << 12U)
#define MIIMCR_RESTART_AUTONEGOTIATION     (1U << 9U)
#define MIIMCR_DUPLEX_MODE                 (1U << 8U)
#define MIIMCR_COLLISION_TEST              (1u << 7U)

#define PHYREG_MIIMSR           0x01U    /**< MII Management Status Register */
#define MIIMSR_ANC              (1U << 5U)    /**< Auto-Negotiation Completed. */

#define PHYREG_ANAR             0x04U    /**< Auto-Negotiation Advertisement Register */
#define ANAR_100FD              (1U << 8U)
#define ANAR_100HD              (1U << 7U)
#define ANAR_10FD               (1U << 6U)
#define ANAR_10HD               (1U << 5U)

#define PHYREG_MPCTRL1                        0x1EU    /**< Micrel PHYCTRL1 */

/*
 * Mask of the "Operation Mode Indication" bits in the PHY Control 1 register.
 * The value of these bits is used retrieve the current link status.
 */
#define OPERATION_MODE_MASK     0x07U

/*
 * Data structure used to build a look-up table of the link status indexed on
 * the value of the PHY's "Operation Mode Indication" register field.
 */
typedef struct phy_link_status
{
    mac_speed_t speed;
    uint8_t duplex;
    uint8_t link_up;
} phy_link_status_t;

/***************************************************************************//**
 * Initialize and configure the PHY. See "phy.h" for details.
 */
void
MAC_phy_init
(
    const uint32_t mac_base_addr,
    const uint8_t phy_addr,
    const uint8_t allowed_link_speeds
)
{
    uint16_t phy_ctlr_reg;
    uint16_t phy_anar_reg;
    uint16_t phy_in_reset;

    /*
     * Reset the PHY
     */
    MAC_MDIO_write(mac_base_addr, phy_addr, PHYREG_MIIMCR, MIIMCR_RESET);
    do
    {
        phy_in_reset = MAC_MDIO_read(mac_base_addr, phy_addr, PHYREG_MIIMCR) & MIIMCR_RESET;
    }
    while (phy_in_reset != 0U);

    phy_anar_reg = MAC_MDIO_read(mac_base_addr, phy_addr, PHYREG_ANAR);
    phy_anar_reg &= ~(ANAR_100FD | ANAR_100HD | ANAR_10FD | ANAR_10HD);

    /*
     * Configure duplex mode and link speed.
     */
    phy_ctlr_reg = MIIMCR_COLLISION_TEST;

    if ((allowed_link_speeds & MAC_ANEG_10M_FD) != 0U)
    {
        phy_anar_reg |= ANAR_10FD;
        phy_ctlr_reg |= MIIMCR_ENABLE_AUTONEGOTIATION | MIIMCR_RESTART_AUTONEGOTIATION;
    }

    if ((allowed_link_speeds & MAC_ANEG_10M_HD) != 0U)
    {
        phy_anar_reg |= ANAR_10HD;
        phy_ctlr_reg |= MIIMCR_ENABLE_AUTONEGOTIATION | MIIMCR_RESTART_AUTONEGOTIATION;
    }

    if ((allowed_link_speeds & MAC_ANEG_100M_FD) != 0U)
    {
        phy_anar_reg |= ANAR_100FD;
        phy_ctlr_reg |= MIIMCR_ENABLE_AUTONEGOTIATION | MIIMCR_RESTART_AUTONEGOTIATION;
    }

    if ((allowed_link_speeds & MAC_ANEG_100M_HD) != 0U)
    {
        phy_anar_reg |= ANAR_100HD;
        phy_ctlr_reg |= MIIMCR_ENABLE_AUTONEGOTIATION | MIIMCR_RESTART_AUTONEGOTIATION;
    }

    MAC_MDIO_write(mac_base_addr, phy_addr, PHYREG_ANAR, phy_anar_reg);
    MAC_MDIO_write(mac_base_addr, phy_addr, PHYREG_MIIMCR, phy_ctlr_reg);

    /*
     * Wait for auto-negotiation to complete.
     */
    {
        int32_t cnt;
        int32_t exit = 1;
        uint16_t reg;

        for (cnt = 0; (cnt < 10000) && (exit != 0); cnt++)
        {
            reg = MAC_MDIO_read(mac_base_addr, phy_addr, PHYREG_MIIMSR);

            if ((reg & MIIMSR_ANC) != 0U)
            {
                exit = 0;
            }
        }
    }
}

/***************************************************************************//**
 * Returns link status. See "phy.h" for details.
 */
uint8_t
MAC_phy_get_link_status
(
    const uint32_t mac_base_addr,
    const uint8_t phy_addr,
    mac_speed_t * speed,
    uint8_t * fullduplex
)
{
    uint16_t op_mode;
    /*
     * Look-up table translating 3-bit "Operation Mode Indication" found in
     * bits [2:0] of PHY Control 1 register into link status.
     */
    const phy_link_status_t operating_mode_lut[8] =
    {
        {MAC_INVALID_SPEED, MAC_HALF_DUPLEX, MAC_LINK_DOWN},    /* Auto negotiating. */
        {MAC_10MBPS, MAC_HALF_DUPLEX, MAC_LINK_UP},             /* 10Mbps, half-duplex. */
        {MAC_100MBPS, MAC_HALF_DUPLEX, MAC_LINK_UP},            /* 100Mbps, half-duplex. */
        {MAC_INVALID_SPEED, MAC_HALF_DUPLEX, MAC_LINK_DOWN},    /* Reserved. */
        {MAC_INVALID_SPEED, MAC_HALF_DUPLEX, MAC_LINK_DOWN},    /* Reserved. */
        {MAC_10MBPS, MAC_FULL_DUPLEX, MAC_LINK_UP},             /* 10Mbps, full-duplex. */
        {MAC_100MBPS, MAC_FULL_DUPLEX, MAC_LINK_UP},            /* 100Mbps, full-duplex. */
        {MAC_INVALID_SPEED, MAC_HALF_DUPLEX, MAC_LINK_DOWN}     /* Reserved. */
    };


    op_mode = MAC_MDIO_read(mac_base_addr, phy_addr, PHYREG_MPCTRL1) & OPERATION_MODE_MASK;
    *speed = operating_mode_lut[op_mode].speed;
    *fullduplex = operating_mode_lut[op_mode].duplex;

    return operating_mode_lut[op_mode].link_up;
}

/***************************************************************************//**
 * Puts the PHY in Loop-back mode. See "phy.h" for details.
 */
void
MAC_phy_set_loopback
(
    const uint32_t mac_base_addr,
    const uint8_t phy_addr
)
{
    uint16_t reg;

    reg = MIIMCR_LOOPBACK | MIIMCR_SPEED_SELECT | MIIMCR_DUPLEX_MODE;
    MAC_MDIO_write(mac_base_addr, phy_addr, PHYREG_MIIMCR, reg);
}

/***************************************************************************//**
 * (c) Copyright 2012-2015 Microsemi SoC Products Group.  All rights reserved.
 *
 * PHY MDIO access methods.
 *
 * SVN $Revision: 7708 $
 * SVN $Date: 2015-08-28 15:31:15 +0530 (Fri, 28 Aug 2015) $
 *
 ******************************************************************************/

#include "hal.h"
#include "core10100_ahbapb.h"
#include "core10100_ahbapb_regs.h"
#include "phy.h"
#include "phy_mdio.h"

#ifdef __cplusplus
extern "C" {
#endif 

/***************************** MDIO FUNCTIONS *********************************/

/********************************* Defines ************************************/
#define MDIO_START_BITS           0x00004000U
#define MDIO_READ_BITS            0x00002000U
#define MDIO_WRITE_BITS           0x00001002U
#define MDIO_ADDR_OFFSET          7U
#define MDIO_ADDR_MASK            0x00000f80U
#define MDIO_REG_ADDR_OFFSET      2U
#define MDIO_REG_ADDR_MASK        0x0000007cU
#define PREAMBLECOUNT             32
#define ONEMICROSECOND            20

typedef enum {
    MDIO_CMD_READ,
    MDIO_CMD_WRITE
} mdio_cmd_t;


static void
management_clock
(
    const uint32_t mac_base_addr,
    const int32_t clock
);

static void
send_cmd
(
    const uint32_t mac_base_addr,
    const uint8_t phy_addr,
    const uint8_t regad,
    const mdio_cmd_t mdio_cmd
);

/***************************************************************************//**
 * Set clock high or low.
 */
static void
management_clock
(
    const uint32_t mac_base_addr,
    const int32_t clock
)
{
    volatile int32_t delay_idx = 0;
    
    HAL_set_32bit_reg_field(mac_base_addr, CSR9_MDC, (uint32_t)clock);

    /* delay for 1us */
    while (delay_idx < ONEMICROSECOND)
    {
        /*
         * Increment delay_idx via a non-volatile variable to avoid delay++
         * construct resulting in a compliance violation (volatile variable in 
         * complex expression).
         */
        int32_t temp_idx = delay_idx;
        temp_idx++;
        delay_idx = temp_idx;
    }
}


/***************************************************************************//**
 * Send read or write command to PHY.
 */
static void
send_cmd
(
    const uint32_t mac_base_addr,
    const uint8_t phy_addr,
    const uint8_t regad,
    const mdio_cmd_t mdio_cmd
)
{
    int32_t idx;
    uint16_t mask;
    uint16_t data;

    /* enable MII output */
    HAL_set_32bit_reg_field(mac_base_addr, CSR9_MII, 1U);

    /* send 32 1's preamble */
    HAL_set_32bit_reg_field(mac_base_addr, CSR9_MDO, 1U);

    for (idx = 0; idx < PREAMBLECOUNT; idx++)
    {
        management_clock(mac_base_addr, 0);
        management_clock(mac_base_addr, 1);
    }

    /* calculate data bits */
    data = MDIO_START_BITS |
        (( mdio_cmd == MDIO_CMD_READ ) ? MDIO_READ_BITS : MDIO_WRITE_BITS ) |
        (((uint16_t)phy_addr << MDIO_ADDR_OFFSET) & MDIO_ADDR_MASK) |
        (((uint16_t)regad << MDIO_REG_ADDR_OFFSET) & MDIO_REG_ADDR_MASK);

    /* send out */
    mask = 0x8000U;
    while (mask > 0U)
    {
        if ((mask == 0x2U) && (mdio_cmd == MDIO_CMD_READ))
        {
            /* enable MII input */
            HAL_set_32bit_reg_field(mac_base_addr, CSR9_MII, 0U);
        }
        
        management_clock(mac_base_addr, 0);
        
        /* prepare MDO */
        HAL_set_32bit_reg_field(mac_base_addr, CSR9_MDO, (uint32_t)((mask & data) != 0U ? 1U : 0U));
        management_clock(mac_base_addr, 1);
        mask = mask >> 1U;
    }
}

/***************************************************************************//**
 * Reads a PHY register.
 */
uint16_t
MAC_MDIO_read
(
    const uint32_t mac_base_addr,
    const uint8_t phy_addr,
    const uint8_t regad
)
{
    uint16_t mask = 0x8000U;
    uint16_t data = 0U;

    send_cmd(mac_base_addr, phy_addr, regad, MDIO_CMD_READ);

    /* read data */
    while (mask > 0U)
    {
        management_clock(mac_base_addr, 0);

        /* read MDI */
        if (HAL_get_32bit_reg_field(mac_base_addr, CSR9_MDI) != 0U)
        {
            data |= mask;
        }
        management_clock(mac_base_addr, 1);
        mask = mask >> 1U;
    }

    management_clock(mac_base_addr, 0);

    return data;
}

/***************************************************************************//**
 * Writes to a PHY register.
 */
void
MAC_MDIO_write
(
    const uint32_t mac_base_addr,
    const uint8_t phy_addr,
    const uint8_t regad,
    const uint16_t data
)
{
    uint16_t mask = 0x8000U;

    send_cmd(mac_base_addr, phy_addr, regad, MDIO_CMD_WRITE);

    /* write data */
    while (mask > 0U)
    {
        management_clock(mac_base_addr, 0);

        /* prepare MDO */
        HAL_set_32bit_reg_field(mac_base_addr,
                                CSR9_MDO,
                                (uint32_t)((mask & data) != 0U ? 1U : 0U));

        management_clock(mac_base_addr, 1);
        mask = mask >> 1U;
    }

    management_clock(mac_base_addr, 0);
}

#ifdef __cplusplus
}
#endif

/******************************** END OF FILE *********************************/


/*******************************************************************************
 * (c) Copyright 2012-2015 Microsemi SoC Products Group.  All rights reserved.
 *
 * Core10100_AHBAPB driver implementation.
 *
 *
 * SVN $Revision: 7800 $
 * SVN $Date: 2015-09-14 17:52:50 +0530 (Mon, 14 Sep 2015) $
 *
*******************************************************************************/
#include <string.h>

#include "hal.h"
#include "hal_assert.h"

#include "crc32.h"
#include "core10100_ahbapb.h"
#include "core10100_ahbapb_regs.h"
#include "core10100_ahbapb_desc.h"

#include "phy.h"
#include "phy_mdio.h"

#include "core10100_ahbapb_conf.h"

#ifdef __cplusplus
extern "C" {
#endif
/**************************** INTERNAL DEFINES ********************************/

#define INVALID_INDEX               (-1)

#define DESC_OWNED_BY_DRIVER        ((uint32_t)0U)
#define TX_DESC_AVAILABLE           ((uint32_t)0xFFFFFFFFU)

#define MAC_EVENT_NONE              ((uint32_t)0U)
#define MAC_EVENT_PACKET_SEND       ((uint32_t)1U)
#define MAC_EVENT_PACKET_RECEIVED   ((uint32_t)2U)

#define PHY_ADDRESS_MIN             0U
#define PHY_ADDRESS_MAX             31U

/**
 * Descriptor byte ordering mode.
 * 1 - Big-endian mode used for data descriptors
 * 0 - Little-endian mode used for data descriptors
 */
#define MAC_DESCRIPTOR_BYTE_ORDERING_MODE   LITTLEENDIAN

/**
 * Big/little endian.
 * Selects the byte-ordering mode used by the data buffers.
 * 1 - Big-endian mode used for the data buffers
 * 0 - Little-endian mode used for the data buffers
 */
#define MAC_BUFFER_BYTE_ORDERING_MODE       LITTLEENDIAN

#define SETUP_FRAME_LENGTH      192U
#define MAC_ADDR_LENGTH         6U

#define PERFECT_FILTERING       1U
#define HASH_FILTERING          2U

/**************************** INTERNAL DATA ***********************************/


/**************************** INTERNAL FUNCTIONS ******************************/

static uint8_t probe_phy
(
    const mac_instance_t * instance
);

static void send_setup_frame
(
    const mac_instance_t *instance,
    const uint8_t * setup_frame,
    uint32_t option
);

static void stop_transmission(const mac_instance_t * instance);
static void start_transmission(const mac_instance_t * instance);
static void stop_receiving(const mac_instance_t * instance);
static void start_receiving(const mac_instance_t * instance);

static void enable_tx_interrupt(const mac_instance_t * instance);
static void disable_tx_interrupt(const mac_instance_t * instance);
static void enable_rx_interrupt(const mac_instance_t * instance);
static void disable_rx_interrupt(const mac_instance_t * instance);
static void txpkt_handler(mac_instance_t * instance);
static void rxpkt_handler(mac_instance_t * instance);

static void update_tx_statistics(mac_instance_t * instance, int16_t tx_desc_index);
static void update_rx_statistics(mac_instance_t * instance, int16_t rx_desc_index);

static int16_t increment_tx_index(int16_t index);
static int16_t increment_rx_index(int16_t index);

static uint32_t adjust_tx_pkt_length(uint32_t tx_length);

static void config_mac_hw
(
    const mac_instance_t * instance,
    const mac_cfg_t * cfg
);

static uint32_t get_rx_frame_errors
(
    const mac_instance_t * instance,
    uint32_t descriptor0
);

static uint32_t
get_rx_packet_length
(
    uint32_t descriptor0
);

/*------------------------------------------------------------------------------
 * Test harness global variables.
 */
#ifdef MSCC_CORE10100_TEST_HARNESS_FORCE_RX_ERRORS
volatile uint32_t g_core10100_test_harness_force_rx_error = 0U;
#endif


/***************************************************************************//**
 See core10100_ahbapb.h for details of how to use this function
*/
void
MAC_cfg_struct_def_init
(
    mac_cfg_t * cfg
)
{
    const uint8_t default_mac_addr[6] = { DEFAULT_MAC_ADDRESS };

    ASSERT(NULL != cfg);

    if (NULL != cfg)
    {
        cfg->link_speed         = MAC_ANEG_ALL_SPEEDS;
        cfg->loopback           = MAC_DISABLE;
        cfg->receive_all        = MAC_DISABLE;
        cfg->tx_threshold_mode  = MAC_CFG_TX_THRESHOLD_100MB_MODE;
        cfg->store_and_forward  = MAC_ENABLE;
        cfg->threshold_control  = MAC_CFG_THRESHOLD_CONTROL_00;
        cfg->pass_all_multicast = MAC_ENABLE;
        cfg->promiscous_mode    = MAC_DISABLE;
        cfg->pass_badframe      = MAC_DISABLE;
        cfg->phy_addr           = 0x00u;

        /* Set default MAC address */
        (void)memcpy(cfg->mac_addr, default_mac_addr, 6);
    }
}

/***************************************************************************//**
 See core10100_ahbapb.h for details of how to use this function
*/
void
MAC_init
(
    mac_instance_t * instance,
    addr_t base,
    const mac_cfg_t * cfg
)
{
    HAL_ASSERT(base != 0);
    HAL_ASSERT((base & 0x3u) == 0U);
    HAL_ASSERT(instance != NULL);

    if(instance != NULL)
    {
        mac_speed_t speed = MAC_INVALID_SPEED;
        uint8_t fullduplex = MAC_FULL_DUPLEX;
        int32_t ring_idx;
        uint32_t soft_reset_bit;

        /* Try to reset Core10100 */
        HAL_set_32bit_reg_field(base, CSR0_SWR, 1U);

        /*Wait for the reset to complete. Indicated by self clearing of CSRO_SWR*/
        do
        {
            soft_reset_bit = HAL_get_32bit_reg_field(base, CSR0_SWR);
        }
        while (soft_reset_bit!= 0U);

        HAL_set_32bit_reg_field(base, CSR5_UNF, 1U);

        /* Check reset values of some registers to control
           base address validity
        */
        HAL_ASSERT(HAL_get_32bit_reg(base, CSR0) == 0xFE000000U);
        HAL_ASSERT(HAL_get_32bit_reg(base, CSR5) == 0xF0000000U);
        HAL_ASSERT(HAL_get_32bit_reg(base, CSR6) == 0x32000040U);

        /* Clear interrupts */
        HAL_set_32bit_reg(base, CSR5, CSR5_INT_BITS);

        /* Instance setup */
        (void)memset(instance, 0, sizeof(instance));

        instance->base_address = base;

        /*
         * Initialize the receive descriptors chain.
         */
        for (ring_idx = 0; ring_idx < MAC_RX_RING_SIZE; ring_idx++)
        {
            instance->rx_descriptors[ring_idx].descriptor_0 = 0U;
            instance->rx_descriptors[ring_idx].descriptor_1 = RDES1_RCH;
            if ((MAC_RX_RING_SIZE - 1) == ring_idx)
            {
                instance->rx_descriptors[ring_idx].buffer_2 = (uint32_t)&instance->rx_descriptors[0];
            }
            else
            {
                instance->rx_descriptors[ring_idx].buffer_2 = (uint32_t)&instance->rx_descriptors[ring_idx + 1];
            }
        }

        /*
         * Initialize the transmit descriptors chain.
         */
        for (ring_idx = 0; ring_idx < MAC_TX_RING_SIZE; ++ring_idx)
        {
            instance->tx_descriptors[ring_idx].descriptor_0 = 0U;
            instance->tx_descriptors[ring_idx].descriptor_1 = TDES1_TCH;
            if ((MAC_TX_RING_SIZE - 1) == ring_idx)
            {
                instance->tx_descriptors[ring_idx].buffer_2 = (uint32_t)&instance->tx_descriptors[0];
            }
            else
            {
                instance->tx_descriptors[ring_idx].buffer_2 = (uint32_t)&instance->tx_descriptors[ring_idx + 1];
            }
        }

        /* Initialize Tx descriptors related variables. */
        instance->first_tx_index = INVALID_INDEX;
        instance->last_tx_index = INVALID_INDEX;
        instance->next_free_tx_index = 0;

        /* Initialize Rx descriptors related variables. */
        instance->next_free_rx_desc_index = 0;
        instance->first_rx_desc_index = 0;

        /* Initialize link status monitoring variables. */
        instance->previous_speed = MAC_INVALID_SPEED;
        instance->previous_duplex_mode = MAC_HALF_DUPLEX;

        /* Configurable settings */
        HAL_set_32bit_reg_field(base, CSR0_DBO, (uint32_t)MAC_DESCRIPTOR_BYTE_ORDERING_MODE);
        HAL_set_32bit_reg_field(base, CSR0_PBL, (uint32_t)MAC_PROGRAMMABLE_BURST_LENGTH);
        HAL_set_32bit_reg_field(base, CSR0_BLE, (uint32_t)MAC_BUFFER_BYTE_ORDERING_MODE);
        HAL_set_32bit_reg_field(base, CSR0_BAR, (uint32_t)MAC_BUS_ARBITRATION_SCHEME);

        /* Fixed settings */
        /* No automatic polling */
        HAL_set_32bit_reg_field(base, CSR0_TAP, 0U);

        /* No space between descriptors */
        HAL_set_32bit_reg_field(base, CSR0_DSL, 0U);

#if 0
        HAL_set_32bit_reg_field(base, CSR11_TT, 0U);
        HAL_set_32bit_reg_field(base, CSR11_NTP, 1U);
#endif

#if 1
        /* General-purpose timer works in one-shot mode */
        HAL_set_32bit_reg_field(base, CSR11_CON, 0U);
#else
        /* General-purpose timer works in continuous mode */
        HAL_set_32bit_reg_field(base, CSR11_CON, 1U);
#endif
        /* Start general-purpose timer*/
        HAL_set_32bit_reg_field(base, CSR11_TIM, 0x0000FFFFU);

        /* Disable promiscuous mode */
        HAL_set_32bit_reg_field(base, CSR6_PR, 0U);

        /* Enable store and forward */
        HAL_set_32bit_reg_field(base, CSR6_SF, 1U);

        config_mac_hw(instance, cfg);

        /* Set descriptors */
        HAL_set_32bit_reg(base, CSR3,
            (uint32_t)&(instance->rx_descriptors[0].descriptor_0));
        HAL_set_32bit_reg(base, CSR4,
            (uint32_t)&(instance->tx_descriptors[0].descriptor_0));

        (void)memcpy(instance->local_mac_addr, cfg->mac_addr, 6);

        MAC_set_address_filter(instance, instance->local_mac_addr, 0U);

        /* Detect PHY */
        if(MAC_AUTO_DETECT_PHY_ADDRESS == cfg->phy_addr)
        {
            instance->phy_address = probe_phy(instance);
        }
        else
        {
            instance->phy_address = cfg->phy_addr;
        }
        HAL_ASSERT(instance->phy_address <= PHY_ADDRESS_MAX);

        /* Reset PHY */
        MAC_phy_init(instance->base_address, instance->phy_address, cfg->link_speed);

        if(MAC_ENABLE == cfg->loopback)
        {
            MAC_phy_set_loopback(instance->base_address, instance->phy_address);
        }

        /* Configure MAC according to PHY link status */
        (void)MAC_get_link_status(instance, &speed, &fullduplex);

        /* enable normal interrupts */
        HAL_set_32bit_reg_field(instance->base_address, CSR7_NIE, 1U);
    }
}

/***************************************************************************//**
 See core10100_ahbapb.h for details of how to use this function
*/
uint8_t
MAC_send_pkt
(
    mac_instance_t * instance,
    uint8_t const * tx_buffer,
    uint32_t tx_length,
    void * p_user_data
)
{
    uint8_t error;
    int16_t first_tx_idx;
    int16_t next_free_tx_idx;
    uint32_t ownership;

    HAL_ASSERT(tx_buffer != NULL);
    HAL_ASSERT(tx_length >= 12U);
    HAL_ASSERT(tx_length <= MAC_MAX_PACKET_SIZE);

    /*--------------------------------------------------------------------------
     * Treat this function as a critical section with regard to the tx packet
     * handler interrupt service routine.
     */
    disable_tx_interrupt(instance);

    first_tx_idx = instance->first_tx_index;
    next_free_tx_idx = instance->next_free_tx_index;

    /*--------------------------------------------------------------------------
     * Reclaim a transmit descriptor for packets that have already been sent but
     * for which a transmit interrupt has not occurred yet.
     */
    if (next_free_tx_idx == first_tx_idx)
    {
        ownership = instance->tx_descriptors[first_tx_idx].descriptor_0 & TDES0_OWN;
        if (DESC_OWNED_BY_DRIVER == ownership)
        {
            update_tx_statistics(instance, first_tx_idx);
            if (instance->tx_complete_handler != NULL)
            {
                instance->tx_complete_handler(instance->tx_descriptors[first_tx_idx].caller_info);
            }
            first_tx_idx = increment_tx_index(first_tx_idx);
        }
    }

    /*--------------------------------------------------------------------------
     * Send frame if there is an available transmit descriptor.
     */
    if (next_free_tx_idx != first_tx_idx)
    {
        uint32_t tx_pkt_length;
        mac_tx_descriptor_t volatile * p_tx_desc = &(instance->tx_descriptors[next_free_tx_idx]);

        if (INVALID_INDEX == first_tx_idx)
        {
            first_tx_idx = next_free_tx_idx;
        }
        instance->last_tx_index = next_free_tx_idx;

        tx_pkt_length = adjust_tx_pkt_length(tx_length);

        /* Every buffer can hold a full frame so they are always first and last
           descriptor
        */
        p_tx_desc->descriptor_1 = TDES1_TCH | TDES1_LS | TDES1_FS
                                  | (tx_pkt_length << TDES1_TBS1_OFFSET);
        p_tx_desc->buffer_1 = tx_buffer;
        p_tx_desc->caller_info = p_user_data;
        next_free_tx_idx = increment_tx_index(next_free_tx_idx);

        /* Give ownership of descriptor to Core10100 */
        p_tx_desc->descriptor_0 = TDES0_OWN;

        start_transmission(instance);

        /* transmit poll demand */
        HAL_set_32bit_reg(instance->base_address, CSR1, 1U);

        error = MAC_SUCCESS;
    }
    else
    {
        error = MAC_FAILED;
    }

    /*--------------------------------------------------------------------------
     * Update instance transmit variables and quit critical section.
     */
    instance->first_tx_index = first_tx_idx;
    instance->next_free_tx_index = next_free_tx_idx;

    enable_tx_interrupt(instance);

    return error;
}

/***************************************************************************//**
 See core10100_ahbapb.h for details of how to use this function
*/
uint8_t
MAC_receive_pkt
(
    mac_instance_t * instance,
    uint8_t * rx_buffer,
    void * p_user_data
)
{
    uint8_t error;
    int16_t next_rx_desc_index;
    uint32_t ownership;

    HAL_ASSERT(rx_buffer != NULL);

    disable_rx_interrupt(instance);

    next_rx_desc_index = instance->next_free_rx_desc_index;
    ownership = instance->rx_descriptors[next_rx_desc_index].descriptor_0 & RDES0_OWN;

    if ((DESC_OWNED_BY_DRIVER == ownership) && (rx_buffer != NULL))
    {
        instance->rx_descriptors[next_rx_desc_index].buffer_1 = rx_buffer;
        instance->rx_descriptors[next_rx_desc_index].caller_info = p_user_data;
        instance->rx_descriptors[next_rx_desc_index].descriptor_1 = RDES1_RCH | (uint32_t)MAC_MAX_PACKET_SIZE;

        /* Give ownership of descriptor to Core10100 */
        instance->rx_descriptors[next_rx_desc_index].descriptor_0 = RDES0_OWN;

        /* Point the next_rx_desc to next free descriptor in the ring */
        next_rx_desc_index = increment_rx_index(next_rx_desc_index);

        instance->next_free_rx_desc_index = next_rx_desc_index;

        enable_rx_interrupt(instance);

        start_receiving(instance);

        error = MAC_SUCCESS;
    }
    else
    {
        enable_rx_interrupt(instance);
        error = MAC_FAILED;
    }

    return error;
}

/***************************************************************************//**
 See core10100_ahbapb.h for details of how to use this function
*/
void MAC_set_rx_callback
(
    mac_instance_t * instance,
    mac_receive_callback_t rx_callback
)
{
    instance->pckt_rx_callback = rx_callback;
}

/***************************************************************************//**
 See core10100_ahbapb.h for details of how to use this function
*/
void MAC_set_tx_callback
(
    mac_instance_t * instance,
    mac_transmit_callback_t tx_complete_handler
)
{
    /* disable tx interrupts */
    HAL_set_32bit_reg_field(instance->base_address, CSR7_TIE, 0U);
    HAL_set_32bit_reg_field(instance->base_address, CSR7_TUE, 0U);

    instance->tx_complete_handler = tx_complete_handler;
}

/***************************************************************************//**
 See core10100_ahbapb.h for details of how to use this function
*/
uint8_t
MAC_get_link_status
(
    mac_instance_t * instance,
    mac_speed_t * speed,
    uint8_t * fullduplex
)
{
    uint32_t link;

    HAL_ASSERT(speed != NULL);
    HAL_ASSERT(fullduplex != NULL);
    
    link = MAC_phy_get_link_status(instance->base_address,
                                   instance->phy_address,
                                   speed,
                                   fullduplex);

    /*
     * Update the MAC's configuration if the link's speed of duplex mode changed
     * since the last time MAC_get_link_status() was called.
     */
    if ((MAC_LINK_UP == link) &&
        ((*speed != instance->previous_speed) ||
         (*fullduplex != instance->previous_duplex_mode)))
    {
        instance->previous_speed = *speed;
        instance->previous_duplex_mode = *fullduplex;

        stop_transmission(instance);

        stop_receiving(instance);

        HAL_set_32bit_reg_field(instance->base_address,
                                CSR6_TTM,
                                (MAC_100MBPS == *speed) ? 1U : 0U);

        HAL_set_32bit_reg_field(instance->base_address,
                                CSR6_FD,
                                (MAC_FULL_DUPLEX == *fullduplex) ? 1U : 0U);

        start_transmission(instance);

        start_receiving(instance);

    }
    return (link);
}

/*----------------------------------------------------------------------------*/
void MAC_set_address_filter
(
    mac_instance_t * instance,
    const uint8_t mac_addresses[],
    uint32_t nb_addresses
)
{
    uint8_t setup_frame[SETUP_FRAME_LENGTH];

    (void)memset(setup_frame, 0, SETUP_FRAME_LENGTH);

    if (nb_addresses <= 15U)
    {
        /*----------------------------------------------------------------------
         * Use perfect filtering.
         */
        uint32_t inc;
        uint32_t in_mac_addr_offset;
        uint32_t frame_addr_offset;

        /* Copy local MAC address into filter setup frame. */
        setup_frame[0] = instance->local_mac_addr[0];
        setup_frame[1] = instance->local_mac_addr[1];
        setup_frame[4] = instance->local_mac_addr[2];
        setup_frame[5] = instance->local_mac_addr[3];
        setup_frame[8] = instance->local_mac_addr[4];
        setup_frame[9] = instance->local_mac_addr[5];

        in_mac_addr_offset = 0U;
        frame_addr_offset = 12U;
        for (inc = 0U; inc < nb_addresses; ++inc)
        {
            setup_frame[frame_addr_offset] = mac_addresses[in_mac_addr_offset];
            setup_frame[frame_addr_offset + 1] = mac_addresses[in_mac_addr_offset + 1];
            setup_frame[frame_addr_offset + 4] = mac_addresses[in_mac_addr_offset + 2];
            setup_frame[frame_addr_offset + 5] = mac_addresses[in_mac_addr_offset + 3];
            setup_frame[frame_addr_offset + 8] = mac_addresses[in_mac_addr_offset + 4];
            setup_frame[frame_addr_offset + 9] = mac_addresses[in_mac_addr_offset + 5];

            in_mac_addr_offset += MAC_ADDR_LENGTH;
            frame_addr_offset += 12U;
        }

        /* Fill remaining filter address locations with local MAC address. */
        for (inc = nb_addresses; inc < 15U; ++inc)
        {
            setup_frame[frame_addr_offset] = instance->local_mac_addr[0];
            setup_frame[frame_addr_offset + 1] = instance->local_mac_addr[1];
            setup_frame[frame_addr_offset + 4] = instance->local_mac_addr[2];
            setup_frame[frame_addr_offset + 5] = instance->local_mac_addr[3];
            setup_frame[frame_addr_offset + 8] = instance->local_mac_addr[4];
            setup_frame[frame_addr_offset + 9] = instance->local_mac_addr[5];

            in_mac_addr_offset += MAC_ADDR_LENGTH;
            frame_addr_offset += 12U;
        }

        send_setup_frame(instance, setup_frame, PERFECT_FILTERING);
    }
    else
    {
        /*----------------------------------------------------------------------
         * Use hash filtering.
         */
        uint32_t hash;
        uint32_t target_idx = 0U;
        uint32_t src_idx = 0U;
        uint32_t inc;

        uint32_t hash_table[64];

        /* Copy local MAC address into filter setup frame. */
        setup_frame[156] = instance->local_mac_addr[0];
        setup_frame[157] = instance->local_mac_addr[1];
        setup_frame[160] = instance->local_mac_addr[2];
        setup_frame[161] = instance->local_mac_addr[3];
        setup_frame[164] = instance->local_mac_addr[4];
        setup_frame[165] = instance->local_mac_addr[5];

        /* reset hash table */
        (void)memset(hash_table, 0, 256);

        for (inc = 0U; inc < nb_addresses; ++inc)
        {
            hash = MAC_ethernet_crc(&mac_addresses[inc * 6], 6U) & 0x1FFU;
            hash_table[ hash / 8 ] |= 1U << (hash & 0x07U);
        }

        for (inc = 0U; inc < 32U; ++inc)
        {
            setup_frame[target_idx] = (uint8_t)hash_table[src_idx];
            ++src_idx;
            ++target_idx;
            setup_frame[target_idx] = (uint8_t)hash_table[src_idx];
            ++src_idx;
            target_idx += 3U;
        }

        send_setup_frame(instance, setup_frame, HASH_FILTERING);
    }
}

/***************************************************************************//**
 See core10100_ahbapb.h for details of how to use this function
*/
uint32_t
MAC_read_stat
(
    const mac_instance_t * instance,
    mac_stat_t stat_id
)
{
    uint32_t returnval;

    switch (stat_id)
    {
        case MAC_RX_INTERRUPTS:
            returnval = instance->statistics.rx_interrupts;
        break;

        case MAC_RX_FILTERING_FAIL:
            returnval = instance->statistics.rx_filtering_fail;
        break;

        case MAC_RX_DESCRIPTOR_ERROR:
            returnval = instance->statistics.rx_descriptor_error;
        break;

        case MAC_RX_RUNT_FRAME:
            returnval = instance->statistics.rx_runt_frame;
        break;

        case MAC_RX_NOT_FIRST:
            returnval = instance->statistics.rx_not_first;
        break;

        case MAC_RX_NOT_LAST:
            returnval = instance->statistics.rx_not_last;
        break;

        case MAC_RX_FRAME_TOO_LONG:
            returnval = instance->statistics.rx_frame_too_long;
        break;

        case MAC_RX_COLLISION_SEEN:
            returnval = instance->statistics.rx_collision_seen;
        break;

        case MAC_RX_CRC_ERROR:
            returnval = instance->statistics.rx_crc_error;
        break;

        case MAC_RX_FIFO_OVERFLOW:
            returnval = instance->statistics.rx_fifo_overflow;
        break;

        case MAC_RX_MISSED_FRAME:
            returnval = instance->statistics.rx_missed_frame;
        break;

        case MAC_TX_INTERRUPTS:
            returnval = instance->statistics.tx_interrupts;
        break;

        case MAC_TX_LOSS_OF_CARRIER:
            returnval = instance->statistics.tx_loss_of_carrier;
        break;

        case MAC_TX_NO_CARRIER:
            returnval = instance->statistics.tx_no_carrier;
        break;

        case MAC_TX_LATE_COLLISION:
            returnval = instance->statistics.tx_late_collision;
        break;

        case MAC_TX_EXCESSIVE_COLLISION:
            returnval = instance->statistics.tx_excessive_collision;
        break;

        case MAC_TX_COLLISION_COUNT:
            returnval = instance->statistics.tx_collision_count;
        break;

        case MAC_TX_UNDERFLOW_ERROR:
            returnval = instance->statistics.tx_underflow_error;
        break;

        default:
            returnval = 0U;
        break;
    }

    return returnval;
}

/***************************************************************************//**
 See core10100_ahbapb.h for details of how to use this function
*/
void MAC_clear_statistics
(
    mac_instance_t * instance
)
{
    (void)memset(&instance->statistics, 0, sizeof(mac_statistics_t));
}

/***************************************************************************//**
 * MAC interrupt service routine.
 *
 * @param instance      Pointer to a mac_instance_t structure
 */
void MAC_isr
(
    mac_instance_t * instance
)
{
    uint32_t events;
    addr_t base;
    uint32_t intr_status;
    uint32_t irq_clear = 0U;

    events = 0U;
    base = instance->base_address;

    intr_status = HAL_get_32bit_reg(base, CSR5);

    if ((intr_status & CSR5_NIS_MASK) != 0U)
    {
        if ((intr_status & CSR5_TI_MASK) != 0U) /* Transmit */
        {
            instance->statistics.tx_interrupts++;
            events |= MAC_EVENT_PACKET_SEND;
            irq_clear |= CSR5_TI_MASK;
        }

        if ((intr_status & CSR5_TU_MASK) != 0U) /* Transmit */
        {
            irq_clear |= CSR5_TU_MASK;
        }

        if ((intr_status & CSR5_RI_MASK) != 0U) /* Receive */
        {
            instance->statistics.rx_interrupts++;
            events |= MAC_EVENT_PACKET_RECEIVED;
            irq_clear |= CSR5_RI_MASK;
        }

        if ((intr_status & CSR5_RU_MASK) != 0U) /* Receive buffer unavailable */
        {
            irq_clear |= CSR5_RU_MASK;
        }
    }

    /* Clear interrupts */
    HAL_set_32bit_reg(base, CSR5, irq_clear);

    if (events != MAC_EVENT_NONE)
    {
        if ((events & MAC_EVENT_PACKET_RECEIVED) == MAC_EVENT_PACKET_RECEIVED)
        {
            rxpkt_handler(instance);
        }

        if ((events & MAC_EVENT_PACKET_SEND) == MAC_EVENT_PACKET_SEND)
        {
            txpkt_handler(instance);
        }
    }
}

/**************************** INTERNAL FUNCTIONS ******************************/

/***************************************************************************//**
 See core10100_ahbapb.h for details of how to use this function
*/

static void
send_setup_frame
(
    const mac_instance_t * instance,
    const uint8_t * setup_frame,
    uint32_t option
)
{
    mac_tx_descriptor_t descriptor;
    uint32_t tx_process_state;
    uint32_t initial_rx_state;

    /* prepare descriptor */
    descriptor.descriptor_0 = TDES0_OWN;
    descriptor.descriptor_1 = TDES1_SET | TDES1_TER |(SETUP_FRAME_LENGTH << TDES1_TBS1_OFFSET);

    if (HASH_FILTERING == option)
    {
        descriptor.descriptor_1 |= TDES1_FT0;
    }

    descriptor.buffer_1 = setup_frame;
    descriptor.buffer_2 = 0U;

    /* Stop transmission */
    stop_transmission(instance);

    initial_rx_state = HAL_get_32bit_reg_field(instance->base_address, CSR5_RS);
    stop_receiving(instance);

    /* Set descriptor */
    HAL_set_32bit_reg(instance->base_address, CSR4, (uint32_t)&descriptor);

    /* Start transmission */
    start_transmission(instance);

    do
    {
        /* transmit poll demand */
        HAL_set_32bit_reg(instance->base_address, CSR1, 1U);
        tx_process_state = HAL_get_32bit_reg_field(instance->base_address, CSR5_TS);
    }
    while (tx_process_state != CSR5_TS_SUSPENDED);

     stop_transmission(instance);

    /* Set tx descriptor */
    HAL_set_32bit_reg(instance->base_address, CSR4, (uint32_t)instance->tx_descriptors);

    /* Start receiving and transmission */
    if (initial_rx_state != CSR5_RS_STOPPED)
    {
        start_receiving(instance);
    }
}

/***************************************************************************//**
 * increment_tx_index().
 */
static int16_t increment_tx_index
(
    int16_t index
)
{
    int16_t incremented_idx = index;

    if ((MAC_TX_RING_SIZE - 1) == incremented_idx)
    {
        incremented_idx = 0;
    }
    else
    {
        incremented_idx++;
    }

    return incremented_idx;
}

/***************************************************************************//**
 * increment_rx_index().
 */
static int16_t increment_rx_index
(
    int16_t index
)
{
    int16_t incremented_idx = index;

    if ((MAC_RX_RING_SIZE - 1) == incremented_idx)
    {
        incremented_idx = 0;
    }
    else
    {
        incremented_idx++;
    }

    return incremented_idx;
}

/***************************************************************************//**
 * adjust_tx_pkt_length().
 */
static uint32_t adjust_tx_pkt_length
(
    uint32_t tx_length
)
{
    uint32_t adjusted_tx_pkt_length;

    if (tx_length > MAC_MAX_PACKET_SIZE)
    {
        adjusted_tx_pkt_length = MAC_MAX_PACKET_SIZE;
    }
    else
    {
        adjusted_tx_pkt_length = tx_length;
    }

    return adjusted_tx_pkt_length;
}

/***************************************************************************//**
 * txpkt_handler().
 */
static void
txpkt_handler
(
    mac_instance_t * instance
)
{
    int16_t first_tx_idx;
    int16_t last_tx_idx;
    uint32_t ownership;

    ASSERT(instance->first_tx_index != INVALID_INDEX);
    ASSERT(instance->last_tx_index != INVALID_INDEX);

    last_tx_idx = instance->last_tx_index;
    first_tx_idx = instance->first_tx_index;
    do
    {
        update_tx_statistics(instance, first_tx_idx);
        if (instance->tx_complete_handler != NULL)
        {
            instance->tx_complete_handler(instance->tx_descriptors[first_tx_idx].caller_info);
        }

        if (first_tx_idx == last_tx_idx)
        {
            /* all pending tx packets sent. */
            first_tx_idx = INVALID_INDEX;
            last_tx_idx = INVALID_INDEX;
            ownership = TX_DESC_AVAILABLE;
        }
        else
        {
            /* Move on to next transmit descriptor. */
            first_tx_idx = increment_tx_index(first_tx_idx);

            /* Check if we reached a descriptor still pending tx. */
            ownership = instance->tx_descriptors[first_tx_idx].descriptor_0 & TDES0_OWN;
        }
    }
    while ((DESC_OWNED_BY_DRIVER == ownership) && (first_tx_idx != INVALID_INDEX));

    instance->last_tx_index = last_tx_idx;
    instance->first_tx_index = first_tx_idx;
}

/***************************************************************************//**
 * get_rx_frame_errors().
 * Retrieve the error codes from the RDES0 receive descriptor field for the
 * received packet.
 */
static uint32_t
get_rx_frame_errors
(
    const mac_instance_t * instance,
    uint32_t descriptor0
)
{
    uint32_t frame_errors;
    uint32_t full_duplex_link;
    uint32_t last_descriptor;

    /*
     * Make sure this was the last descriptor.
     */
    last_descriptor =  descriptor0 & RDES0_LS;
    if (RDES0_LS == last_descriptor)
    {
        /*
         * Ensure frame was received without errors. Ignore bits not relevant to
         * the current duplex mode.
         */
        full_duplex_link = HAL_get_32bit_reg_field(instance->base_address, CSR6_FD);

        if (1U == full_duplex_link)
        {
            frame_errors =  descriptor0 & (RDES0_TL | RDES0_RF | RDES0_DE | RDES0_CE);
        }
        else
        {
            frame_errors =  descriptor0 & (RDES0_TL | RDES0_CS | RDES0_RF | RDES0_DE | RDES0_CE);
        }
    }
    else
    {
        frame_errors = RDES0_LS;
    }

#ifdef MSCC_CORE10100_TEST_HARNESS_FORCE_RX_ERRORS
    /*
     * Signal an error on the received packet if requested by the driver test
     * harness.
     */
    if (g_core10100_test_harness_force_rx_error > 0U)
    {
        --g_core10100_test_harness_force_rx_error;
        frame_errors = RDES0_CE;
    }
#endif

    return frame_errors;
}

/***************************************************************************//**
 * Retrieve the received packet length from the RDES0 receive descriptor field.
 */
static uint32_t
get_rx_packet_length
(
    uint32_t descriptor0
)
{
    uint32_t pckt_length;

    if ((descriptor0 & RDES0_OWN) != 0U)
    {
        /* Current descriptor is empty */
        pckt_length = 0U;
    }
    else
    {
        pckt_length = (descriptor0 >> RDES0_FL_OFFSET) & RDES0_FL_MASK;

        /* strip crc */
        if(pckt_length > 4U)
        {
            pckt_length -= 4U;
        }
        else
        {
            pckt_length = 0U;
        }
    }

    return pckt_length;
}

/***************************************************************************//**
 * rxpkt_handler().
 */
static void
rxpkt_handler
(
    mac_instance_t * instance
)
{
    int16_t first_rx_descr_idx;
    int16_t next_free_rx_desc_idx;
    uint32_t ownership;

    first_rx_descr_idx = instance->first_rx_desc_index;
    next_free_rx_desc_idx = instance->next_free_rx_desc_index;

    do
    {
        uint32_t frame_errors;
        mac_rx_descriptor_t volatile * cdesc = &instance->rx_descriptors[first_rx_descr_idx];
        uint8_t * p_rx_packet = cdesc->buffer_1;

        update_rx_statistics(instance, first_rx_descr_idx);

        frame_errors = get_rx_frame_errors(instance, cdesc->descriptor_0);
        if (0U == frame_errors)
        {
            uint32_t pckt_length;

            pckt_length = get_rx_packet_length(cdesc->descriptor_0);

            if ((pckt_length > 0U) && (instance->pckt_rx_callback != NULL))
            {
                instance->pckt_rx_callback(p_rx_packet,
                                           pckt_length,
                                           cdesc->caller_info);
            }
        }
        else
        {
            instance->rx_descriptors[next_free_rx_desc_idx].buffer_1 = p_rx_packet;
            instance->rx_descriptors[next_free_rx_desc_idx].caller_info = cdesc->caller_info;
            instance->rx_descriptors[next_free_rx_desc_idx].descriptor_1 = cdesc->descriptor_1;
            instance->rx_descriptors[next_free_rx_desc_idx].descriptor_0 = RDES0_OWN;
            next_free_rx_desc_idx = increment_rx_index(next_free_rx_desc_idx);
            instance->next_free_rx_desc_index = next_free_rx_desc_idx;
            /* Start receive */
            start_receiving(instance);
        }

        first_rx_descr_idx = increment_rx_index(first_rx_descr_idx);
        ownership = instance->rx_descriptors[first_rx_descr_idx].descriptor_0 & RDES0_OWN;
    }
    while ((DESC_OWNED_BY_DRIVER == ownership) &&
           (first_rx_descr_idx != next_free_rx_desc_idx));

    instance->first_rx_desc_index = first_rx_descr_idx;
}

/***************************************************************************//**
 * enable_tx_interrupt().
 */
static void enable_tx_interrupt(const mac_instance_t * instance)
{
    HAL_set_32bit_reg_field(instance->base_address, CSR7_TIE, 1U);
    HAL_set_32bit_reg_field(instance->base_address, CSR7_TUE, 1U);
}

/***************************************************************************//**
 * disable_tx_interrupt().
 */
static void disable_tx_interrupt(const mac_instance_t * instance)
{
    HAL_set_32bit_reg_field(instance->base_address, CSR7_TIE, 0U);
    HAL_set_32bit_reg_field(instance->base_address, CSR7_TUE, 0U);
}

/***************************************************************************//**
 * enable_rx_interrupt().
 */
static void
enable_rx_interrupt
(
    const mac_instance_t * instance
)
{
    HAL_set_32bit_reg_field(instance->base_address, CSR7_RIE, 1U);
}

/***************************************************************************//**
 * disable_rx_interrupt().
 */
static void
disable_rx_interrupt
(
    const mac_instance_t * instance
)
{
    HAL_set_32bit_reg_field(instance->base_address, CSR7_RIE, 0U);
}

/***************************************************************************//**
 * disable_rx_interrupt().
 */
static void
update_tx_statistics
(
    mac_instance_t * instance,
    int16_t tx_desc_index
)
{
    uint32_t desc;
    /* update counters */
    desc = instance->tx_descriptors[tx_desc_index].descriptor_0;

    if ((desc & TDES0_LO) != 0U)
    {
        instance->statistics.tx_loss_of_carrier++;
    }
    if ((desc & TDES0_NC) != 0U)
    {
        instance->statistics.tx_no_carrier++;
    }
    if ((desc & TDES0_LC) != 0U)
    {
        instance->statistics.tx_late_collision++;
    }
    if ((desc & TDES0_EC) != 0U)
    {
        instance->statistics.tx_excessive_collision++;
    }
    if ((desc & TDES0_UF) != 0U)
    {
        instance->statistics.tx_underflow_error++;

        /* On underflow, the Transmit process goes into suspended state.
           To bring it out of Suspend, issue a stop command*/
        stop_transmission(instance);
    }

    instance->statistics.tx_collision_count +=
        (desc >> TDES0_CC_OFFSET) & TDES0_CC_MASK;
}

/***************************************************************************//**
 * disable_rx_interrupt().
 */
static void update_rx_statistics
(
    mac_instance_t * instance,
    int16_t rx_desc_index
)
{
    uint32_t desc;

    /* update counters */
    desc = instance->rx_descriptors[rx_desc_index].descriptor_0;

    if ((desc & RDES0_FF) != 0U)
    {
        instance->statistics.rx_filtering_fail++;
    }

    if ((desc & RDES0_DE) != 0U)
    {
        instance->statistics.rx_descriptor_error++;
    }

    if ((desc & RDES0_RF) != 0U)
    {
        instance->statistics.rx_runt_frame++;
    }

    if ((desc & RDES0_FS) == 0U)
    {
        instance->statistics.rx_not_first++;
    }

    if ((desc & RDES0_LS) == 0U)
    {
        instance->statistics.rx_not_last++;
    }

    if ((desc & RDES0_TL) != 0U)
    {
        instance->statistics.rx_frame_too_long++;
    }

    if ((desc & RDES0_CS) != 0U)
    {
        instance->statistics.rx_collision_seen++;
    }

    if ((desc & RDES0_CE) != 0U)
    {
        instance->statistics.rx_crc_error++;
    }

    desc = HAL_get_32bit_reg(instance->base_address, CSR8);

    instance->statistics.rx_fifo_overflow +=
        (desc & (CSR8_OCO_MASK | CSR8_FOC_MASK)) >> CSR8_FOC_SHIFT;

    instance->statistics.rx_missed_frame +=
        (desc & (CSR8_MFO_MASK | (uint32_t)CSR8_MFC_MASK));
}

/***************************************************************************//**
 * Stops transmission.
 * Function will wait until transmit operation enters stop state.
 */
static void
stop_transmission
(
    const mac_instance_t * instance
)
{
    uint32_t tx_process_state;

    do
    {
        HAL_set_32bit_reg_field(instance->base_address, CSR6_ST, 0U);
        tx_process_state = HAL_get_32bit_reg_field(instance->base_address, CSR5_TS);
    }
    while (tx_process_state != CSR5_TS_STOPPED);
}

/***************************************************************************//**
 * Starts transmission.
 */
static void
start_transmission
(
    const mac_instance_t * instance
)
{
       HAL_set_32bit_reg_field(instance->base_address, CSR6_ST, 1U);
}

/***************************************************************************//**
 * Stops transmission.
 * Function will wait until transmit operation enters stop state.
 */
static void
stop_receiving
(
    const mac_instance_t * instance
)
{
    uint32_t rx_process_state;

    do
    {
        HAL_set_32bit_reg_field(instance->base_address, CSR6_SR, 0U);
        rx_process_state = HAL_get_32bit_reg_field(instance->base_address, CSR5_RS);
    }
    while (rx_process_state != CSR5_RS_STOPPED);
}

/***************************************************************************//**
 * Starts transmission.
 */
static void
start_receiving
(
    const mac_instance_t * instance
)
{
    HAL_set_32bit_reg_field(instance->base_address, CSR6_SR, 1U);
}

/***************************************************************************//**
 *
 */
static void config_mac_hw
(
    const mac_instance_t * instance,
    const mac_cfg_t * cfg
)
{
    addr_t base;

    stop_transmission(instance);
    stop_receiving(instance);

    base = instance->base_address;

    HAL_set_32bit_reg_field(base, CSR6_RA, (uint32_t)(cfg->receive_all != 0U ? 1U : 0U));
    HAL_set_32bit_reg_field(base, CSR6_TTM, (uint32_t)(cfg->tx_threshold_mode != 0U ? 1U : 0U));
    HAL_set_32bit_reg_field(base, CSR6_SF, (uint32_t)(cfg->store_and_forward != 0U ? 1U : 0U));
    HAL_set_32bit_reg_field(base, CSR6_TR, (uint32_t)cfg->threshold_control);
    HAL_set_32bit_reg_field(base, CSR6_PM, (uint32_t)(cfg->pass_all_multicast != 0U ? 1U : 0U));
    HAL_set_32bit_reg_field(base, CSR6_PR, (uint32_t)(cfg->promiscous_mode != 0U ? 1U : 0U));
    HAL_set_32bit_reg_field(base, CSR6_PB, (uint32_t)(cfg->pass_badframe != 0U ? 1U : 0U));
}

/***************************************************************************//**
 * Auto-detect the PHY's address by attempting to read the PHY identification
 * register containing the PHY manufacturer's identifier.
 * Attempting to read a PHY register using an incorrect PHY address will result
 * in a value with all bits set to one on the MDIO bus. Reading any other value
 * means that a PHY responded to the read request, therefore we have found the
 * PHY's address.
 * This function returns the detected PHY's address or 32 (PHY_ADDRESS_MAX + 1)
 * if no PHY is responding.
 */
static uint8_t probe_phy
(
    const mac_instance_t * instance
)
{
    uint8_t phy_address = PHY_ADDRESS_MIN;
    const uint16_t ALL_BITS_HIGH = 0xffffU;
    const uint8_t PHYREG_PHYID1R = 0x02U;   /* PHY Identifier 1 register address. */
    uint32_t found;

    do
    {
        uint16_t reg;

        reg = MAC_MDIO_read(instance->base_address, phy_address, PHYREG_PHYID1R);
        if (reg != ALL_BITS_HIGH)
        {
            found = 1U;
        }
        else
        {
            found = 0U;
            ++phy_address;
        }
    }
    while ((phy_address <= PHY_ADDRESS_MAX) && (0U == found));

    return phy_address;
}

/******************************** END OF FILE *********************************/

#ifdef __cplusplus
}
#endif

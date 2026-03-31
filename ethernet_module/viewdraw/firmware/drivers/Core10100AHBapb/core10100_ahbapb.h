/***************************************************************************//**
 * (c) Copyright 2012-2015 Microsemi SoC Products Group.  All rights reserved.
 *
 * Header file for Core10100_AHBAPB driver.
 * Core10100_AHBAPB driver public APIs.
 *
 *
 * SVN $Revision: 7800 $
 * SVN $Date: 2015-09-14 17:52:50 +0530 (Mon, 14 Sep 2015) $
 *
 *******************************************************************************/
/*=========================================================================*//**
  @mainpage Core10100_AHBAPB Bare Metal Driver.

  @section intro_sec Introduction
    The Core10100_AHBAPB is a high-speed media access control (MAC) Ethernet
    controller. The Core10100_AHBAPB supports MII and RMII interfaces to the
    physical layer devices (PHY).
    This software driver provides a set of functions for controlling
    the Core10100_AHBAPB as part of a bare metal system where no operating system
    is available. This driver can be adapted for use as part of an operating
    system but the implementation of the adaptation layer between this driver and
    the operating system's driver model is outside the scope of this driver.
    The Core10100_AHBAPB is an AHB bus master. The built-in DMA controller inside
    the Core10100_AHBAPB, along with the AHB master interface, is used to
    automatically move data between external RAM and the built-in transmit FIFO
    and receive FIFO with minimal CPU intervention.
    The Core10100_AHBAPB automatically fetches from transmit data buffers and
    stores the receive data buffers in external RAM. Internal memory is used as
    configurable FIFO memory blocks; both RX/TX memory blocks are available. The
    blocks are called descriptors, and both RX/TX are referenced within the driver.

  @section theory_op Theory of Operation
    The Core10100_AHBAPB driver functions are grouped into the following categories:
        - Initialization and configuration
        - Transmit operations
        - Receive operations
        - Reading link status and statistics

    Initialization and Configuration
    The Core10100_AHBAPB software driver is designed to allow the control of
    multiple instances of Core10100_AHBAPB. Each instance of Core10100_AHBAPB
    in the hardware design is associated with a single instance of the
    mac_instance_t structure in the software. You need to allocate memory for
    one unique mac_instance_t structure instance for each Core10100_AHBAPB
    hardware instance. The content of these data structures are initialized
    during calls to function MAC_init().The MAC_init() function takes a pointer
    to a configuration data structure as parameter. This data structure contains
    all the configuration information required to initialize and configure the
    Core10100_AHBAPB. A pointer to the mac_instance_t structure is passed to
    subsequent driver functions in order to identify the Core10100_AHBAPB
    hardware instance you wish to perform the requested operation on.

    Note:     Do not attempt to directly manipulate the contents of mac_instance_t
    structures. This structure is only intended to be modified by the driver
    function.

    The Core10100_AHBAPB driver provides the MAC_cfg_struct_def_init() function
    to initialize the configuration data structure to default values. It is
    recommended to use this function to retrieve the default configuration then
    overwrite the defaults with the application specific settings such as
    allowed link speeds, link duplex mode and MAC address.

    The following functions are used for initialization and configuration:
        - MAC_cfg_struct_def_init()
        - MAC_init()

    Transmit Operations
    The Core10100_AHBAPB driver transmit operations are interrupt driven. The
    application must register a transmit call-back function with the driver
    using the MAC_set_tx_callback() function. This call-back function will be
    called by the Core10100_AHBAPB driver every time a packet has been sent.

    The application must call the MAC_send_pkt() function every time it wants
    to transmit a packet. The application must pass a pointer to the buffer
    containing the packet to be sent. It is the application’s responsibility to
    manage the memory allocated to store the transmit packets. The
    Core10100_AHBAPB driver only requires a pointer to the buffer containing
    the packet and the packet size. The Core10100_AHBAPB driver will call the
    transmit call-back function registered using the MAC_set_tx_callback()
    function once a packet is sent. The transmit call-back function is supplied
    by the application and can be used to release the memory used to store the
    packet that was sent.

    The following functions are used for transmit and receive operations:
        - MAC_send_pkt()
        - MAC_set_tx_callback()

    Receive Operations
    The Core10100_AHBAPB driver receive operations are interrupt driven. The
    application must first register a receive call-back function using the
    MAC_set_rx_callback() function. The application can then allocate receive
    buffers to the Core10100_AHBAPB driver by calling the MAC_receive_pkt()
    function. This function can be called multiple times to allocate more than
    one receive buffer. The Core10100_AHBAPB driver will then call the receive
    call-back function whenever a packet is received into one of the receive
    buffer. It will hand back the receive buffer to the application for packet
    processing. This buffer will not be reused by the Core10100_AHBAPB driver
    unless it is re-allocated to the driver by a call to MAC_receive_pkt().

    The following functions are used for transmit and receive operations:
        - MAC_receive_pkt()
        - MAC_set_rx_callback()

    Reading Status and Statistics
    The Core10100_AHBAPB driver provides the following functions to retrieve
    the current link status and statistics.
        - MAC_get_link_status()
        - MAC_read_stat()
        - MAC_clear_statistics()

    Address based Frame filtering
    The Core10100_AHBAPB performs frame filtering based on the destination MAC
    address of the received frame. The MAC_init() function initializes the
    Core10100_AHBAPB hardware to a default filtering mode where only broadcast
    frames, multicast frames and frames with a destination address equal to the
    local base station MAC address are passed to the MAC. Broadcast frames are
    usually required by an application to obtain an IP address. This default
    configuration does not need the frame filtering table to be filled. This
    default configuration is returned with the MAC_cfg_struct_def_init()
    function. You may change the configuration before passing it to the
    MAC_init() function.
    The application can use the MAC_set_address_filter() function to overwrite
    the frame filter choice that was selected for initialization. The
    application must provide the list of MAC addresses from which it actually
    wants to receive frames (allowed MAC addresses list) to this driver using
    the MAC_set_address_filter() function. If a received frame contains one of
    the MAC addresses contained in the allowed MAC addresses list then that
    frame will be passed.
    The Core10100_AHBAPB performs perfect filtering when the allowed address
    list passed to MAC_set_address_filter() contains no more than 15
    addresses. Otherwise, the filtering is not perfect since the filtering
    hardware uses a hash table. Therefore, some frames with an address not
    included in the allowed MAC addresses list are still passed because the
    hash value for that frame’s MAC address is identical to the hash value
    for an allowed MAC address.
    The following function is used for frame filtering
        - MAC_set_address_filter()

*//*=========================================================================*/
#ifndef CORE10100_AHBAPB_H
#define CORE10100_AHBAPB_H    1

#include "cpu_types.h"
#include "core10100_ahbapb_user_cfg.h"

#ifdef __cplusplus
extern "C" {
#endif

/******************************** DEFINES *************************************/

/*******************************************************************************
 Configuration parameters.
 The definitions listed below are provided to populate the configuration, of
 type mac_cfg_t, provided as parameter to the MAC_init() function. The
 MAC_cfg_struct_def_init() function call initializes a configuration record with
 default values. This default configuration record can be customized using the
 definitions below prior to calling MAC_init().
*/

/********************************************************************************
 * The following definitions are used to set the values of the store_and_forward,
 * loopback, receive_all, pass_all_multicast, promiscous_mode and pass_badframe
 * configuration parameter
 */
#define MAC_ENABLE      1U
#define MAC_DISABLE     0U

/********************************************************************************
 * The following definitions are used with functions MAC_send_pkt() and
 * MAC_receive_pkt() to report success or failure in assigning the packet memory
 * buffer to a transmit/receive descriptor.
 */
#define MAC_SUCCESS     ((uint8_t) 1U)
#define MAC_FAILED      ((uint8_t) 0U)

/********************************************************************************
 * The following definitions are used to specify the transmit FIFO threshold
 * level as part of the driver configuration. These definitions are used to set
 * the values of the threshold_control and tx_threshold_mode
 */
/*
 * Transmit threshold mode.
 * 1 - Transmit FIFO threshold set for 100 Mbps mode
 * 0 - Transmit FIFO threshold set for 10 Mbps mode
 * This configuration can be changed only when a transmit process is in a stopped
 * state.
 */
#define MAC_CFG_TX_THRESHOLD_100MB_MODE             (uint8_t)0x01
#define MAC_CFG_TX_THRESHOLD_10MB_MODE              (uint8_t)0x00

/*
 * Threshold control bits.
 * These bits, together with TTM, SF, and PS, control the threshold level for the
 * transmit FIFO.
 */
#define MAC_CFG_THRESHOLD_CONTROL_00                (uint8_t)0x00000000
#define MAC_CFG_THRESHOLD_CONTROL_01                (uint8_t)0x00000001
#define MAC_CFG_THRESHOLD_CONTROL_10                (uint8_t)0x00000002
#define MAC_CFG_THRESHOLD_CONTROL_11                (uint8_t)0x00000003

/********************************************************************************
  The following definitions are used to specify the allowed link speed and duplex
  mode as part of the driver configuration. These definitions are used to create
  a bitmask value for the linkspeed configuration parameter.
 */
#define MAC_ANEG_10M_FD         0x01U
#define MAC_ANEG_10M_HD         0x02U
#define MAC_ANEG_100M_FD        0x04U
#define MAC_ANEG_100M_HD        0x08U
#define MAC_ANEG_ALL_SPEEDS     (MAC_ANEG_10M_FD | MAC_ANEG_10M_HD | \
                                 MAC_ANEG_100M_FD | MAC_ANEG_100M_HD)

/********************************************************************************
  The following definitions are used with function MAC_get_link_status() to
  report the link’s status.
 */
#define MAC_LINK_DOWN       0U
#define MAC_LINK_UP         1U

#define MAC_HALF_DUPLEX     0U
#define MAC_FULL_DUPLEX     1U

/*******************************************************************************
  The definition below is provided to create packet buffers in the application
  memory space. It specifies the required size of transmit and receive buffers
  that must be allocated by the application.
 */
#define MAC_MAX_PACKET_SIZE             1518U

/***************************************************************************//**
  Application can use this constant to indicate to the driver to probe the PHY 
  and auto-detect the PHY address that it is configured with. If you already 
  know the PHY address configured in your hardware system, you can provide that 
  address to the driver instead of this constant. That way the MAC_init() 
  function would be faster because the AUTO detection process of the PHY address 
  is now avoided.
  
  Note: To auto detect the PHY address, this drivers scans the valid MDIO 
  addresses starting from ‘0’ for valid data.

 */
#define MAC_AUTO_DETECT_PHY_ADDRESS     (uint8_t)255U

/***************************************************************************//**
 The mac_transmit_callback_t type defines the prototype for the callback
 funtion which will be called by the Core10100_AHBAPB driver every time when a
 packet is sent. The application must first define a function of this type and
 pass it to the Core10100_AHBAPB driver using MAC_set_tx_callback() function.

 Declaring and Implementing the transmit call-back function:
  The transmit call-back function should follow the following prototype:
    void transmit_callback(void * caller_info);
  The actual name of the call-back function is unimportant. You can use any name
  of your choice for the transmit call-back function. The caller_info parameter
  will contain the value of the pointer passed as last parameter to the
  MAC_send_pkt() function call used to initiate a specific frame transmit. The
  caller_info parameter is intended to be used by the application to resolve
  which frame has been sent.
 */
typedef void (*mac_transmit_callback_t)(void * caller_info);

/***************************************************************************//**
 The mac_receive_callback_t type defines the prototype for the call-back
 function which will be called by the Core10100_AHBAPB driver every time a
 packet is received. The application must first define a function of this type
 and pass it to the Core10100_AHBAPB driver using mac_set_rx_callback()
 function.

 Declaring and Implementing the receive call-back function:
  The receive call-back function should follow the following prototype:
    void receive_callback(uint8_t * p_rx_packet,
                          uint32_t pckt_length,
                          void * caller_info);
  The actual name of the call-back function is unimportant. You can use any
  name of your choice for the receive call-back function.
  The p_rx_packet parameter will contain a pointer to the received frame. The
  pckt_length parameter will contain the length of the received frame. The
  caller_info parameter will contain the value of the pointer passed as last
  parameter to the MAC_receive_pkt() function call used to allocate a receive
  buffer to the MAC’s receive ring. The caller_info parameter is intended to be
  used by the application to manage receive buffers allocation.
 */
typedef void (*mac_receive_callback_t)(uint8_t * p_rx_packet,
                                       uint32_t pckt_length,
                                       void * caller_info);

/*******************************************************************************
 * MAC interface speed
 The mac_speed_t type definition provides various interface speeds supported by
 the Core10100_AHBAPB core.
 */
typedef enum
{
    MAC_10MBPS          = 0x00,
    MAC_100MBPS         = 0x01,
    MAC_AUTONEGOTIATE   = 0x02,
    MAC_INVALID_SPEED   = 0x03
} mac_speed_t;

/***************************************************************************//**
 * Statistics counter identifiers are used with MAC_read_stat routine to
 * receive the count of the requested event occurrences.
 *
 * MAC_RX_INTERRUPTS
 *      Used to receive the number of receive interrupts occurred.
 *
 * MAC_RX_FILTERING_FAIL
 *      Used to receive the number of received frames which did not pass the
 *      address recognition process.
 *
 * MAC_RX_DESCRIPTOR_ERROR
 *      Used to receive the number of occurrences of; no receive buffer was
 *      available when trying to store the received data.
 *
 * MAC_RX_RUNT_FRAME
 *      Used to receive the number of occurrences of; the frame is damaged by a
 *      collision or by a premature termination before the end of a collision
 *      window.
 *
 * MAC_RX_NOT_FIRST
 *      Used to receive the number of occurrences of; start of the frame is not
 *      the first descriptor of a frame. of the frame is not the first descriptor
 *      of a frame.
 *
 * MAC_RX_FRAME_TOO_LONG
 *      Used to receive the number of occurrences of; a current frame is longer
 *      than maximum size of 1,518 bytes, as specified by 802.3.
 *
 * MAC_RX_COLLISION_SEEN
 *      Used to receive the number of occurrences of; a late collision was seen
 *      (collision after 64 bytes following SFD).
 *
 * MAC_RX_CRC_ERROR
 *      Used to receive the number of occurrences of; a CRC error has occurred
 *      in the received frame.
 *
 * MAC_RX_FIFO_OVERFLOW
 *      Used to receive the number of frames not accepted due to the receive FIFO
 *      overflow.
 *
 * MAC_RX_MISSED_FRAME
 *      Used to receive the number of frames not accepted due to the unavailability
 *      of the receive descriptor.
 *
 * MAC_TX_INTERRUPTS
 *      Used to receive the number of transmit interrupts occurred.
 *
 * MAC_TX_LOSS_OF_CARRIER
 *      Used to receive the number of occurrences of; a loss of the carrier during
 *      a transmission.
 *
 * MAC_TX_NO_CARRIER
 *      Used to receive the number of occurrences of; the carrier was not asserted
 *      by an external transceiver during the transmission.
 *
 * MAC_TX_LATE_COLLISION
 *      Used to receive the number of occurrences of; a collision was detected
 *      after transmitting 64 bytes.
 *
 * MAC_TX_EXCESSIVE_COLLISION
 *      Used to receive the number of occurrences of; the transmission was aborted
 *      after 16 retries.
 *
 * MAC_TX_COLLISION_COUNT
 *      Used to receive the number of collisions occurred.
 *
 * MAC_TX_UNDERFLOW_ERROR
 *      Used to receive the number of occurrences of; the FIFO was empty during the
 *      frame transmission.
 */
typedef enum
{
    MAC_RX_INTERRUPTS,
    MAC_RX_FILTERING_FAIL,
    MAC_RX_DESCRIPTOR_ERROR,
    MAC_RX_RUNT_FRAME,
    MAC_RX_NOT_FIRST,
    MAC_RX_NOT_LAST,
    MAC_RX_FRAME_TOO_LONG,
    MAC_RX_COLLISION_SEEN,
    MAC_RX_CRC_ERROR,
    MAC_RX_FIFO_OVERFLOW,
    MAC_RX_MISSED_FRAME,

    MAC_TX_INTERRUPTS,
    MAC_TX_LOSS_OF_CARRIER,
    MAC_TX_NO_CARRIER,
    MAC_TX_LATE_COLLISION,
    MAC_TX_EXCESSIVE_COLLISION,
    MAC_TX_COLLISION_COUNT,
    MAC_TX_UNDERFLOW_ERROR
} mac_stat_t;

/*******************************************************************************
  Core10100_AHBAPB Configuration Structure.
  The mac_cfg_t type provides the prototype for the configuration values of the
  Core10100_AHBAPB MAC. You need to create a record of this type to hold the
  configuration of the MAC. The MAC_cfg_struct_def_init() function can be used to
  initialize the configuration record to default values. Later, the configuration
  elements in the record can be changed to desired values.

  threshold_control and tx_threshold_mode
  The values of the parameters store_and_forward, threshold_control and
  tx_threshold_mode together affect the transmit FIFO threshold level. The table
  below lists the transmit FIFO threshold levels. These levels are specified in
  bytes.

  store_and_forward   threshold_control   tx_threshold_mode  tx_threshold_mode
                                             = 100Mb            = 10Mb

        0                   00                  64 bytes            128 bytes
        0                   01                  128 bytes           256 bytes
        0                   10                  128 bytes           512 bytes
        0                   11                  256 bytes           1024 bytes
        1                   xx             Store and forward  Store and forward

  The allowed values for the threshold_control and tx_threshold_mode
  configuration parameters are listed in the “Transmit FIFO Threshold Level”
  table in the Constant Values section of the user's guide. The
  MAC_cfg_struct_def_init() function sets the transmit FIFO threshold level to
  64 bytes by configuring the parameters as follows:
    - tx_threshold_mode is set to MAC_CFG_TX_THRESHOLD_100MB_MODE
    - threshold_control is set to MAC_CFG_THRESHOLD_CONTROL_00
    - store_and_forward is set to MAC_DISABLE


  link_speed:
    The linkspeed configuration parameter specifies the allowed link speeds. It
    is a bit-mask of the various link speed and duplex modes. The
    MAC_cfg_struct_def_init() function sets this configuration parameter to
    MAC_ANEG_ALL_SPEEDS indicating that a link will be setup for any available
    speed and duplex combination. The linkspeed configuration can be set to a
    bitmask of the following defines to specify the allowed link speed and
    duplex mode:
        - MAC_ANEG_10M_FD
        - MAC_ANEG_10M_HD
        - MAC_ANEG_100M_FD
        - MAC_ANEG_100M_HD

  loopback:
    The loopback configuration parameter specifies if transmit packets should be
    looped back to the Ethernet MAC by the PHY. The allowed values for the
    loopback configuration parameter are:
        - MAC_DISABLE
        - MAC_ENABLE
    Set this configuration parameter to MAC_ENABLE if you want transmitted
    packets to be looped back to the receive side of the Ethernet MAC. The
    MAC_cfg_struct_def_init() function sets this configuration parameter to
    MAC_DISABLE for normal operations.

  receive_all:
    When Enabled, all incoming frames are received, regardless of their
    destination address. An address check is performed, and the result of the
    check is written into the receive descriptor. . The allowed values for the
    receive_all configuration parameter are:
        - MAC_DISABLE
        - MAC_ENABLE
    The MAC_cfg_struct_def_init() function sets this configuration parameter to
    MAC_DISABLE.

  store_and_forward:
    When enabled, the transmission starts after a full packet is written into the
    transmit FIFO, regardless of the current FIFO threshold level. The allowed
    values for the store_and_forward configuration parameter are:
        - MAC_DISABLE
        - MAC_ENABLE
    The MAC_cfg_struct_def_init() function sets this configuration parameter to
    MAC_DISABLE.

  pass_all_multicast:
    When Enabled, all frames with multicast destination addresses will be received,
    regardless of the address check result. The allowed values for the
    pass_all_multicast configuration parameter are:
        - MAC_DISABLE
        - MAC_ENABLE
    The MAC_cfg_struct_def_init() function sets this configuration parameter to
    MAC_ENABLE.

  promiscous_mode:
    When enabled, all frames will be received regardless of the address check
    result. An address check is not performed. The allowed values for the
    promiscous_mode configuration parameter are:
        - MAC_DISABLE
        - MAC_ENABLE
    The MAC_cfg_struct_def_init() function sets this configuration parameter to
    MAC_DISABLE.

  pass_badframe:
    When set, Core10/100 transfers all frames into the data buffers, regardless
    of the receive errors. This allows the runt frames, collided fragments, and
    truncated frames to be received. The allowed values for the pass_badframe
    configuration parameter are:
        - MAC_DISABLE
        - MAC_ENABLE
    The MAC_cfg_struct_def_init() function sets this configuration parameter to
    MAC_DISABLE.

  mac_addr:
    The mac_addr configuration parameter is a 6-byte array containing the
    local MAC address of the Ethernet MAC.

  phy_addr
    The phy_addr parameter specifies the address of the PHY device set in
    hardware by the address pins of the PHY device. The phy_address parameter can
    be a value from 0 to 31. This address is board specific and usually depends on
    how PHY configuration pins are connected. You will need to look at the target
    board schematics and PHY datasheet to find the value for this parameter.
    Alternatively, you can use MAC_AUTO_DETECT_PHY_ADDRESS as value to this
    parameter to request the driver to discover the address of the PHY.

    The MAC_cfg_struct_def_init() function sets this configuration parameter to 0.

 */
typedef struct
{
    uint8_t     link_speed;              /* Link speed: 10Mbps, 100Mbps, auto-negotiate */
    uint8_t     loopback;                /* Enable Tx packets loopback. */
    uint8_t     receive_all;             /*Enable/Disable value, default is disable*/
    uint8_t     tx_threshold_mode;       /*Transmit Threshold mode, default is 10Mbps mode*/
    uint8_t     store_and_forward;       /*Enable/Disable value, default is disable*/
    uint8_t     threshold_control;       /*Threshold control, default is 00*/
    uint8_t     pass_all_multicast;      /*Enable Disable Value, default is Disabled*/
    uint8_t     promiscous_mode;         /*Enable Disable Value, default is Enabled*/
    uint8_t     pass_badframe;           /*Enable Disable Value, default Disabled*/
    uint8_t     mac_addr[6];             /*MAC address of the drived instance*/
    uint8_t     phy_addr;                /*Address of the PHY device*/
} mac_cfg_t;

/***************************************************************************//**
 * Descriptor structure
 */
typedef struct
{
    uint32_t        descriptor_0;
    uint32_t        descriptor_1;
    const uint8_t * buffer_1;
    uint32_t        buffer_2;
    void *          caller_info;
} mac_tx_descriptor_t;

typedef struct
{
    uint32_t   descriptor_0;
    uint32_t   descriptor_1;
    uint8_t *  buffer_1;
    uint32_t   buffer_2;
    void *     caller_info;
} mac_rx_descriptor_t;

/*******************************************************************************
 * Transmit and Receive statistics.
 * Statistic of below type, which is desired to be read is to be passed to the
 * function MAC_read_stat().
 */
typedef struct
{
    uint32_t rx_interrupts;            /**< Number of receive interrupts occurred.*/
    uint32_t rx_filtering_fail;        /**< Number of received frames which did not pass
                                        the address recognition process.*/
    uint32_t rx_descriptor_error;    /**< Number of occurrences of; no receive buffer was
                                        available when trying to store the received data.*/
    uint32_t rx_runt_frame;            /**< Number of occurrences of; the frame is damaged by
                                        a collision or by a premature termination before
                                        the end of a collision window.*/
    uint32_t rx_not_first;            /**< Number of occurrences of; start of the frame is
                                        not the first descriptor of a frame.*/
    uint32_t rx_not_last;            /**< Number of occurrences of; end of the frame is not
                                        the first descriptor of a frame.*/
    uint32_t rx_frame_too_long;        /**< Number of occurrences of; a current frame is
                                        longer than maximum size of 1,518 bytes, as specified
                                        by 802.3.*/
    uint32_t rx_collision_seen;        /**< Number of occurrences of; a late collision was seen
                                        (collision after 64 bytes following SFD).*/
    uint32_t rx_crc_error;            /**< Number of occurrences of; a CRC error has occurred
                                        in the received frame.*/
    uint32_t rx_fifo_overflow;        /**< Number of frames not accepted due to the receive
                                        FIFO overflow.*/
    uint32_t rx_missed_frame;        /**< Number of frames not accepted due to the
                                        unavailability of the receive descriptor.*/

    uint32_t tx_interrupts;            /**< Number of transmit interrupts occurred.*/
    uint32_t tx_loss_of_carrier;    /**< Number of occurrences of; a loss of the carrier
                                        during a transmission.*/
    uint32_t tx_no_carrier;            /**< Number of occurrences of; the carrier was not asserted
                                        by an external transceiver during the transmission.*/
    uint32_t tx_late_collision;        /**< Number of occurrences of; a collision was detected
                                        after transmitting 64 bytes.*/
    uint32_t tx_excessive_collision;/**< Number of occurrences of; the transmission was
                                        aborted after 16 retries.*/
    uint32_t tx_collision_count;    /**< Number of collisions occurred.*/
    uint32_t tx_underflow_error;    /**< Number of occurrences of; the FIFO was empty during
                                        the frame transmission.*/
} mac_statistics_t;

/***************************************************************************//**
 mac_instance_t
  The mac_instance_t structure is used to identify the various Core10100_AHBAPB
  hardware instances in your system. Your application software must declare
  one instance of this structure for each instance of Core10100_AHBAPB in your
  system. The function MAC_init() initializes this structure. A pointer to an
  initialized instance of the structure must be passed as the first parameter
  to the Core10100_AHBAPB driver functions, to identify which Core10100_AHBAPB
  hardware instance should perform the requested operation.

  base_address:
    The base_address parameter is the base address in the processor's memory map
    for the registers of the Core10100_AHBAPB hardware instance.

  tx_complete_handler:
    The tx_complete_handle parameter holds the call-back function provided by
    user using the MAC_set_tx_callback() function for this instance of the
    ore10100_AHBAPB hardware instance. This call-back function will be called by
    this driver on completion of every packet transmit operation.

  pckt_rx_callback:
    The pckt_rx_callback parameter holds the call-back function provided by user
    using the MAC_set_rx_callback() function for this instance of the
    Core10100_AHBAPB hardware instance. This call-back function will be called by
    this driver on reception of a packet.

  phy_address:
    The phy_address parameter specifies the address of the PHY device, set in
    hardware by the address pins of the PHY device. The phy_address parameter can
    be a value from 0 to 31.

  tx_desc_index:
    The tx_desc_index parameter tracks the current transmit descriptor being used.

  tx_descriptors:
    The tx_descriptors parameter is the array of transmit packet descriptors.

  rx_descriptors:
    The rx_descriptors parameter is the array of receive packet descriptors.

  statistics:
    The statistics parameter is used to keep track of the transmit operation, the
    receive operation and the health of the Core10100_AHBAPB hardware instance.
    This parameter is used by this driver to return the statistics values to the
    user.

  first_tx_index:
    The first_tx_index parameter is the index of the first transmit descriptor
    in a sequence of transmit frames.

  last_tx_index:
    The last_tx_index parameter is the index of the last transmit descriptor in
    a sequence of transmit frames.

  next_free_tx_index:
    The next_free_tx_index parameter is the index of the next available transmit
    descriptor.

  next_free_rx_desc_index:
    The next_free_rx_desc_index parameter is the index of the next available
    receive descriptor.

  first_rx_desc_index:
    The first_rx_desc_index parameter is the index of the first receive
    descriptor in a sequence of received frames.

  previous_speed:
    The previous_speed parameter is used to detect changes in link speed. It is
    use to detect a change in link speed between calls to function
    MAC_get_link_status() and update the MAC hardware accordingly.

  previous_duplex_mode:
    The previous_duplex_mode parameter is used to detect changes in link duplex
    mode. It is use to detect a change in duplex mode between calls to function
    MAC_get_link_status() and update the MAC hardware accordingly.

*/
typedef struct
{
    addr_t        base_address;            /* Register base address of the driver*/
    mac_transmit_callback_t     tx_complete_handler;
    mac_receive_callback_t      pckt_rx_callback;

    uint8_t phy_address;            /* MII address of the connected PHY*/

    uint8_t local_mac_addr[6];

    /* transmit related info: */
    volatile mac_tx_descriptor_t tx_descriptors[MAC_TX_RING_SIZE];/* array of transmit descriptors*/

    /* receive related info: */
    volatile mac_rx_descriptor_t rx_descriptors[MAC_RX_RING_SIZE];  /* Array of receive descriptors*/
    mac_statistics_t statistics;

    /* Transmit descriptors management: */
    volatile int16_t    first_tx_index;
    volatile int16_t    last_tx_index;
    volatile int16_t    next_free_tx_index;

    /* Receive descriptors management: */
    volatile int16_t    next_free_rx_desc_index;
    volatile int16_t    first_rx_desc_index;

    /* Link status monitoring: */
    mac_speed_t previous_speed;
    uint8_t     previous_duplex_mode;

} mac_instance_t;

/***************************************************************************//**
 * Data structure internally used by the Core10100_AHBAPB driver.
 */

/******************************* FUNCTIONS ************************************/

/***************************************************************************//**
  @brief MAC_cfg_struct_def_init()
  The MAC_cfg_struct_def_init() function initializes a mac_cfg_t configuration
  data structure to default values. This default configuration can then be used
  as parameter to MAC_init(). Typically the default configuration would be
  modified to suit the application before being passed to MAC_init(). At a
  minimum you need to set the local MAC address.

  @param cfg
    The cfg parameter is a pointer to a mac_cfg_t data structure that will be used
    as a parameter to function MAC_init()

  @return
    This function does not return a value.

  Example:
  The example below demonstrates the use of the MAC_cfg_struct_def_init()
  function.

  @code
    #define MAC_BASE_ADDRESS    0x30000000
    #define PHY_ADDRESS            0

    mac_instance_t g_mac;
    mac_cfg_t core10100_cfg;

    MAC_cfg_struct_def_init(&core10100_cfg);

    mac_config.mac_addr[0] = MY_MAC_ADDR_0;
    mac_config.mac_addr[1] = MY_MAC_ADDR_1;
    mac_config.mac_addr[2] = MY_MAC_ADDR_2;
    mac_config.mac_addr[3] = MY_MAC_ADDR_3;
    mac_config.mac_addr[4] = MY_MAC_ADDR_4;
    mac_config.mac_addr[5] = MY_MAC_ADDR_5;

    MAC_init(&g_mac, MAC_BASE_ADDRESS, &core10100_cfg);
  @endcode
 */
void
MAC_cfg_struct_def_init
(
    mac_cfg_t * cfg
);

/***************************************************************************//**
  @brief MAC_init
  The MAC_init() function initializes the Core10100_AHBAPB hardware and the
  driver internal data structures. The MAC_init() function takes a pointer to a
  configuration data structure of type mac_cfg_t as parameter. This
  configuration data structure contains all the information required to
  configure the Core10100_AHBAPB. The MAC_init() function initializes the
  descriptor rings and their pointers to initial values. The configuration
  passed to the MAC_init() function specifies the allowed link speed and duplex
  mode. It is at this point that the application chooses the link speed and
  duplex mode to be advertised during auto-negotiation.

  @param instance
    The instance parameter is a pointer to a mac_instance_t structure identifying
    the Core10100_AHBAPB hardware instance to be initialized. A pointer to an
    initialized instance of the structure must be passed as the first parameter
    to the Core10100_AHBAPB driver functions to identify which Core10100_AHBAPB
    hardware instance should perform the requested operation.

  @param cfg
    The cfg parameter is a pointer to a data structure of type mac_cfg_t
    containing the requested configuration for the Core10100_AHBAPB hardware
    instance. This data structure must first be initialized by calling the
    MAC_cfg_struct_def_init() function to fill the configuration data structure
    with default values. You can then overwrite some of the default settings with
    the ones specific to the application before passing this data structure as
    parameter to the MAC_init() function. At a minimum the mac_addr[6] array of
    the configuration data structure must be overwritten to contain a unique value
    used as the device’s MAC address.

  @param base
    The base parameter is the base address in the processor's memory map for the
    registers of the Core10100_AHBAPB hardware instance being initialized.

  @return
    This function does not return a value.

  Example:
  This example demonstrates the use of the MAC_init() function to configure the
  Core10100_AHBAPB with the default configuration. Please note a unique MAC
  address must always be assigned through the configuration data passed as
  parameter to the MAC_init() function.

  @code
    #define MAC_BASE_ADDRESS    0x30000000
    #define PHY_ADDRESS            0

    mac_instance_t g_mac;
    mac_cfg_t core10100_cfg;

    MAC_cfg_struct_def_init(&core10100_cfg);

    mac_config.mac_addr[0] = MY_MAC_ADDR_0;
    mac_config.mac_addr[1] = MY_MAC_ADDR_1;
    mac_config.mac_addr[2] = MY_MAC_ADDR_2;
    mac_config.mac_addr[3] = MY_MAC_ADDR_3;
    mac_config.mac_addr[4] = MY_MAC_ADDR_4;
    mac_config.mac_addr[5] = MY_MAC_ADDR_5;

    MAC_init(&g_mac, MAC_BASE_ADDRESS, &core10100_cfg);
  @endcode
*/
void
MAC_init
(
    mac_instance_t * instance,
    addr_t base,
    const mac_cfg_t * cfg
);

/***************************************************************************//**
  @brief MAC_send_pkt
  The MAC_send_pkt()function initiates the transmission of a packet. It assigns
  the buffer containing the packet to be sent to one of the Core10100_AHBAPB’s
  transmit descriptors. This function is non-blocking. It will return
  immediately without waiting for the packet to be sent. The Core10100_AHBAPB
  driver indicates that the packet is sent by calling the transmit completion
  handler registered by a call to MAC_set_tx_callback().

  @param instance
    The instance parameter is a pointer to a mac_instance_t structure identifying
    the Core10100_AHBAPB hardware instance that will perform this function.

  @param tx_buffer
    The tx_buffer parameter is a pointer to the buffer containing the packet to be
    transmitted.

  @param tx_length
    The tx_length parameter specifies the length in bytes of the packet to be
    transmitted.

  @param p_user_data
    The p_user_data parameter is a pointer to an optional application defined data
    structure. Its usage is left to the application. It is intended to help the
    application manage memory allocated to store packets. The Core10100_AHBAPB
    driver does not make use of this pointer. The Core10100_AHBAPB driver will
    pass back this pointer to the application as part of the call to the transmit
    completion handler registered by the application.

  @return
    This function returns MAC_SUCCESS on successfully assigning the packet to a
    transmit descriptor. It returns MAC_FAILED otherwise.

  Example:
  This example demonstrates the use of the MAC_send_pkt() function. The
  application registers the tx_complete_callback() transmit completion callback
  function with the Core10100_AHBAPB driver by a call to MAC_set_tx_callback().
  The application dynamically allocates memory for an application defined
  packet_t data structure, builds a packet and calls send_packet(). The
  send_packet() function extracts the pointer to the buffer containing the data
  to transmit and its length from the tx_packet data structure and passes these
  to MAC_send_pkt(). It also passes the pointer to tx_packet as the p_user_data
  parameter. The Core10100_AHBAPB driver calls tx_complete_callback() once the
  packet is sent. The tx_complete_callback() function uses the p_user_data,
  which points to tx_packet, to release memory allocated by the application to
  stored the transmit packet.

  @code
    mac_instance_t g_mac;

    void tx_complete_callback(void * p_user_data);

    void init(void)
    {
        MAC_set_tx_callback(&g_mac, tx_complete_callback);
    }

    void tx_complete_callback (void * p_user_data)
    {
        release_packet_memory(p_user_data);
    }

    void send_packet(packet_t * tx_packet)
    {
        MAC_send_pkt(&g_mac, tx_packet->buffer, tx_packet->length, tx_packet);
    }
  @endcode
*/

uint8_t
MAC_send_pkt
(
    mac_instance_t * instance,
    uint8_t const * tx_buffer,
    uint32_t tx_length,
    void * p_user_data
);

/***************************************************************************//**
  @brief MAC_receive_pkt
  The MAC_receive_pkt() function assigns a buffer to one of  the Core10100_AHBAPB’s
  receive descriptors. The receive buffer specified as parameter will be
  used to receive one single packet. The receive buffer will be handed back to
  the application via a call to the receive callback function assigned through a
  call to MAC_set_rx_callback(). The MAC_receive_pkt() function will
  need to be called again pointing to the same buffer if more packets are to be
  received into this same buffer after the packet has been processed by the
  application.
  The MAC_receive_pkt() function is non-blocking. It will return immediately
  and does not wait for a packet to be received. The application needs to
  implement a receive callback function to be notified that a packet has been
  received.
  The p_user_data parameter can be optionally used to point to a memory
  management data structure managed by the application.

  @param instance
    The instance parameter is a pointer to a mac_instance_t structure identifying
    the Core10100_AHBAPB hardware instance that will perform this function.

  @param rx_pkt_buffer
    This rx_pkt_buffer parameter is a pointer to a memory buffer. It points to
    the memory that will be assigned to one of the Core10100_AHBAPB’s receive
    descriptors. It must point to a buffer large enough to contain the largest
    possible packet.

  @param p_user_data
    The p_user_data parameter is intended to help the application manage memory.
    Its usage is left to the application. The Core10100_AHBAPB driver does not make
    use of this pointer. The  Core10100_AHBAPB driver will pass this pointer back
    to the application as part of the call to the application’s receive callback
    function to help the application associate the received packet with the memory
    it allocated prior to the call to MAC_receive_pkt().

  @return
    This function returns MAC_SUCCESS on successfully assigning the buffer to a
    receive descriptor. It returns MAC_FAILED otherwise.

  Example:
  The example below demonstrates the use of the MAC_receive_pkt() function to
  handle packet reception. The init() function calls
  the MAC_set_rx_callback() function to register the rx_callback() receive
  callback function with the Core10100_AHBAPB driver. The MAC_receive_pkt()
  function is then called to assign rx_buffer_1 to Core10100_AHBAPB descriptors
  for packet reception. The rx_callback function will be called by the
  Core10100_AHBAPB driver once a packet has been received into one of the
  receive buffers. The rx_callback() function calls the process_rx_packet()
  application function to process the received packet then calls MAC_receive_pkt()
  to reallocate the receive buffer to receive another packet. The rx_callback()
  function will be called again every time a packet is received to process the
  received packet and reallocate rx_buffer for packet reception.

  Please note the use of the p_user_data parameter to handle the buffer
  reassignment to the Core10100_AHBAPB as part of the rx_callback() function.
  This is a simplistic use of p_user_data. It is more likely that p_user_data
  would be useful to keep track of a pointer to a TCP/IP stack packet container
  data structure that is dynamically allocated by the application. In this more
  complex use case, the rx_pkt_buffer parameter of MAC_receive_pkt() would point
  to the actual receive buffer and the p_user_data parameter would point to a
  data structure used to free the receive buffer memory once the packet has been
  consumed by the TCP/IP stack.

   @code
    mac_instance_t g_mac;
    uint8_t rx_buffer_1[MAC_MAX_PACKET_SIZE];

    void rx_callback
    (
        uint8_t * p_rx_packet,
        uint32_t pckt_length,
        void * p_user_data
    )
    {
        process_rx_packet(p_rx_packet, pckt_length);
        MAC_receive_pkt(&g_mac, (uint8_t *)p_user_data, p_user_data);
    }

    void init(void)
    {
        MAC_set_rx_callback(&g_mac, rx_callback);
        MAC_receive_pkt(&g_mac, rx_buffer_1, (void *)rx_buffer_1);
    }
   @endcode
*/
uint8_t
MAC_receive_pkt
(
    mac_instance_t * instance,
    uint8_t * rx_buffer,
    void * p_user_data
);

/***************************************************************************//**
  @brief MAC_get_link_status()
  The MAC_get_link_status () function retrieves the status of the link from the
  Ethernet PHY. It returns the current state of the Ethernet link. The speed and
  duplex mode of the link is also returned via the two pointers passed as
  parameter if the link is up. Calling this function also has the side effect of
  updating the MAC’s internal configuration in case the link speed or duplex
  mode changed since the last call to this function. It is recommended to call
  this function at regular interval to handle cable disconnection and
  reconnection ensuring that the MAC is configured properly in case of such an
  event taking place.

  @param instance
    The instance parameter is a pointer to a mac_instance_t structure identifying
    the Core10100_AHBAPB hardware instance that will perform this function.

  @param speed
    The speed parameter is a pointer to variable of type mac_speed_t where the
    current link speed will be stored if the link is up. This variable is not
    updated if the link is down. This parameter can be set to zero if the caller
    does not need to find out the link speed.

  @param fullduplex
    The fullduplex parameter is a pointer to an unsigned character where the
    current link duplex mode will be stored if the link is up. This variable is
    not updated if the link is down.

  @return
    This function returns MAC_LINK_UP, if the link is up. It returns 
    MAC_LINK_DOWN if the link is down.

  Example:
  @code
    mac_instance_t g_mac,
    uint8_t link_up;
    mac_speed_t speed;
    uint8_t full_duplex

    link_up = MAC_get_link_status(&g_mac, &speed, &full_duplex);

  @endcode
 */
uint8_t
MAC_get_link_status
(
    mac_instance_t * instance,
    mac_speed_t * speed,
    uint8_t * fullduplex
);

/***************************************************************************//**
  MAC interrupt service routine.
  This routine should only be triggered by the interrupt handler.

  @param instance
    The instance parameter is the pointer to a mac_instance_t structure which will
    hold all data regarding this instance of the Core10100_AHBAPB hardware.
 */
void
MAC_isr
(
    mac_instance_t * instance
);

/***************************************************************************//**
  @brief MAC_read_stat()
  The MAC_read_stat()  function reads the transmit and receive statistics collected
  by the Core10100_AHBAPB driver. This function can be used to read one of statistics
  value as defined in the mac_stat_t enumeration.

  @param instance
  The instance parameter is a pointer to a mac_instance_t structure identifying 
  the Core10100_AHBAPB hardware instance that will perform this function.

  @param stat_id
  The stat_id parameter identifies the statistic that will be read. The allowed 
  values for stat_id are defined in the mac_stat_t enumeration.

  @return
    This function returns the value of the requested statistic.

  Example:
  @code
    uint32_t tx_pkts_cnt = MAC_read_stat(MAC_RX_INTERRUPTS);
  @endcode

*/
uint32_t
MAC_read_stat
(
    const mac_instance_t * instance,
    mac_stat_t stat_id
);

/***************************************************************************//**
  @brief MAC_set_tx_callback()
  The MAC_set_tx_callback() function registers the function that will be
  called by the Core10100_AHBAPB driver when a packet has been sent.

  @param instance
    The instance parameter is a pointer to a mac_instance_t structure identifying
    the Core10100_AHBAPB hardware instance that will perform this function.

  @param tx_complete_handler
    The tx_complete_handler parameter is a pointer to the function that will be
    called when a packet is sent by the Core10100_AHBAPB.

  @return
    This function does not return a value.

  Example:
  @code
    mac_instance_t g_mac;
    void tx_complete_callback(void * p_user_data);

    void init(void)
    {
        MAC_set_tx_callback(&g_mac, tx_complete_callback);
    }

    void tx_complete_callback (void * p_user_data)
    {
        release_packet_memory(p_user_data);
    }

    void send_packet(packet_t * tx_packet)
    {
        MAC_send_pkt(&g_mac, tx_packet->buffer, tx_packet->length, tx_packet);
    }
  @endcode

 */
void MAC_set_tx_callback
(
    mac_instance_t * instance,
    mac_transmit_callback_t tx_complete_handler
);

/***************************************************************************//**
  @brief MAC_set_rx_callback()
  The MAC_set_rx_callback() function registers the function that will be
  called by the Core10100_AHBAPB driver when a packet is received.

  @param instance
    The instance parameter is a pointer to a mac_instance_t structure identifying
    the Core10100_AHBAPB hardware instance that will perform this function.

  @param rx_callback
    The rx_callback parameter is a pointer to the function that will be called when a
    acket is received by the Core10100_AHBAPB.

  Example:
  @code
    uint8_t rx_buffer[MAC_MAX_PACKET_SIZE];
    Mac_instance_t instance;

    void rx_callback
    (
        uint8_t * p_rx_packet,
        uint32_t pckt_length,
        void * p_user_data
    )
    {
        process_rx_packet(p_rx_packet, pckt_length);
        MAC_receive_pkt(&instance, rx_buffer, (void *)0);
    }

    void init(void)
    {
        MAC_set_rx_callback(&instance, rx_callback);
        MAC_receive_pkt(&instance, rx_buffer, (void *)0);
    }
  @endcode
 */
void MAC_set_rx_callback
(
    mac_instance_t * instance,
    mac_receive_callback_t rx_callback
);

/***************************************************************************//**
  @brief MAC_set_address_filter()
    The MAC_set_address_filter() function implements the frame filtering
    functionality of the driver. This function is used to specify the list of
    destination MAC addresses of received frames that will be passed to the MAC.
    This function takes an array of MAC addresses as parameter and generates the
    correct hash table for that list of addresses.

  @param instance
    The instance parameter is a pointer to a mac_instance_t structure identifying
    the Core10100_AHBAPB hardware instance that will perform this function.

  @param  mac_addresses
    The mac_addresses parameter is a pointer to the buffer containing the MAC
    addresses that are used to generate the MAC address hash table.

  @param nb_addresses
    The nb_addresses parameter specifies the number of mac addresses being
    passed in the buffer pointed by the mac_addresses buffer pointer.

    Note: Each MAC address consists of 6 octets and must be placed in the
    buffer starting with the first (most significant) octet of the MAC address.

  @return
    This function does not return a value.

  Example:
    This example demonstrates the use of the MAC_set_address_filter() function
    to handle frame filtering.

  @code
    #define CORE10100_BASE_ADDRESS  0x31000000
    mac_instance_t g_core10100;
    mac_cfg_t mac_config;

    uint8_t mac_data[4][6] = {{0x10, 0x10, 0x10, 0x10, 0x10, 0x10},
                      {0x43, 0x40, 0x40, 0x40, 0x40, 0x43},
                      {0xC0, 0xB1, 0x3C, 0x60, 0x60, 0x60},
                      {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF}};

    MAC_cfg_struct_def_init(&mac_config);
    mac_config.mac_addr[0] = 0xC0;
    mac_config.mac_addr[1] = 0xB1;
    mac_config.mac_addr[2] = 0x3C;
    mac_config.mac_addr[3] = 0x60;
    mac_config.mac_addr[4] = 0x60;
    mac_config.mac_addr[5] = 0x60;

    MAC_init(&g_core10100, CORE10100_BASE_ADDRESS, &mac_config);

    MAC_set_address_filter(&g_core10100, mac_data[0], 4);
  @endcode
 */
void MAC_set_address_filter
(
    mac_instance_t * instance,
    const uint8_t mac_addresses[],
    uint32_t nb_addresses
);

/***************************************************************************//**
  @brief MAC_clear_statistics()
    The MAC_clear_statistics() function clears all the statistics counter
    registers.

  @param instance
    The instance parameter is a pointer to a mac_instance_t structure identifying
    the Core10100_AHBAPB hardware instance that will perform this function.

  @return
    This function does not return a value.
 */
void MAC_clear_statistics
(
    mac_instance_t * instance
);

#ifdef __cplusplus
}
#endif

#endif    /* CORE10100_AHBAPB_H */

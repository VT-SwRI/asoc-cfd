/***************************************************************************//**
 * (c) Copyright 2012-2015 Microsemi SoC Products Group.  All rights reserved.
 *
 * Header file for Core10100_AHBAPB driver.
 * Core10100_AHBAPB driver internal definitions.
 *
 *
 * SVN $Revision: 7708 $
 * SVN $Date: 2015-08-28 15:31:15 +0530 (Fri, 28 Aug 2015) $
 *
 *
 *******************************************************************************/
#ifndef CORE10100_AHBAPB_DESC_H
#define CORE10100_AHBAPB_DESC_H    1

#ifdef __cplusplus
extern "C" {
#endif 
/*******************************************************************************
 * Receive descriptor bits
 */

/***************************************************************************//**
 * Ownership bit.
 * 1 - Core10/100 owns the descriptor.
 * 0 - The host owns the descriptor.
 * Core10/100 will clear this bit when it completes a current frame reception or
 * when the data buffers associated with a given descriptor are already full.
 */
#define RDES0_OWN   ((uint32_t)0x80000000U)

/***************************************************************************//**
 * Filtering fail.
 * When set, indicates that a received frame did not pass the address recognition 
 * process.
 * This bit is valid only for the last descriptor of the frame (RDES0.8 set), 
 * when the CSR6.30 (receive all) bit
 * is set and the frame is at least 64 bytes long.
 */
#define RDES0_FF    ((uint32_t)0x40000000U)

/***************************************************************************//**
 * Frame length.
 * Indicates the length, in bytes, of the data transferred into a host memory 
 * for a given frame
 * This bit is valid only when RDES0.8 (last descriptor) is set and RDES0.14 
 * (descriptor error) is cleared.
 */
#define RDES0_FL_MASK       ((uint32_t)0x00003FFFU)
#define RDES0_FL_OFFSET     16U

/***************************************************************************//**
 * Error summary.
 * This bit is a logical OR of the following bits:
 * RDES0.1 - CRC error
 * RDES0.6 - Collision seen
 * RDES0.7 - Frame too long
 * RDES0.11 - Runt frame
 * RDES0.14 - Descriptor error
 * This bit is valid only when RDES0.8 (last descriptor) is set.
 */
#define RDES0_ES    ((uint32_t)0x00008000U)

/***************************************************************************//**
 * Descriptor error.
 * Set by Core10/100 when no receive buffer was available when trying to store 
 * the received data.
 * This bit is valid only when RDES0.8 (last descriptor) is set.
 */
#define RDES0_DE    ((uint32_t)0x00004000U)

/***************************************************************************//**
 * Runt frame.
 * When set, indicates that the frame is damaged by a collision or by a premature 
 * termination before the end
 * of a collision window.
 * This bit is valid only when RDES0.8 (last descriptor) is set.
 */
#define RDES0_RF    ((uint32_t)0x00000800U)

/***************************************************************************//**
 * Multicast frame.
 * When set, indicates that the frame has a multicast address.
 * This bit is valid only when RDES0.8 (last descriptor) is set.
 */
#define RDES0_MF    ((uint32_t)0x00000400U)

/***************************************************************************//**
 * First descriptor.
 * When set, indicates that this is the first descriptor of a frame.
 */
#define RDES0_FS    ((uint32_t)0x00000200U)

/***************************************************************************//**
 * Last descriptor.
 * When set, indicates that this is the last descriptor of a frame.
 */
#define RDES0_LS    ((uint32_t)0x00000100U)

/***************************************************************************//**
 * Frame too long.
 * When set, indicates that a current frame is longer than maximum size of 1,518 
 * bytes, as specified by 802.3.
 * TL (frame too long) in the receive descriptor has been set when the received 
 * frame is longer than
 * 1,518 bytes. This flag is valid in all receive descriptors when multiple 
 * descriptors are used for one frame.
 */
#define RDES0_TL    ((uint32_t)0x00000080U)

/***************************************************************************//**
 * Collision seen.
 * When set, indicates that a late collision was seen (collision after 64 bytes 
 * following SFD).
 * This bit is valid only when RDES0.8 (last descriptor) is set.
 */
#define RDES0_CS    ((uint32_t)0x00000040U)

/***************************************************************************//**
 * Frame type.
 * When set, indicates that the frame has a length field larger than 1,500 
 * (Ethernet-type frame). When cleared, indicates an 802.3-type frame.
 * This bit is valid only when RDES0.8 (last descriptor) is set.
 * Additionally, FT is invalid for runt frames shorter than 14 bytes.
 */
#define RDES0_FT    ((uint32_t)0x00000020U)

/***************************************************************************//**
 * Report on MII error.
 * When set, indicates that an error has been detected by a physical layer chip 
 * connected through the MII interface.
 * This bit is valid only when RDES0.8 (last descriptor) is set.
 */
#define RDES0_RE    ((uint32_t)0x00000008U)

/***************************************************************************//**
 * Dribbling bit.
 * When set, indicates that the frame was not byte-aligned.
 * This bit is valid only when RDES0.8 (last descriptor) is set.
 */
#define RDES0_DB    ((uint32_t)0x00000004U)

/***************************************************************************//**
 * CRC error.
 * When set, indicates that a CRC error has occurred in the received frame.
 * This bit is valid only when RDES0.8 (last descriptor) is set.
 * Additionally, CE is not valid when the received frame is a runt frame.
 */
#define RDES0_CE    ((uint32_t)0x00000002U)

/***************************************************************************//**
 * This bit is reset for frames with a legal length.
 */
#define RDES0_ZERO  ((uint32_t)0x00000001U)

/***************************************************************************//**
 * Receive end of ring.
 * When set, indicates that this is the last descriptor in the receive descriptor 
 * ring. Core10/100 returns to the first descriptor in the ring, as specified by 
 * CSR3 (start of receive list address).
 */
#define RDES1_RER   0x02000000U

/***************************************************************************//**
 * Second address chained.
 * When set, indicates that the second buffer's address points to the next 
 * descriptor and not to the data buffer.
 * Note that RER takes precedence over RCH.
 */
#define RDES1_RCH   0x01000000U

/***************************************************************************//**
 * Buffer 2 size.
 * Indicates the size, in bytes, of memory space used by the second data buffer. 
 * This number must be a multiple of four. If it is 0, Core10/100 ignores the 
 * second data buffer and fetches the next data descriptor.
 * This number is valid only when RDES1.24 (second address chained) is cleared.
 */
#define RDES1_RBS2_MASK         0x7FFU
#define RDES1_RBS2_OFFSET       11U

/***************************************************************************//**
 * Buffer 1 size
 * Indicates the size, in bytes, of memory space used by the first data buffer. 
 * This number must be a multiple of four. If it is 0, Core10/100 ignores the 
 * first data buffer and uses the second data buffer.
 */
#define RDES1_RBS1_MASK         0x7FFU
#define RDES1_RBS1_OFFSET       0U


/*******************************************************************************
 * Transmit descriptor bits
 */

/***************************************************************************//**
 * Ownership bit.
 * 1 - Core10/100 owns the descriptor.
 * 0 - The host owns the descriptor.
 * Core10/100 will clear this bit when it completes a current frame transmission 
 * or when the data buffers
 * associated with a given descriptor are empty.
 */
#define TDES0_OWN     ((uint32_t)0x80000000U)

/***************************************************************************//**
 * Error summary.
 * This bit is a logical OR of the following bits:
 * TDES0.1 - Underflow error
 * TDES0.8 - Excessive collision error
 * TDES0.9 - Late collision
 * TDES0.10 - No carrier
 * TDES0.11 - Loss of carrier
 * This bit is valid only when TDES1.30 (last descriptor) is set.
 */
#define TDES0_ES      (1U << 15U)

/***************************************************************************//**
 * Loss of carrier.
 * When set, indicates a loss of the carrier during a transmission.
 * This bit is valid only when TDES1.30 (last descriptor) is set.
 */
#define TDES0_LO      (1U << 11U)

/***************************************************************************//**
 * No carrier.
 * When set, indicates that the carrier was not asserted by an external 
 * transceiver during the transmission.
 * This bit is valid only when TDES1.30 (last descriptor) is set.
 */
#define TDES0_NC      (1U << 10U)

/***************************************************************************//**
 * Late collision.
 * When set, indicates that a collision was detected after transmitting 64 bytes.
 * This bit is not valid when TDES0.1 (underflow error) is set.
 * This bit is valid only when TDES1.30 (last descriptor) is set.
 */
#define TDES0_LC      (1U << 9U)

/***************************************************************************//**
 * Excessive collisions.
 * When set, indicates that the transmission was aborted after 16 retries.
 * This bit is valid only when TDES1.30 (last descriptor) is set.
 */
#define TDES0_EC      (1U << 8U)

/***************************************************************************//**
 * Collision count.
 * This field indicates the number of collisions that occurred before the end of 
 * a frame transmission.
 * This value is not valid when TDES0.8 (excessive collisions bit) is set.
 * This bit is valid only when TDES1.30 (last descriptor) is set.
 */
#define TDES0_CC_MASK       0xFU
#define TDES0_CC_OFFSET     3U

/***************************************************************************//**
 * Underflow error.
 * When set, indicates that the FIFO was empty during the frame transmission.
 * This bit is valid only when TDES1.30 (last descriptor) is set.
 */
#define TDES0_UF      (1U << 1U)

/***************************************************************************//**
 * Deferred.
 * When set, indicates that the frame was deferred before transmission. 
 * Deferring occurs if the carrier is detected when the transmission is ready to 
 * start.
 * This bit is valid only when TDES1.30 (last descriptor) is set.
 */
#define TDES0_DE      (1U)

/***************************************************************************//**
 * Interrupt on completion.
 * Setting this flag instructs Core10/100 to set CSR5.0 (transmit interrupt) 
 * immediately after processing a current frame.
 * This bit is valid when TDES1.30 (last descriptor) is set or for a setup packet.
 */
#define TDES1_IC      (1U << 31U)

/***************************************************************************//**
 * Last descriptor.
 * When set, indicates the last descriptor of the frame.
 */
#define TDES1_LS      (1U << 30U)

/***************************************************************************//**
 * First descriptor.
 * When set, indicates the first descriptor of the frame.
 */
#define TDES1_FS      (1U << 29U)

/***************************************************************************//**
 * Filtering type.
 * This bit, together with TDES0.22 (FT0), controls a current filtering mode.
 * This bit is valid only for the setup frames.
 */
#define TDES1_FT1     (1U << 28U)

/***************************************************************************//**
 * Setup packet.
 * When set, indicates that this is a setup frame descriptor.
 */
#define TDES1_SET     (1U << 27U)

/***************************************************************************//**
 * Add CRC disable.
 * When set, Core10/100 does not append the CRC value at the end of the frame. 
 * The exception is when the frame is shorter than 64 bytes and automatic byte 
 * padding is enabled. In that case, the CRC field is added, despite the state 
 * of the AC flag.
 */
#define TDES1_AC      (1U << 26U)

/***************************************************************************//**
 * Transmit end of ring.
 * When set, indicates the last descriptor in the descriptor ring.
 */
#define TDES1_TER     (1U << 25U)

/***************************************************************************//**
 * Second address chained.
 * When set, indicates that the second descriptor's address points to the next 
 * descriptor and not to the data buffer.
 * This bit is valid only when TDES1.25 (transmit end of ring) is reset.
 */
#define TDES1_TCH     (1U << 24U)

/***************************************************************************//**
 * Disabled padding.
 * When set, automatic byte padding is disabled. Core10/100 normally appends the 
 * PAD field after the INFO field when the size of an actual frame is less than 
 * 64 bytes. After padding bytes, the CRC field is also inserted, despite the 
 * state of the AC flag. When DPD is set, no padding bytes are appended.
 */
#define TDES1_DPD     (1U << 23U)

/***************************************************************************//**
 * Filtering type.
 * This bit, together with TDES0.28 (FT1), controls the current filtering mode.
 * This bit is valid only when the TDES1.27 (SET) bit is set.
 */
#define TDES1_FT0     (1U << 22U)

/***************************************************************************//**
 * Buffer 2 size.
 * Indicates the size, in bytes, of memory space used by the second data buffer. 
 * If it is zero, Core10/100 ignores the second data buffer and fetches the next 
 * data descriptor.
 * This bit is valid only when TDES1.24 (second address chained) is cleared.
 */
#define TDES1_TBS2_MASK         0x7FFU
#define TDES1_TBS2_OFFSET       11U

/***************************************************************************//**
 * Buffer 1 size.
 * Indicates the size, in bytes, of memory space used by the first data buffer. 
 * If it is 0, Core10/100 ignores the first data buffer and uses the second data 
 * buffer.
 */
#define TDES1_TBS1_MASK        0x7FFU
#define TDES1_TBS1_OFFSET    0U

#ifdef __cplusplus
}
#endif

#endif    /* CORE10100_AHBAPB_DESC_H */

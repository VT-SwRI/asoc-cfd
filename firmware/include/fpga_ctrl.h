#pragma once
#include <stdbool.h>
#include <stdint.h>
#include "asoc_error.h"

/**
 * Firmware-visible FPGA register map.
 *
 * The FPGA image should implement these registers (or you should update
 * the offsets here to match your HDL).
 */
typedef enum {
  FPGA_REG_ID             = 0x0000, /* RO: ASCII 'ASOC' or similar */
  FPGA_REG_VERSION        = 0x0004, /* RO: [31:16]=major, [15:0]=minor */
  FPGA_REG_CTRL           = 0x0008, /* RW: bit0=run, bit1=reset_asoc, bit2=soft_reset */
  FPGA_REG_STATUS         = 0x000C, /* RO: bit0=run, bit1=asoc_locked, bit2=fifo_overflow */
  FPGA_REG_IRQ_ENABLE     = 0x0010, /* RW */
  FPGA_REG_IRQ_STATUS     = 0x0014, /* W1C */
  FPGA_REG_RUN_ID         = 0x0018, /* RW: user-defined run counter/tag */
  FPGA_REG_ACQ_CFG0       = 0x0020, /* RW: samples_per_event, pretrigger, etc. (packed) */
  FPGA_REG_ACQ_CFG1       = 0x0024, /* RW: channel mask, decimation, etc. */
  FPGA_REG_CFD_CFG0       = 0x0030, /* RW: global CFD configuration */
  FPGA_REG_CFD_CFG1       = 0x0034, /* RW: threshold and flags */
  FPGA_REG_FIFO_LEVEL     = 0x0040, /* RO: words available in readout FIFO */
  FPGA_REG_FIFO_DATA      = 0x0044, /* RO: pops one word (when read) */
} fpga_reg_off_t;

typedef struct {
  uint32_t base;
} fpga_ctrl_t;

void fpga_ctrl_init(fpga_ctrl_t *f, uint32_t base_addr);

uint32_t fpga_ctrl_read32(const fpga_ctrl_t *f, fpga_reg_off_t off);
void     fpga_ctrl_write32(const fpga_ctrl_t *f, fpga_reg_off_t off, uint32_t v);

asoc_status_t fpga_ctrl_soft_reset(const fpga_ctrl_t *f);
asoc_status_t fpga_ctrl_set_run(const fpga_ctrl_t *f, bool enable);

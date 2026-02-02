#include "fpga_ctrl.h"
#include "platform/platform.h"

void fpga_ctrl_init(fpga_ctrl_t *f, uint32_t base_addr) {
  f->base = base_addr;
}

uint32_t fpga_ctrl_read32(const fpga_ctrl_t *f, fpga_reg_off_t off) {
  return platform_mmio_read32(f->base + (uint32_t)off);
}

void fpga_ctrl_write32(const fpga_ctrl_t *f, fpga_reg_off_t off, uint32_t v) {
  platform_mmio_write32(f->base + (uint32_t)off, v);
}

asoc_status_t fpga_ctrl_soft_reset(const fpga_ctrl_t *f) {
  uint32_t ctrl = fpga_ctrl_read32(f, FPGA_REG_CTRL);
  ctrl |= (1u << 2);
  fpga_ctrl_write32(f, FPGA_REG_CTRL, ctrl);
  /* optional: deassert */
  ctrl &= ~(1u << 2);
  fpga_ctrl_write32(f, FPGA_REG_CTRL, ctrl);
  return ASOC_OK;
}

asoc_status_t fpga_ctrl_set_run(const fpga_ctrl_t *f, bool enable) {
  uint32_t ctrl = fpga_ctrl_read32(f, FPGA_REG_CTRL);
  if (enable) ctrl |= 1u;
  else ctrl &= ~1u;
  fpga_ctrl_write32(f, FPGA_REG_CTRL, ctrl);
  return ASOC_OK;
}

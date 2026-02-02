#include "acq_manager.h"

void acq_manager_init(acq_manager_t *m, fpga_ctrl_t *fpga, asoc_asic_t *asic) {
  m->st = ACQ_IDLE;
  m->fpga = fpga;
  m->asic = asic;
}

asoc_status_t acq_manager_configure(acq_manager_t *m) {
  if (m->st != ACQ_IDLE) return ASOC_ESTATE;
  asoc_status_t st = asoc_asic_reset(m->asic);
  if (st != ASOC_OK) { m->st = ACQ_ERROR; return st; }

  st = asoc_asic_apply_default_config(m->asic);
  if (st != ASOC_OK) { m->st = ACQ_ERROR; return st; }

  m->st = ACQ_CONFIGURED;
  return ASOC_OK;
}

asoc_status_t acq_manager_start(acq_manager_t *m) {
  if (m->st != ACQ_CONFIGURED) return ASOC_ESTATE;
  fpga_ctrl_set_run(m->fpga, true);
  m->st = ACQ_RUNNING;
  return ASOC_OK;
}

asoc_status_t acq_manager_stop(acq_manager_t *m) {
  if (m->st != ACQ_RUNNING) return ASOC_ESTATE;
  fpga_ctrl_set_run(m->fpga, false);
  m->st = ACQ_CONFIGURED;
  return ASOC_OK;
}

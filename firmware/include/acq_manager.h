#pragma once
#include <stdint.h>
#include "asoc_error.h"
#include "fpga_ctrl.h"
#include "asoc_asic.h"

typedef enum {
  ACQ_IDLE = 0,
  ACQ_CONFIGURED,
  ACQ_RUNNING,
  ACQ_ERROR,
} acq_state_t;

typedef struct {
  acq_state_t st;
  fpga_ctrl_t *fpga;
  asoc_asic_t *asic;
} acq_manager_t;

void acq_manager_init(acq_manager_t *m, fpga_ctrl_t *fpga, asoc_asic_t *asic);

asoc_status_t acq_manager_configure(acq_manager_t *m);
asoc_status_t acq_manager_start(acq_manager_t *m);
asoc_status_t acq_manager_stop(acq_manager_t *m);

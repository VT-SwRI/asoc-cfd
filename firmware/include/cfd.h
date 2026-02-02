#pragma once
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "asoc_error.h"

typedef struct {
  /* fraction in Q15 (0..32767 corresponds to 0..(1-1/32768)) */
  uint16_t fraction_q15;
  /* delay in samples */
  uint16_t delay_samp;
  /* threshold (ADC codes after baseline subtraction) */
  int16_t threshold;
  /* pulse polarity: true for negative-going pulses */
  bool negative;
} cfd_params_t;

typedef struct {
  /* Time of threshold crossing in fractional sample units, Q16.16 */
  int32_t t_cross_q16_16;
  /* Peak amplitude after baseline subtraction */
  int16_t peak;
  /* Baseline estimate */
  int16_t baseline;
  /* Index of peak sample */
  uint16_t peak_index;
} cfd_result_t;

/**
 * Digital CFD using delayed subtraction:
 *   y[n] = frac*x[n] - x[n-delay]
 * Crossing time is the first sign change through threshold.
 *
 * samples: signed ADC codes (already converted to signed polarity)
 */
asoc_status_t cfd_compute(const int16_t *samples, size_t n,
                          const cfd_params_t *p,
                          cfd_result_t *out);

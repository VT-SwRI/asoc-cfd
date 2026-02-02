#include "cfd.h"

asoc_status_t cfd_compute(const int16_t *s, size_t n,
                          const cfd_params_t *p,
                          cfd_result_t *out) {
  if (!s || !p || !out || n < 8) return ASOC_EINVAL;
  if (p->delay_samp == 0 || p->delay_samp >= n) return ASOC_EINVAL;

  /* Baseline: average first 8 samples (simple, deterministic). */
  int32_t sum = 0;
  size_t nb = (n < 8) ? n : 8;
  for (size_t i = 0; i < nb; i++) sum += s[i];
  int16_t baseline = (int16_t)(sum / (int32_t)nb);

  /* Polarity normalize so we always look for positive pulses internally. */
  /* Caller may already provide signed samples; we keep a local view. */
  int16_t peak = 0;
  uint16_t peak_i = 0;

  /* Find peak (max value) after baseline subtraction. */
  for (size_t i = 0; i < n; i++) {
    int16_t v = (int16_t)(s[i] - baseline);
    if (p->negative) v = (int16_t)-v;
    if (v > peak) { peak = v; peak_i = (uint16_t)i; }
  }

  /* Must exceed threshold to be considered a hit. */
  if (peak < p->threshold) return ASOC_ETIMEOUT;

  /* Compute CFD waveform y[n] and find first crossing above 0. */
  const uint16_t d = p->delay_samp;
  int32_t prev_y = 0;
  bool has_prev = false;

  for (size_t i = d; i < n; i++) {
    int32_t x_now  = (int32_t)(s[i] - baseline);
    int32_t x_del  = (int32_t)(s[i - d] - baseline);
    if (p->negative) { x_now = -x_now; x_del = -x_del; }

    /* y = frac*x_now - x_del */
    int32_t y = ((int32_t)p->fraction_q15 * x_now) / 32768 - x_del;

    if (!has_prev) {
      prev_y = y;
      has_prev = true;
      continue;
    }

    /* Detect rising through 0 (or through some small hysteresis). */
    if (prev_y < 0 && y >= 0) {
      /* Linear interpolation: t = (i-1) + (-prev_y)/(y-prev_y) */
      int32_t dy = (y - prev_y);
      if (dy == 0) dy = 1;
      int32_t frac_q16 = (int32_t)(((-prev_y) << 16) / dy);
      out->t_cross_q16_16 = (int32_t)(((int32_t)(i - 1) << 16) + frac_q16);
      out->baseline = baseline;
      out->peak = peak;
      out->peak_index = peak_i;
      return ASOC_OK;
    }

    prev_y = y;
  }

  return ASOC_ETIMEOUT;
}

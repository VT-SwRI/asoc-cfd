#pragma once
#include <stdint.h>

/**
 * Board-level parameters (compile-time defaults).
 *
 * These defaults reflect public ASoC family specs:
 * - 4 channels, multi-GSa/s sampling, long buffering. See Nalu public docs. 
 *
 * Override these with -DASOC_SAMPLE_RATE_HZ=... etc if needed.
 */

#ifndef ASOC_CHANNELS
#define ASOC_CHANNELS 4u
#endif

#ifndef ASOC_SAMPLE_RATE_HZ
#define ASOC_SAMPLE_RATE_HZ 3200000000ull
#endif

#ifndef ASOC_BUFFER_SAMPLES
#define ASOC_BUFFER_SAMPLES 16384u
#endif

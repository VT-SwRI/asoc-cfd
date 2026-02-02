/* ASOC Firmware Skeleton (Example / Template)
 *
 * This is an example/template file in firmware/src/.
 * Use this directory to implement embedded firmware that configures the ASOC
 * ASIC, controls the FPGA readout, and coordinates data acquisition runs.
 *
 * When designing real firmware, consult:
 *   - docs/ASOCv3 Quick Start Guide.pdf
 *   - docs/ASoCv3 Product Sheet.pdf (for register and mode descriptions)
 *   - docs/NaluScope.0.22.3.-.ASoCv3.User.Manual.pdf (for typical operating
 *     modes and configuration sequences)
 *
 * Replace this file with real modules or copy/rename it as a starting point.
 */

#include <stdint.h>

/* TODO: include platform-specific headers from firmware/platform/. */
#include "platform_config_example.h"

/* -------------------------------------------------------------------------
 * ASOC configuration API (placeholders)
 * ------------------------------------------------------------------------- */

static void asoc_init(void)
{
    /* TODO: initialize clocks, GPIOs, and communication interfaces
     * (e.g., SPI, I2C, or memory-mapped registers) needed to talk to ASOC.
     */
}

static void asoc_configure_default(void)
{
    /* TODO: write ASOC configuration registers to set up sampling rate,
     * channel enables, trigger thresholds, etc. Document the chosen settings
     * in docs/fpga/ and docs/experiments/.
     */
}

static void asoc_start_run(void)
{
    /* TODO: assert control signals or write registers that start acquisitions.
     * Consider matching behavior to NaluScope where practical.
     */
}

static void asoc_stop_run(void)
{
    /* TODO: gracefully stop acquisitions and flush any remaining data. */
}

static void asoc_service_run(void)
{
    /* TODO: poll status, handle interrupts, and communicate with host DAQ
     * software (e.g., over USB, UART, or Ethernet) to stream waveform data.
     */
}

int main(void)
{
    /* High-level firmware flow:
     *   1. Initialize platform (clocks, peripherals, FPGA interface).
     *   2. Initialize and configure ASOC.
     *   3. Enter run loop to acquire data until commanded to stop.
     */

    asoc_init();
    asoc_configure_default();
    asoc_start_run();

    while (1) {
        asoc_service_run();
        /* TODO: add exit condition or command handling. */
    }

    asoc_stop_run();
    return 0;
}


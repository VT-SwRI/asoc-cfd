#include "platform/platform.h"
#include "asoc_log.h"
#include "asoc_fw_version.h"
#include "fpga_ctrl.h"
#include "asoc_bus_spi.h"
#include "asoc_asic.h"
#include "acq_manager.h"
#include "asoc_cli.h"

fpga_ctrl_t g_fpga;
asoc_asic_t g_asic;

int main(void) {
  platform_init();

  asoc_logf("ASoC FW %u.%u.%u\n", ASOC_FW_VERSION_MAJOR, ASOC_FW_VERSION_MINOR, ASOC_FW_VERSION_PATCH);

  fpga_ctrl_init(&g_fpga, FPGA_REG_BASE);

  /* ASIC bus: start with SPI portal backend (adjust as needed for your board). */
  asoc_bus_spi_ctx_t spi_ctx = { .addr_hi_mask = 0x7Fu };
  asoc_bus_t bus = asoc_bus_spi_make(&spi_ctx);
  asoc_asic_init(&g_asic, bus);

  acq_manager_t acq;
  acq_manager_init(&acq, &g_fpga, &g_asic);

  asoc_cli_t cli;
  asoc_cli_init(&cli);

  asoc_logf("Type 'help' + Enter\n");

  while (1) {
    uint8_t b = 0;
    if (platform_uart_read_byte(&b)) {
      if (asoc_cli_feed(&cli, b)) {
        (void)asoc_cli_process(cli.line);
      }
    }
    /* In a real build you would also service IRQs, watchdogs, and streaming. */
  }

  return 0;
}

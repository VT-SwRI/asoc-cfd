#include "asoc_cli.h"
#include "asoc_log.h"
#include "asoc_fw_version.h"
#include "fpga_ctrl.h"
#include "asoc_asic.h"
#include <ctype.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* These are owned by main.c */
extern fpga_ctrl_t g_fpga;
extern asoc_asic_t g_asic;

static void trim(char *s) {
  /* trim leading */
  while (*s && isspace((unsigned char)*s)) memmove(s, s+1, strlen(s));
  /* trim trailing */
  size_t n = strlen(s);
  while (n && isspace((unsigned char)s[n-1])) s[--n] = 0;
}

static int tok(char *s, char **argv, int maxv) {
  int n = 0;
  trim(s);
  while (*s && n < maxv) {
    while (*s && isspace((unsigned char)*s)) s++;
    if (!*s) break;
    argv[n++] = s;
    while (*s && !isspace((unsigned char)*s)) s++;
    if (*s) *s++ = 0;
  }
  return n;
}

static uint32_t parse_u32(const char *s, int *ok) {
  char *end = NULL;
  uint32_t v = (uint32_t)strtoul(s, &end, 0);
  *ok = (end && *end == 0);
  return v;
}

void asoc_cli_init(asoc_cli_t *cli) { cli->len = 0; }

int asoc_cli_feed(asoc_cli_t *cli, uint8_t b) {
  if (b == '\r') return 0;
  if (b == '\n') {
    cli->line[cli->len] = 0;
    cli->len = 0;
    return 1;
  }
  if (cli->len + 1 < sizeof(cli->line)) {
    cli->line[cli->len++] = (char)b;
  }
  return 0;
}

asoc_status_t asoc_cli_process(const char *line_in) {
  char line[128];
  strncpy(line, line_in, sizeof(line));
  line[sizeof(line)-1] = 0;

  char *argv[8] = {0};
  int argc = tok(line, argv, 8);
  if (argc == 0) return ASOC_OK;

  if (strcmp(argv[0], "help") == 0) {
    asoc_logf(
      "Commands:\n"
      "  help\n"
      "  ver\n"
      "  fpga.rd <off>\n"
      "  fpga.wr <off> <val>\n"
      "  run <0|1>\n"
      "  asic.wr <addr> <val>\n"
      "  asic.rd <addr>\n"
    );
    return ASOC_OK;
  }

  if (strcmp(argv[0], "ver") == 0) {
    asoc_logf("FW %u.%u.%u\n", ASOC_FW_VERSION_MAJOR, ASOC_FW_VERSION_MINOR, ASOC_FW_VERSION_PATCH);
    return ASOC_OK;
  }

  if (strcmp(argv[0], "fpga.rd") == 0 && argc == 2) {
    int ok = 0;
    uint32_t off = parse_u32(argv[1], &ok);
    if (!ok) return ASOC_EINVAL;
    uint32_t v = fpga_ctrl_read32(&g_fpga, (fpga_reg_off_t)off);
    asoc_logf("0x%08lx\n", (unsigned long)v);
    return ASOC_OK;
  }

  if (strcmp(argv[0], "fpga.wr") == 0 && argc == 3) {
    int ok1 = 0, ok2 = 0;
    uint32_t off = parse_u32(argv[1], &ok1);
    uint32_t val = parse_u32(argv[2], &ok2);
    if (!ok1 || !ok2) return ASOC_EINVAL;
    fpga_ctrl_write32(&g_fpga, (fpga_reg_off_t)off, val);
    asoc_logf("OK\n");
    return ASOC_OK;
  }

  if (strcmp(argv[0], "run") == 0 && argc == 2) {
    int ok = 0;
    uint32_t en = parse_u32(argv[1], &ok);
    if (!ok) return ASOC_EINVAL;
    fpga_ctrl_set_run(&g_fpga, en != 0);
    asoc_logf("OK\n");
    return ASOC_OK;
  }

  if (strcmp(argv[0], "asic.wr") == 0 && argc == 3) {
    int ok1 = 0, ok2 = 0;
    uint32_t addr = parse_u32(argv[1], &ok1);
    uint32_t val  = parse_u32(argv[2], &ok2);
    if (!ok1 || !ok2) return ASOC_EINVAL;
    asoc_status_t st = asoc_asic_write_u32(&g_asic, (uint16_t)addr, val);
    asoc_logf("%s\n", asoc_status_str(st));
    return st;
  }

  if (strcmp(argv[0], "asic.rd") == 0 && argc == 2) {
    int ok = 0;
    uint32_t addr = parse_u32(argv[1], &ok);
    if (!ok) return ASOC_EINVAL;
    uint32_t val = 0;
    asoc_status_t st = asoc_asic_read_u32(&g_asic, (uint16_t)addr, &val);
    if (st == ASOC_OK) asoc_logf("0x%08lx\n", (unsigned long)val);
    else asoc_logf("%s\n", asoc_status_str(st));
    return st;
  }

  asoc_logf("ERR: unknown cmd\n");
  return ASOC_EINVAL;
}

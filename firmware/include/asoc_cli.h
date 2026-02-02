#pragma once
#include <stddef.h>
#include <stdint.h>
#include "asoc_error.h"

typedef struct {
  char line[128];
  size_t len;
} asoc_cli_t;

void asoc_cli_init(asoc_cli_t *cli);

/* Feed one byte; returns true if a full line is ready. */
int asoc_cli_feed(asoc_cli_t *cli, uint8_t b);

/* Process ready line. */
asoc_status_t asoc_cli_process(const char *line);

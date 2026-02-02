#include "asoc_log.h"
#include "platform/platform.h"
#include <stdarg.h>
#include <stdio.h>

void asoc_logf(const char *fmt, ...) {
  char buf[256];
  va_list ap;
  va_start(ap, fmt);
  int n = vsnprintf(buf, sizeof(buf), fmt, ap);
  va_end(ap);

  if (n <= 0) return;
  if ((size_t)n >= sizeof(buf)) n = (int)sizeof(buf) - 1;
  platform_uart_write_n(buf, (size_t)n);
}

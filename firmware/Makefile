CC ?= gcc
CFLAGS ?= -std=c11 -O2 -Wall -Wextra -Werror
INCLUDES = -I. -Iinclude

SRCS =   src/main.c   src/fpga_ctrl.c   src/acq_manager.c   src/asoc_packets.c   src/utils/asoc_log.c   src/utils/crc32.c   src/utils/ringbuf.c   src/asoc/asoc_asic.c   src/asoc/asoc_bus_spi.c   src/protocol/asoc_cli.c   src/cfd/cfd.c   platform/platform_common.c

BUILD_DIR = build
TARGET = $(BUILD_DIR)/fw_mock

all: $(TARGET)

$(TARGET): $(SRCS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(INCLUDES) $(SRCS) -o $(TARGET)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean

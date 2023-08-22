BUILD_DIR   		:= build
BUILD_GEN_DIR 		:= $(BUILD_DIR)/gen
BUILD_GEN_OBJ_DIR 	:= $(BUILD_GEN_DIR)/obj

OBJ_GEN     := $(wildcard $(BUILD_GEN_OBJ_DIR)/*.o)
LINK_SCRIPT := wotl.ld
TARGET 		:= build/bin/BOOT.elf

LD := mips-elf-ld

.PHONY: all
all: $(TARGET)

$(TARGET): $(OBJ_GEN)
	$(LD) -EL -mips32 -T $(LINK_SCRIPT) -o $@ $^

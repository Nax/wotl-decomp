BUILD_DIR   		:= build
BUILD_OBJ_DIR 		:= $(BUILD_DIR)/obj
BUILD_GEN_DIR 		:= $(BUILD_DIR)/gen
BUILD_GEN_OBJ_DIR 	:= $(BUILD_GEN_DIR)/obj

rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

DEPS        := $(call rwildcard,build,*.d)
SRC         := $(call rwildcard,src/wotl,*.c)
OBJ_SRC     := $(patsubst src/wotl/%,$(BUILD_OBJ_DIR)/%.o,$(SRC))
OBJ_GEN     := $(wildcard $(BUILD_GEN_OBJ_DIR)/*.o)
OBJ 	   	:= $(OBJ_SRC) $(OBJ_GEN)
LINK_SCRIPT := $(BUILD_GEN_DIR)/wotl.ld
TARGET 		:= build/bin/BOOT.elf

LD 			:= mips-elf-ld
OBJCOPY 	:= mips-elf-objcopy

.PHONY: all
all: $(TARGET)

-include $(DEPS)

$(TARGET): $(OBJ) $(LINK_SCRIPT)
	$(LD) -EL -mips32 -zmax-page-size=4 -T $(LINK_SCRIPT) -o $@ $(OBJ)

$(BUILD_OBJ_DIR)/%.c.o: src/wotl/%.c
	@mkdir -p $(dir $@)
	mwccpsp.exe -gccinc -Iinclude -c -O3 -o $@ -gccdep -MD $<
	$(OBJCOPY) $@ --set-section-alignment .text=64 --remove-section .comment --remove-section .mwcats

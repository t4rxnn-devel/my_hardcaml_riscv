# ==============================================================================
# Project: My HardCaml RISC-V Core
# Automation & Toolchain Makefile
# ==============================================================================

# Toolchain Binaries
CC      = riscv64-unknown-elf-gcc
AS      = riscv64-unknown-elf-as
LD      = riscv64-unknown-elf-ld
OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump
SIZE    = riscv64-unknown-elf-size

# Compilation & Linker Flags
CFLAGS  = -march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -fno-builtin
LDFLAGS = -T sw/linker.ld -nostdlib

# Source Files Specification
ASM_SRCS = sw/crt0.s sw/stress_test.s
C_SRCS   = sw/main.c

# Target Artifacts
FIRMWARE_ELF  = sw/firmware.elf
FIRMWARE_BIN  = sw/firmware.bin
FIRMWARE_HEX  = sw/firmware.hex
FIRMWARE_ASM  = sw/firmware.dump
HARDWARE_V    = rv32i_simple.v

.PHONY: all clean build sw test help info disassemble size-check

# Default Target Action
all: build sw_bin info
	@echo "[SUCCESS] Complete hardware-software build workflow successfully executed."

# Help Target Description
help:
	@echo "======================================================================"
	@echo "Available Makefile targets for my_hardcaml_riscv:"
	@echo "  make build       - Compiles HardCaml design and generates Verilog netlist"
	@echo "  make sw_bin      - Compiles assembly and C sources into firmware binaries"
	@echo "  make test        - Executes native OCaml property/cyclesim testbenches"
	@echo "  make disassemble - Generates annotated assembly dump for debugging"
	@echo "  make size-check  - Displays firmware section memory footprint sizes"
	@echo "  make clean       - Purges build artifacts, netlists, and compiled objects"
	@echo "======================================================================"

# ==============================================================================
# Hardware Build Rules (OCaml / HardCaml)
# ==============================================================================

build: $(HARDWARE_V)
	@echo "[INFO] HardCaml RTL target successfully verified and built via dune."

$(HARDWARE_V): dune top.ml alu.ml control.ml datapath.ml regfile.ml fifo.ml hazard.ml pipeline_regs.ml
	@echo "[INFO] Invoking dune to compile top.exe and emit structural Verilog..."
	dune build top.exe
	./_build/default/top.exe > $(HARDWARE_V)
	@echo "[INFO] Generated structural netlist target -> $(HARDWARE_V)"

# ==============================================================================
# Software Toolchain & Firmware Compilation Rules
# ==============================================================================

sw_bin: $(FIRMWARE_HEX) $(FIRMWARE_BIN)
	@echo "[INFO] RISC-V bare-metal toolchain successfully processed firmware images."

$(FIRMWARE_ELF): $(ASM_SRCS) $(C_SRCS) sw/linker.ld
	@echo "[INFO] Compiling and linking assembly and C bare-metal code..."
	$(CC) $(CFLAGS) $(LDFLAGS) $(ASM_SRCS) $(C_SRCS) -o $(FIRMWARE_ELF)

$(FIRMWARE_BIN): $(FIRMWARE_ELF)
	@echo "[INFO] Extracting raw binary format..."
	$(OBJCOPY) -O binary $(FIRMWARE_ELF) $(FIRMWARE_BIN)

$(FIRMWARE_HEX): $(FIRMWARE_ELF)
	@echo "[INFO] Extracting Intel HEX memory-map format..."
	$(OBJCOPY) -O ihex $(FIRMWARE_ELF) $(FIRMWARE_HEX)

# ==============================================================================
# Verification, Testing, & Diagnostics
# ==============================================================================

test:
	@echo "[INFO] Launching programmatic native OCaml Cyclesim test suites..."
	dune exec ./test/test_alu.exe
	dune exec ./test/test_datapath.exe
	@echo "[INFO] All native test suites passed successfully."

disassemble: $(FIRMWARE_ELF)
	@echo "[INFO] Dumping annotated instruction disassembly..."
	$(OBJDUMP) -d $(FIRMWARE_ELF) > $(FIRMWARE_ASM)
	@echo "[INFO] Disassembly dump saved to $(FIRMWARE_ASM)"

size-check: $(FIRMWARE_ELF)
	@echo "[INFO] Checking firmware memory layout size dimensions:"
	$(SIZE) $(FIRMWARE_ELF)

info:
	@echo "[INFO] Repository state summary:"
	@echo "  - RTL Netlist: $(HARDWARE_V)"
	@echo "  - Firmware Image: $(FIRMWARE_HEX)"
	@echo "  - Architecture: RV32I 5-Stage Pipelined + HFT MMIO FIFO"

# ==============================================================================
# Housekeeping & Cleanup Rules
# ==============================================================================

clean:
	@echo "[INFO] Cleaning up build outputs, logs, and artifacts..."
	dune clean
	rm -f $(HARDWARE_V)
	rm -f sw/*.elf sw/*.bin sw/*.hex sw/*.dump
	@echo "[INFO] Cleanup complete."

# Toolchain definition
CC = riscv64-unknown-elf-gcc
AS = riscv64-unknown-elf-as
LD = riscv64-unknown-elf-ld
OBJCOPY = riscv64-unknown-elf-objcopy

CFLAGS = -march=rv32i -mabi=ilp32 -O0 -ffreestanding -nostdlib
LDFLAGS = -T sw/linker.ld -nostdlib

.PHONY: all clean build sw

all: rv32i_simple.v sw_bin

build:
	dune build @all

rv32i_simple.v:
	dune build top.exe
	./_build/default/top.exe > rv32i_simple.v

sw_bin:
	$(CC) $(CFLAGS) $(LDFLAGS) sw/crt0.s sw/main.c -o sw/firmware.elf
	$(OBJCOPY) -O binary sw/firmware.elf sw/firmware.bin
	$(OBJCOPY) -O ihex sw/firmware.elf sw/firmware.hex

clean:
	dune clean
	rm -f rv32i_simple.v
	rm -f sw/*.elf sw/*.bin sw/*.hex

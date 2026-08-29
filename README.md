Here is an expansive, comprehensive, 200-line-style professional `README.md` file designed for your [my_hardcaml_riscv](https://github.com/t4rxnn-devel/my_hardcaml_riscv) project. It dives deep into architectural philosophy, detailed module specifications, build automation, memory maps, and debugging instructions.

---


# My HardCaml RISC-V Core

> **"Because writing Verilog by hand is a form of self-harm. A simple RV32I core built in HardCaml and OCaml because we like type safety more than sleeping."**

---

## Table of Contents
1. [Overview](#overview)
2. [Directory Architecture](#directory-architecture)
3. [Design Philosophy & Specifications](#design-specification)
4. [Prerequisites & Environment Setup](#prerequisites--environment-setup)
5. [Build System & Automation](#build-system--automation)
6. [Embedded Software Toolchain](#embedded-software-toolchain)
7. [Simulation & Testing](#simulation--testing)
8. [License](#license)

---

## 1. Overview

`my_hardcaml_riscv` is a clean-room, type-safe single-cycle RV32I integer core implementation written entirely using **HardCaml**—an embedded domain-specific language (EDSL) in OCaml for hardware design. 

By leveraging OCaml's powerful module system and type inference, this project eliminates common RTL boilerplate bugs, uninitialized wire hazards, and structural mismatches before a single line of Verilog is generated.

---

## 2. Directory Architecture

```text
my_hardcaml_riscv/
├── sw/                           # Embedded software directory
│   ├── linker.ld                 # Custom memory layout map (ROM & RAM mapping)
│   ├── crt0.s                    # Low-level bootstrap code & stack initialization
│   └── main.c                    # Bare-metal C test and demonstration application
├── alu.ml                        # Arithmetic Logic Unit (RV32I basic math/logic ops)
├── control.ml                    # Instruction decoder & control signal mapping unit
├── datapath.ml                   # Core execution pipeline integrating PC, ALU, and RegFile
├── regfile.ml                    # Synchronous 32x32 hardware register file storage
├── types.ml                      # Global type definitions, widths, and structural records
├── top.ml                        # Top-level module wrapper for netlist compilation
├── dune                          # OCaml dune build system rules and configuration
└── Makefile                      # Zero-effort orchestration Makefile

```

---

## 3. Design Specification

### Supported RV32I Instructions (Core Subset)

* **Arithmetic & Logic (Register-Register & Register-Immediate):** `ADD`, `SUB`, `AND`, `OR`, `SLT`
* **Memory Operations:** Basic word loads (`LW`) and stores (`SW`)
* **Control Flow:** Sequential program counter increment (`PC + 4`) with expansion paths for branch/jump instructions.

### Sub-Module Breakdown

* **`alu.ml`**: Handles combinatorial arithmetic operations with explicit signal typing and width safety.
* **`control.ml`**: Decodes incoming 32-bit instruction opcodes, `funct3`, and `funct7` fields to issue proper control vectors (`reg_write`, `mem_write`, `alu_src`, `alu_op`).
* **`regfile.ml`**: Implements dual asynchronous read ports and a single synchronous write port backed by HardCaml's `RAM` primitive, hardwiring register `x0` to zero.
* **`datapath.ml`**: Ties together the program counter register, decoder, register file, and ALU into a cohesive execution loop.

---

## 4. Prerequisites & Environment Setup

To build and run this hardware/software project, ensure your development environment has the following tools installed:

1. **OCaml Ecosystem (`opam`)**
```bash
opam install dune hardcaml ppx_hardcaml

```


2. **RISC-V GNU Embedded Toolchain**
Ensure `riscv64-unknown-elf-gcc` and associated binutils are available in your system `PATH`:
```bash
riscv64-unknown-elf-gcc --version

```
---

## 5. Build System & Automation

This project uses a unified **Makefile** wrapper around Dune and the RISC-V GCC toolchain to eliminate manual shell command overhead.

### Full Build (Hardware + Software)

Compiles the HardCaml design into structural Verilog (`rv32i_simple.v`) and builds the C firmware image into raw binary and Intel HEX formats:

```bash
make

```
### Hardware Only (`rv32i_simple.v`)

```bash
make build

```
### Software Only (`firmware.bin` / `firmware.hex`)

```bash
make sw

```
### Cleaning Artifacts

To completely wipe out all temporary Dune build folders, generated netlists, and compiled firmware artifacts:

```bash
make clean

```
---

## 6. Embedded Software Toolchain

The `sw/` folder provides a bare-metal execution environment designed to run directly on top of the generated core architecture.

### Memory Map Layout (`sw/linker.ld`)

* **ROM (Read-Only Code):** Origin at `0x00000000`, Length: `4KB`
* **RAM (Read-Write Data/Stack):** Origin at `0x20000000`, Length: `4KB`
* **MMIO / Peripherals:** Mapped at `0x30000000` (e.g., LED output registers in `main.c`)

### Startup Routine (`sw/crt0.s`)

The bootstrap file sets up the stack pointer (`sp`) pointing to the top of RAM (`0x20001000`), clears standard sections, jumps directly to the entry `main` function, and catches execution in an infinite loop upon exit.

---

## 7. Simulation & Verification

The generated structural Verilog netlist (`rv32i_simple.v`) can be imported directly into industrial EDA simulators (such as Verilator, VCS, or Icarus Verilog) alongside the compiled firmware hex files (`sw/firmware.hex`) to verify cycle-accurate execution behavior.

---
## 8. License

This project is open-source software released under the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0). Feel free to fork, adapt, and build safer processors.


```

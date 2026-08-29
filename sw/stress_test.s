.global _start
.section .text

# Memory-Mapped I/O (MMIO) and Data Constants
.equ FIFO_MMIO_ADDR, 0x30000000
.equ STACK_INIT,     0x20001000

_start:
    # 1. Initialize Stack Pointer to top of RAM
    li sp, STACK_INIT

    # 2. Test Hazard Forwarding & ALU Operations
    # Back-to-back dependencies to exercise the hazard and forwarding logic units
    li   t0, 10             # t0 = 10
    li   t1, 20             # t1 = 20
    add  t2, t0, t1         # t2 = 30 (Forwarding from EX/MEM or MEM/WB required)
    sub  t3, t1, t0         # t3 = 10
    addi t4, t2, 5          # t4 = 35

    # 3. Test Data Memory & Store/Load Operations
    la   a0, data_buffer    # Load data buffer base address
    sw   t4, 0(a0)          # Store 35 into RAM data buffer
    lw   t5, 0(a0)          # Load back into t5 (triggers load-use hazard stall check)

    # 4. Stream Data into the Low-Latency HFT Circular FIFO Peripheral (MMIO)
    li   s0, FIFO_MMIO_ADDR # Load MMIO base address of circular FIFO
    li   s1, 0x41434241     # Stream packet header "ACBA"
    li   s2, 0xDEADBEEF     # Stream market data payload payload
    li   s3, 5              # Loop counter for streaming burst

fifo_stream_loop:
    sw   s1, 0(s0)          # Write packet header into FIFO input register
    sw   s2, 0(s0)          # Write market payload into FIFO input register
    addi s3, s3, -1         # Decrement loop counter
    bnez s3, fifo_stream_loop # Branch back if more packets remain

    # 5. Control Flow & Branching Stress Test
    li   x5, 0
    li   x6, 10
branch_target:
    addi x5, x5, 1
    blt  x5, x6, branch_target # Loop branch test to stress pipeline flush/control hazards

    # 6. Infinite Hang / Exit Loop on Completion
inf_loop:
    j    inf_loop

.section .data
.align 4
data_buffer:
    .word 0x00000000
    .word 0x00000000

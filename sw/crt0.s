.section .text.startup
.globl _start

_start:
    # Initialize Stack Pointer to top of RAM (0x20001000)
    li sp, 0x20001000

    # Clear BSS or handle initialization if necessary
    # Jump to main C program
    call main

    # Infinite loop upon exit
_exit:
    j _exit

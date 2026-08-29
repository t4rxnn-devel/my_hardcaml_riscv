ENTRY(_start)

MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 4K
}

SECTIONS
{
    .text : {
        *(.text.startup)
        *(.text)
    } > ROM

    .data : {
        *(.data)
        *(.sdata)
    } > RAM

    .bss : {
        *(.bss)
        *(.sbss)
    } > RAM
}

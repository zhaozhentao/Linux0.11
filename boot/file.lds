SECTIONS {
    . = 0x30004000;
    .text          :   { *(.text) }
    .rodata ALIGN(4) : {*(.rodata)}
    .data ALIGN(4) : { *(.data) }
    .bss ALIGN(4)  : { *(.bss)  *(COMMON) }
}

@ interrupt.s    (C) 2023 zhaozhentao
@ 中断向量表

.global _start

_start:
  b   reset
  bl  _undefined_instruction
  bl  _software_interrupt
  bl  _prefetch_abort
  bl  _data_abort
  bl  _not_used
  bl  _irq
  bl  _fiq

reset:

_undefined_instruction:

_software_interrupt:

_prefetch_abort:

_data_abort:

_not_used:

_irq:

_fiq:



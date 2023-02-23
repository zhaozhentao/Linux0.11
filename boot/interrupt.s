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

print_booting_msg:
  ldr  r0, =0x50000010        @ UTRSTAT0 寄存器
  ldr  r1, =0x50000020        @ UTXH0 发送数据寄存器

  adrl r2, msg2               @ 字符串起始地址
  add  r3, r2, $27            @ 字符串长度包括换行
1:
  ldr  r4, [r0]               @ 读取 r0 指向的地址,即读取 UTRSTAT0 寄存器
  tst  r4, $0x4               @ 检查是否发送完成
  beq  1b                     @ 未发送完成继续检查

  ldrb r5, [r2], $0x1         @ 读取一个 byte 到 r5，r2 指向下一个 byte
  strb r5, [r1]               @ 向 UTXH0 寄存器写入一个 byte
  cmp  r2, r3                 @ 看看 r2 地址是否已经指向 r3
  bne  1b
  mov  pc, lr                 @ 返回

msg2:
  .ascii "Now we are in setup ..."
  .byte 13, 10, 13, 10

@ setup.s  (c) 2023 zhaozhentao

.global _start
_start:
  bl  print_booting_msg
  bl  mov_irq_table           @ 将中断模块复制到 0 地址，覆盖原来的 bootsect 模块
  bl  mov_system              @ 将 system (包含 head ) 模块搬运到 SDRAM 起始地址
  ldr pc, SDRAM_BASE          @ 跳转到 head 模块

loop:
  b loop

mov_irq_table:                @ 先设置好要复制的源和目的地
  ldr  r1, INTERRUPT          @ 从 0x30090400 地址开始复制
  mov  r2, $0x0               @ 将 interrupt 模块移动到这个位置执行
  add  r3, r1, $0x200         @ 使 r3 指向 INTERRUPT 后 512 byte 地址
  b    do_move                @ 开始复制

mov_system:
  ldr  r1, HEAD               @ 从 0x30090600 地址开始复制
  ldr  r2, SDRAM_BASE         @ 将 system 模块移动到这个位置执行
  add  r3, r1, $0x200         @ 使 r3 指向 HEAD 后 512 byte 地址
  b    do_move                @ 开始复制

do_move:
1:
  ldr  r4, [r1], $4           @ 将 r1 指向的地址数据读到 r4, r1 指向下一个地址
  str  r4, [r2], $4           @ 将 r4 里面的数据复制到 r2 指向的地址，然后 r2 指向下一个地址
  cmp  r1, r3                 @ 检查复制到最后地址没
  bne  1b                     @ 未复制到最后跳转到 1:
  mov  pc, lr                 @ 返回

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

SDRAM_BASE:
  .word 0x30000000            @ SDRAM 起始地址，setup 模块执行完后，system 模块起始地址就是 SDRAM_BASE
INTERRUPT:
  .word 0x30090400            @ interrupt 模块被 bootsect 移动后的地址
HEAD:
  .word 0x30090600            @ head/system 模块被 bootsect 移动后的地址

msg2:
  .ascii "Now we are in setup ..."
  .byte 13, 10, 13, 10


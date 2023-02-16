@ bootsect.s    (C) 2023 zhaozhentao

.equ MEM_CTL_BASE, 0x48000000

.global _start

_start:
  bl disable_watch_dog     @ 关闭看门狗
  bl memsetup              @ 启用外部 SDRAM

disable_watch_dog:
  ldr  r0, WATCHDOG        @ r0 存入 WATCHDOG 寄存器地址, 也可以直接使用 ldr r0, =0x56000010, 让编译器为这个立即数分配存放地址
  mov  r1, #0
  str  r1, [r0]            @ 向 r0 所指向地址写入 r1 保存的数据，即向地址 0x56000010 写入 0，禁止 WATCHDOG
  mov  pc, lr              @ 在执行 bl 指令时，cpu 会自动将下一条指令的地址 (当前 pc + 4) 存入 lr 寄存器，通过 lr 寄存器返回 
  
memsetup:
  mov  r1, #MEM_CTL_BASE   @ 存储控制器的13个寄存器的开始地址
  adrl r2, mem_cfg_val
  mov  pc, lr

WATCHDOG:
  .word 0x56000010

.align 4
mem_cfg_val:
  @ 存储控制器13个寄存器的设置值
  .long 0x22011110 @ BWSCON
  .long 0x00000700 @ BANKCON0
  .long 0x00000700 @ BANKCON1
  .long 0x00000700 @ BANKCON2
  .long 0x00000700 @ BANKCON3
  .long 0x00000700 @ BANKCON4
  .long 0x00000700 @ BANKCON5
  .long 0x00018005 @ BANKCON6
  .long 0x00018005 @ BANKCON7
  .long 0x008C07A3 @ REFRESH
  .long 0x000000B1 @ BANKSIZE
  .long 0x00000030 @ MRSRB6
  .long 0x00000030 @ MRSRB7

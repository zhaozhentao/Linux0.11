@ bootsect.s    (C) 2023 zhaozhentao

.equ MEM_CTL_BASE, 0x48000000
.equ SDRAM_BASE,   0x30000000

.global _start

_start:
  bl  disable_watch_dog       @ 关闭看门狗
  bl  clock_init              @ 设置MPLL，改变FCLK、HCLK、PCLK
  bl  memsetup                @ 启用外部 SDRAM
  bl  uart0_init              @ 初始化串口 0
  bl  copy_to_sdram           @ 将代码复制到 SDRAM 中
  ldr pc, =on_sdram           @ 跳转到 SDRAM 中运行，因为 _start 链接地址为 0x30000000

on_sdram:
  b on_sdram

disable_watch_dog:
  ldr  r0, WATCHDOG           @ r0 存入 WATCHDOG 寄存器地址, 也可以直接使用 ldr r0, =0x56000010, 让编译器为这个立即数分配存放地址
  mov  r1, #0
  str  r1, [r0]               @ 向 r0 所指向地址写入 r1 保存的数据，即向地址 0x56000010 写入 0，禁止 WATCHDOG
  mov  pc, lr                 @ 在执行 bl 指令时，CPU 会自动将下一条指令的地址 (当前 pc + 4) 存入 lr 寄存器，通过 lr 寄存器返回 
  
memsetup:
  mov  r1, #MEM_CTL_BASE      @ 存储控制器的13个寄存器的开始地址
  adrl r2, mem_cfg_val
  add  r3, r1, #52            @ 13 * 4, MEM_CTL_BASE 接着的第 13 个寄存器地址
1:
  ldr  r4, [r2], #4           @ 读取 r2 指向的地址的值，然后 r2 加 4，指向下一个值
  str  r4, [r1], #4           @ 将 r4 的值设置到 r1 指向的地址，然后 r1 加4，指向下一个寄存器
  cmp  r1, r3                 @ 比较一下看看 r1 是否已经指向最后一个需要被设置寄存器，
  bne  1b                     @ 上面的比较不成立的话继续 1: ,bne 1b 指的是 backward，倒退寻找标号为 1 的地方并跳转
  mov  pc, lr                 @ 返回

copy_to_sdram:
  mov  r1, #0                 @ 从 0 地址开始 
  ldr  r2, =SDRAM_BASE        @ SDRAM 所在位置
  mov  r3, #4*1024            @ 4k 大小
1:
  ldr  r4, [r1], #4           @ 将 r1 指向的地址数据读到 r4, r1 指向下一个地址
  str  r4, [r2], #4           @ 将 r4 里面的数据复制到 r2 指向的地址，然后 r2 指向下一个地址
  cmp  r1, r3                 @ 检查复制到最后地址没
  bne  1b                     @ 未复制到最后跳转到 1:
  mov  pc, lr                 @ 返回

clock_init:
  ldr  r0, =0x4c000014        @ CLKDIVN 寄存器
  mov  r1, #0x03              @ FCLK:HCLK:PCLK=1:2:4, HDIVN=1,PDIVN=1
  str  r1, [r0]

                              @ 如果 HDIVN 非0，CPU的总线模式应该从“fast bus mode”变为“asynchronous bus mode”
  mrc  p15, 0, r1, c1, c0, 0  @ 读出控制寄存器
  orr  r1, r1, #0xc0000000    @ 设置为“asynchronous bus mode
  mcr  p15, 0, r1, c1, c0, 0  @ 写入控制寄存器

  ldr  r0, =0x4c000004        @ MPLLCON 寄存器
  ldr  r1, =376850            
  str  r1, [r0]               @ 现在，FCLK=200MHz,HCLK=100MHz,PCLK=50MHz

  mov  pc, lr                 @ 返回

uart0_init:
  ldr  r0, =0x56000070        @ GPHCON 寄存器
  mov  r1, #0xa0              @ GPH2, GPH3 用作TXD0, RXD0
  str  r1, [r0]
  ldr  r0, =0x56000078        @ GPHUP 寄存器
  mov  r1, #0x0c              @ GPH2, GPH3 内部上拉
  str  r1, [r0]
  ldr  r0, =0x50000000        @ ULCON0 寄存器
  mov  r1, #0x03              @ 8N1 (8 个数据位，无较验，1 个停止位)
  str  r1, [r0]
  ldr  r0, =0x50000004        @ UCON0 寄存器
  mov  r1, #0x05              @ 查询方式，UART时钟源为PCLK
  str  r1, [r0]
  ldr  r0, =0x50000008        @ UFCON0 寄存器
  mov  r1, #0x0               @ 不使用FIFO
  str  r1, [r0]
  ldr  r0, =0x5000000c        @ UMCON0 寄存器
  mov  r1, #0x0               @ 不使用流控
  str  r1, [r0]
  ldr  r0, =0x50000028        @ UBRDIV0 寄存器
  mov  r1, #26                @ 波特率为115200
  str  r1, [r0]
  mov  pc, lr                 @ 返回

print_msg:
  ldr  r0, =0x50000010        @ UTRSTAT0 寄存器
1:
  ldr  r1, r0                 @ 读取 r0 指向的地址,即读取 UTRSTAT0 寄存器
  tst  r1, #4
  beq  1b
  mov  pc, lr                 @ 返回

WATCHDOG:
  .word 0x56000010

.align 4
mem_cfg_val:                  @ 存储控制器13个寄存器的设置值
  .long 0x22011110            @ BWSCON
  .long 0x00000700            @ BANKCON0
  .long 0x00000700            @ BANKCON1
  .long 0x00000700            @ BANKCON2
  .long 0x00000700            @ BANKCON3
  .long 0x00000700            @ BANKCON4
  .long 0x00000700            @ BANKCON5
  .long 0x00018005            @ BANKCON6
  .long 0x00018005            @ BANKCON7
  .long 0x008C07A3            @ REFRESH
  .long 0x000000B1            @ BANKSIZE
  .long 0x00000030            @ MRSRB6
  .long 0x00000030            @ MRSRB7

MSG:
  .ascii "IceCityOS is booting ..."

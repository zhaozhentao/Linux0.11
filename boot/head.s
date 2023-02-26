@ head.s  (c) 2023 zhaozhentao

.equ MMU_SECDESC,            3090
.equ MMU_SECDESC_WB,         3102
.equ SRAM_PHYSICS_BASE,      0x0
.equ SRAM_VIRTUAL_BASE,      0x0
.equ SDRAM_PHYSICS_BASE,     0x30000000
.equ SDRAM_VIRTUAL_BASE,     0x30000000
.equ GPIO_PHYSICS_BASE,      0x56000000
.equ GPIO_VIRTUAL_BASE,      0xA0000000

.extern stack_start

.global _start

_start:
  bl  setup_interrupt                                      @ 设置中断
  bl  create_page_table                                    @ 设置 MMU 映射
  bl  mmu_init                                             @ 开启 MMU

  ldr r0, =stack_start                                     @ 将变量 stack_start 地址存放到 r0
  ldr sp, [r0]                                             @ 读出 stack_start 指向的地址,赋值 sp，为跳转到 main 函数准备栈空间
loop:
  b   loop

setup_interrupt:                                           @ 初始化 GPIO 引脚为外部中断, GPIO 引脚用作外部中断时，默认为低电平触发、IRQ方式(不用设置INTMOD)
  mov r2, $0x800000
  mov r1, $0x56000000
  add r2, r2, $0x80
  mov r3, $0x22
  str r3, [r1, $0x50]
  mov r0, $0x4a000000
  str r2, [r1, $0x60]
  ldr r3, [r1, $164]
  bic r3, r3, $524288
  bic r3, r3, $2048
  str r3, [r1, $164]
  ldr r2, [r0, $12]
  bic r2, r2, $1
  str r2, [r0, $12]
  ldr r3, [r0, $8]
  bic r3, r3, $37
  str r3, [r0, $8]
  mov pc, lr                                              @ 返回

create_page_table:
  ldr  r0, MMU_TLB_BASE                                    @ 映射表基地址
/*
 * 为了开启 MMU 后仍然能够继续执行程序,将 0~1M 和 0x30000000 ~ 0x30100000 (SDRAM 开头的1M) 映射为原来的地址
 * 简化代码就是 MMU_TLB_BASE[virtal >> 20] = (physics >> 20) | MMU_SECDESC
 */
  adrl r1, mmu_table                                       @ r1 保存 mmu_table 起始地址
  add  r2, r0, $(4 * 4)                                    @ r2 保存 mmu_table 结束地址，结束地址 = 起始地址 + (4 * 4)

1:
  ldr  r3, [r1], $4                                        @ 读取 mmu_table 数组中第 n 个元素保存到 r3, 然后 r1 指向下一个元素，即读取映射设置
  ldr  r4, [r1], $4                                        @ 读取 mmu_table 中第 n + 1 元素, r1 继续指向下一个元素, 即 MMU_TLB_BASE 偏移值
  str  r3, [r0, r4]                                        @ 将 r3 的值写到 r0 + r4 处，即将映射设置配置到 MMU_TLB_BASE 对应的项
  cmp  r1, r2                                              @ 比较看看是否已经设置完 mmu_table 项
  bne  1b

  mov  pc, lr                                              @ 返回

mmu_init:
  mov  r0, $0
  mcr  p15, 0, r0, c7, c7, 0                               @ 使无效 ICaches 和 DCaches
  mcr  p15, 0, r0, c7, c10, 4                              @ drain write buffer on v4
  mcr  p15, 0, r0, c8, c7, 0                               @ 使无效指令、数据TLB
  ldr  r4, MMU_TLB_BASE                                    @ r4 = 页表基址
  mcr  p15, 0, r4, c2, c0, 0                               @ 设置页表基址寄存器

  mvn  r0, $0
  mcr  p15, 0, r0, c3, c0, 0

  mrc  p15, 0, r0, c1, c0, 0
  bic  r0, r0, $0x3000
  bic  r0, r0, $0x0087

  orr  r0, r0, $0x0002
  orr  r0, r0, $0x0004
  orr  r0, r0, $0x1000
  orr  r0, r0, $0x0001

  mcr  p15, 0, r0, c1, c0, 0

  mov  pc, lr                                              @ 返回

mmu_table:
  .word((SRAM_PHYSICS_BASE >> 20) | MMU_SECDESC_WB)        @ SDRAM 1M 映射设置
  .word(SRAM_VIRTUAL_BASE >> 20)                           @ SDRAM 1M 映射表项
  .word((SDRAM_PHYSICS_BASE >> 20) | MMU_SECDESC_WB)       @ 0x30000000 ~ 0x30100000 映射设置
  .word(SDRAM_VIRTUAL_BASE >> 20)                          @ 0x30000000 ~ 0x30100000 映射表项

GPFCON:                                                    @ GPFCON 寄存器
  .word 0x56000050
GPGCON:                                                    @ GPGCON 寄存器
  .word 0x56000060
EINTMASK:                                                  @ EINTMASK 寄存器
  .word 0x560000a4
MMU_TLB_BASE:
  .word 0x30000600

@ 这里是 head 模块编译后距离起点 0x1000 地址处
@.org 0x1000
@pg0:
@
@.org 0x2000
@pg1:
@
@.org 0x3000
@pg2:
@
@.org 0x4000
@pg3:
@
@.org 0x5000

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

.global _start, __vectors_start, __vectors_end, __stubs_start

_start:
  bl  setup_interrupt                                      @ 设置中断
  ldr r0, =stack_start                                     @ 将变量 stack_start 地址存放到 r0
  ldr sp, [r0]                                             @ 读出 stack_start 指向的地址,赋值 sp，为跳转到 main 函数准备栈空间

  bl  create_page_table                                    @ 设置 MMU 映射
  bl  mmu_init                                             @ 开启 MMU

  bl  main                                                 @ 跳转到 main

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

mmu_table:
  .word((SRAM_PHYSICS_BASE & 0xFFF00000) | MMU_SECDESC_WB) @ SDRAM 1M 映射设置
  .word(SRAM_VIRTUAL_BASE >> 20)                           @ SDRAM 1M 映射表项
  .word((SDRAM_PHYSICS_BASE & 0xFFF00000) | MMU_SECDESC_WB)@ 0x30000000 ~ 0x30100000 映射设置
  .word(SDRAM_VIRTUAL_BASE >> 20)                          @ 0x30000000 ~ 0x30100000 映射表项

GPFCON:                                                    @ GPFCON 寄存器
  .word 0x56000050
GPGCON:                                                    @ GPGCON 寄存器
  .word 0x56000060
EINTMASK:                                                  @ EINTMASK 寄存器
  .word 0x560000a4
MMU_TLB_BASE:
  .word 0x30000000

__und_invalid:

__und_usr:

.macro	vector_stub, name, mode, correction=0
.align	5

vector_\name:
  .if \correction
  sub  lr, lr, $\correction
  .endif

  @
  @ Save r0, lr_<exception> (parent PC) and spsr_<exception>
  @ (parent CPSR)
  @
  stmia sp, {r0, lr}                                    @ save r0, lr
  mrs  lr, spsr
  str  lr, [sp, $8]                                     @ save spsr

  @
  @ Prepare for SVC32 mode.  IRQs remain disabled.
  @
  mrs  r0, cpsr
  eor  r0, r0, $(\mode ^ SVC_MODE | PSR_ISETSTATE)
  msr  spsr_cxsf, r0

  @
  @ the branch table must immediately follow this code
  @
  and  lr, lr, $0x0f
  THUMB(adr r0, 1f)
  THUMB(ldr lr, [r0, lr, lsl $2])
  mov r0, sp
  ARM(ldr  lr, [pc, lr, lsl $2])
  movs  pc, lr                                           @ branch to handler in SVC mode
  ENDPROC(vector_\name)

  .align 2
  @ handler addresses follow this label
1:
  .endm

__stubs_start:
vector_stub und, UND_MODE
  .long  __und_usr                                        @ 0 (USR_26 / USR_32)
  .long  __und_invalid                                    @ 1 (FIQ_26 / FIQ_32)
  .align 5

__stubs_end:
    .equ stubs_offset, __vectors_start + 0x200 - __stubs_start

__vectors_start:
  ARM(swi SYS_ERROR0)
  THUMB(svc $0)
  THUMB(nop)
  W(b)  vector_und + stubs_offset

__vectors_end:

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

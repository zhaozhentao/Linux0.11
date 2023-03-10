@ head.s  (c) 2023 zhaozhentao

#include <mach/entry-macro.S>
#include <asm/unwind.h>

#include "entry-header.S"

.equ MMU_SECDESC,            3090
.equ MMU_SECDESC_WB,         3102
.equ SRAM_PHYSICS_BASE,      0x0
.equ SRAM_VIRTUAL_BASE,      0x0
.equ SDRAM_PHYSICS_BASE,     0x30000000
.equ SDRAM_VIRTUAL_BASE,     0x30000000
.equ GPIO_PHYSICS_BASE,      0x56000000
.equ GPIO_VIRTUAL_BASE,      0xA0000000

.extern stack_start

.global _start, __vectors_start, __vectors_end, __stubs_start, __divsi3

_start:
  bl  setup_interrupt                                      @ 设置中断
  ldr r0, =stack_start                                     @ 将变量 stack_start 地址存放到 r0
  ldr sp, [r0]                                             @ 读出 stack_start 指向的地址,赋值 sp，为跳转到 main 函数准备栈空间

  bl  create_page_table                                    @ 设置 MMU 映射
  bl  mmu_init                                             @ 开启 MMU

  msr cpsr_c, $0xdf                                        @ 进入系统模式
  ldr r0, =stack_start                                     @ 设置系统模式栈指针
  ldr sp, [r0]

  msr cpsr_c, $0x5f                                        @ 开启中断,自动进入系统模式

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

.LCcralign:
  .word  cr_alignment

__und_invalid:

ENDPROC(__und_invalid)

__und_svc:

ENDPROC(__und_svc)

/*
 * 从中断返回用户模式
 */
ENTRY(ret_from_exception)

ENDPROC(ret_from_exception)

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
/*
 * irq 中断分发
 */
vector_stub irq, IRQ_MODE, 4

/*
 * Data Abort 分发
 * 进入 Abort 模式, spsr = USR CPSR, lr = USR PC
 */
vector_stub dabt, ABT_MODE, 8

/*
 * Prefetch Abort 分发
 * 进入 Abort 模式, spsr = USR CPSR, lr = USR PC
 */
vector_stub pabt, ABT_MODE, 4

/** Undefined Instruction 未定义指令中断 **/
vector_stub und, UND_MODE

/** Linux 中没有使用 fiq 中断 **/
vector_fiq:
  disable_fiq
  subs  pc, lr, $4

/*=============================================================================
 * Address exception handler
 *-----------------------------------------------------------------------------
 * These aren't too critical.
 * (they're not supposed to happen, and won't happen in 32-bit data mode).
 */
vector_addrexcptn:
  b  vector_addrexcptn

  /*
   * We group all the following data together to optimise
   * for CPUs with separate I & D caches.
   */
  .align  5

.LCvswi:
  .word vector_swi

__stubs_end:
  .equ stubs_offset, __vectors_start + 0x200 - __stubs_start

__vectors_start:
  ARM(swi SYS_ERROR0)                                     @ 0xffff0000 reset 复位
  W(b)   vector_und + stubs_offset                        @ 0xffff0004 Undefined Instruction 未定义指令，这里跳转到经过 traps.c trap_init() 移动后的位置
  W(ldr) pc, .LCvswi + stubs_offset                       @ 0xffff0008 Software Interrupt，软件中断
  W(b)   vector_pabt + stubs_offset                       @ 0xffff000c Abort (prefetch)
  W(b)   vector_dabt + stubs_offset                       @ 0xffff0010 Abort (data)
  W(b)   vector_addrexcptn + stubs_offset                 @ 0xffff0014 Reserved 保留中断
  W(b)   vector_irq + stubs_offset                        @ 0xffff0018 irq 中断
  W(b)   vector_fiq + stubs_offset                        @ 0xffff001c fiq 快中断

__vectors_end:

cr_alignment:
  .space 4

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

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

.LCcralign:
  .word  cr_alignment

.macro  usr_entry
  UNWIND(.fnstart)                                         @ 实际上是空语句
  UNWIND(.cantunwind)                                      @ 实际上是空语句 don't unwind the user space
  sub  sp, sp, $S_FRAME_SIZE
  ARM(stmib sp, {r1 - r12})

  ldmia  r0, {r1 - r3}
  add r0, sp, $S_PC                                        @ here for interlock avoidance
  mov r4, $-1                                              @  ""  ""     ""        ""

  str r1, [sp]                                             @ save the "real" r0 copied
                                                           @ from the exception stack

  @ We are now ready to fill in the remaining blanks on the stack:
  @
  @  r2 - lr_<exception>, already fixed up for correct return/restart
  @  r3 - spsr_<exception>
  @  r4 - orig_r0 (see pt_regs definition in ptrace.h)
  @
  @ Also, separately save sp_usr and lr_usr
  @
  stmia  r0, {r2 - r4}
  ARM(stmdb  r0, {sp, lr}^)

  @
  @ Enable the alignment trap while in kernel mode
  @
  alignment_trap r0

  @
  @ Clear FP to mark the first stack frame
  @
  zero_fp

  asm_trace_hardirqs_off
.endm

__und_invalid:

ENDPROC(__und_invalid)

__und_svc:

ENDPROC(__und_svc)

__und_usr:
  usr_entry

  @ fall through to the emulation code, which returns using r9 if
  @ it has emulated the instruction, or the more conventional lr
  @ if we are to treat this as a real undefined instruction
  @
  @  r0 - instruction
  @
  adr    r9, BSYM(ret_from_exception)
  adr    lr, BSYM(__und_usr_unknown)
  tst    r3, #PSR_T_BIT                                 @ Thumb mode?
  itet   eq	                                            @ explicit IT needed for the 1f label
  subeq  r4, r2, $4                                     @ ARM instr at LR - 4
  subne  r4, r2, $2                                     @ Thumb instr at LR - 2
1:
  ldreqt r0, [r4]
  beq    call_fpe
  b	__und_usr_unknown
ENDPROC(__und_usr)

call_fpe:
  tst    r0, $0x08000000                                @ only CDP/CPRT/LDC/STC have bit 27
  tstne  r0, $0x04000000                                @ bit 26 set on both ARM and Thumb-2
  moveq  pc, lr
  get_thread_info r10                                   @ get current thread
  and    r8, r0, $0x00000f00                            @ mask out CP number
  THUMB(lsr	r8, r8, $8)
  mov	r7, $1
  add   r6, r10, $TI_USED_CP
  ARM(strb r7, [r6, r8, lsr $8])                        @ set appropriate used_cp[]
  THUMB(strb r7, [r6, r8])                              @ set appropriate used_cp[]
  ARM(add pc, pc, r8, lsr $6)
  THUMB(	lsl	r8, r8, $2		)
  THUMB(	add	pc, r8			)
  nop

  movw_pc	lr                                          @ CP#0
  W(b)	do_fpe                                          @ CP#1 (FPE)
  W(b)	do_fpe                                          @ CP#2 (FPE)
  movw_pc  lr                                           @ CP#3
  movw_pc  lr                                           @ CP#4
  movw_pc  lr                                           @ CP#5
  movw_pc  lr                                           @ CP#6
  movw_pc  lr                                           @ CP#7
  movw_pc  lr                                           @ CP#8
  movw_pc  lr                                           @ CP#9
  movw_pc  lr                                           @ CP#10 (VFP)
  movw_pc  lr                                           @ CP#11 (VFP)
  movw_pc  lr                                           @ CP#12
  movw_pc  lr                                           @ CP#13
  movw_pc  lr                                           @ CP#14 (Debug)
  movw_pc  lr                                           @ CP#15 (Control)

__und_usr_unknown:
  enable_irq
  mov r0, sp
  adr lr, BSYM(ret_from_exception)
  b   do_undefinstr
ENDPROC(__und_usr_unknown)

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
  .long  __und_usr                       @  0 (USR_26 / USR_32)
  .long  __und_invalid                   @  1 (FIQ_26 / FIQ_32)
  .long  __und_invalid                   @  2 (IRQ_26 / IRQ_32)
  .long  __und_svc                       @  3 (SVC_26 / SVC_32)
  .long  __und_invalid                   @  4
  .long  __und_invalid                   @  5
  .long  __und_invalid                   @  6
  .long  __und_invalid                   @  7
  .long  __und_invalid                   @  8
  .long  __und_invalid                   @  9
  .long  __und_invalid                   @  a
  .long  __und_invalid                   @  b
  .long  __und_invalid                   @  c
  .long  __und_invalid                   @  d
  .long  __und_invalid                   @  e
  .long  __und_invalid                   @  f
  .align 5

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
  ARM(swi SYS_ERROR0)                                     @ reset 复位
  W(b)   vector_und + stubs_offset                        @ Undefined Instruction 未定义指令，这里跳转到经过 traps.c trap_init() 移动后的位置
  W(ldr) pc, .LCvswi + stubs_offset                       @ Software Interrupt，软件中断
  W(b)   vector_pabt + stubs_offset                       @ Abort (prefetch)
  W(b)   vector_dabt + stubs_offset                       @ Abort (data)
  W(b)   vector_addrexcptn + stubs_offset                 @ Reserved 保留中断
  W(b)   vector_irq + stubs_offset                        @ irq 中断
  W(b)   vector_fiq + stubs_offset                        @ fiq 中断

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

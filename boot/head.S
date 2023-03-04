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
  msr cpsr_c, $0x5f                                       @ 开启中断
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

Ldiv0:
str	lr, [sp, #-8]!
bl	__div0
mov	r0, #0			@ About as wrong as it could be.
ldr	pc, [sp], #8


.macro ARM_DIV_BODY dividend, divisor, result, curbit
#if __LINUX_ARM_ARCH__ >= 5

	clz	\curbit, \divisor
	clz	\result, \dividend
	sub	\result, \curbit, \result
	mov	\curbit, #1
	mov	\divisor, \divisor, lsl \result
	mov	\curbit, \curbit, lsl \result
	mov	\result, #0
	
#else

	@ Initially shift the divisor left 3 bits if possible,
	@ set curbit accordingly.  This allows for curbit to be located
	@ at the left end of each 4 bit nibbles in the division loop
	@ to save one loop in most cases.
	tst	\divisor, #0xe0000000
	moveq	\divisor, \divisor, lsl #3
	moveq	\curbit, #8
	movne	\curbit, #1

	@ Unless the divisor is very big, shift it up in multiples of
	@ four bits, since this is the amount of unwinding in the main
	@ division loop.  Continue shifting until the divisor is 
	@ larger than the dividend.
1:	cmp	\divisor, #0x10000000
	cmplo	\divisor, \dividend
	movlo	\divisor, \divisor, lsl #4
	movlo	\curbit, \curbit, lsl #4
	blo	1b

	@ For very big divisors, we must shift it a bit at a time, or
	@ we will be in danger of overflowing.
1:	cmp	\divisor, #0x80000000
	cmplo	\divisor, \dividend
	movlo	\divisor, \divisor, lsl #1
	movlo	\curbit, \curbit, lsl #1
	blo	1b

	mov	\result, #0

#endif

	@ Division loop
1:	cmp	\dividend, \divisor
	subhs	\dividend, \dividend, \divisor
	orrhs	\result,   \result,   \curbit
	cmp	\dividend, \divisor,  lsr #1
	subhs	\dividend, \dividend, \divisor, lsr #1
	orrhs	\result,   \result,   \curbit,  lsr #1
	cmp	\dividend, \divisor,  lsr #2
	subhs	\dividend, \dividend, \divisor, lsr #2
	orrhs	\result,   \result,   \curbit,  lsr #2
	cmp	\dividend, \divisor,  lsr #3
	subhs	\dividend, \dividend, \divisor, lsr #3
	orrhs	\result,   \result,   \curbit,  lsr #3
	cmp	\dividend, #0			@ Early termination?
	movnes	\curbit,   \curbit,  lsr #4	@ No, any more bits to do?
	movne	\divisor,  \divisor, lsr #4
	bne	1b
.endm


.macro ARM_DIV2_ORDER divisor, order
#if __LINUX_ARM_ARCH__ >= 5
	clz	\order, \divisor
	rsb	\order, \order, #31
#else
	cmp	\divisor, #(1 << 16)
	movhs	\divisor, \divisor, lsr #16
	movhs	\order, #16
	movlo	\order, #0

	cmp	\divisor, #(1 << 8)
	movhs	\divisor, \divisor, lsr #8
	addhs	\order, \order, #8

	cmp	\divisor, #(1 << 4)
	movhs	\divisor, \divisor, lsr #4
	addhs	\order, \order, #4

	cmp	\divisor, #(1 << 2)
	addhi	\order, \order, #3
	addls	\order, \order, \divisor, lsr #1
#endif
.endm


ENTRY(__divsi3)
ENTRY(__aeabi_idiv)

	cmp	r1, #0
	eor	ip, r0, r1			@ save the sign of the result.
	beq	Ldiv0
	rsbmi	r1, r1, #0			@ loops below use unsigned.
	subs	r2, r1, #1			@ division by 1 or -1 ?
	beq	10f
	movs	r3, r0
	rsbmi	r3, r0, #0			@ positive dividend value
	cmp	r3, r1
	bls	11f
	tst	r1, r2				@ divisor is power of 2 ?
	beq	12f

	ARM_DIV_BODY r3, r1, r0, r2

	cmp	ip, #0
	rsbmi	r0, r0, #0
	mov	pc, lr

10:	teq	ip, r0				@ same sign ?
	rsbmi	r0, r0, #0
	mov	pc, lr

11:	movlo	r0, #0
	moveq	r0, ip, asr #31
	orreq	r0, r0, #1
	mov	pc, lr

12:	ARM_DIV2_ORDER r1, r2

	cmp	ip, #0
	mov	r0, r3, lsr r2
	rsbmi	r0, r0, #0
	mov	pc, lr

ENDPROC(__divsi3)
ENDPROC(__aeabi_idiv)


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

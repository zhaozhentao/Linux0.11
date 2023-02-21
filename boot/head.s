@ setup.s  (c) 2023 zhaozhentao

.equ MMU_SECDESC,            3090
.equ MMU_SECDESC_WB,         3102
.equ MMU_TLB_BASE,           0x30000600
.equ SRAM_PHYSICS_BASE,      0x0
.equ SRAM_VIRTUAL_BASE,      0x0
.equ GPIO_PHYSICS_BASE,      0x56000000
.equ GPIO_VIRTUAL_BASE,      0xA0000000

.global _pg_dir

_pg_dir:
start_up:
  bl create_page_table                                     @ 设置 MMU 映射

create_page_table:
  ldr  r0, =MMU_TLB_BASE                                   @ 映射表基地址
/*
 * 为了开启 mmu 后仍然能够继续执行程序,将 0~1M 和 0x30000000 ~ 0x30100000 (sdram 开头的1M) 映射为原来的地址
 * 
 */
  ldr  r1, =((SRAM_PHYSICS_BASE >> 20) | MMU_SECDESC_WB)   @ 虚拟地址 0 >> 20 ，段基地址
  str  r1, [r0, $(SRAM_VIRTUAL_BASE >> 20)]                @ 映射表第一个表项

  ldr  r1, =((GPIO_PHYSICS_BASE >> 20) | MMU_SECDESC)      @ 虚拟地址 0 >> 20 ，段基地址
  str  r1, [r0, $(GPIO_VIRTUAL_BASE >> 20)]                @ 根据虚拟地址段基地址偏移，寻找表项

  mov  pc, lr                                              @ 返回
  
mmu_table:
  .word((SRAM_PHYSICS_BASE >> 20) | MMU_SECDESC_WB)        @ SDRAM 1M 映射设置
  .word((SRAM_PHYSICS_BASE >> 20) | MMU_SECDESC_WB)        @ SDRAM 1M 映射表项
  .word((GPIO_PHYSICS_BASE >> 20) | MMU_SECDESC)           @ 0x30000000 ~ 0x30100000 映射设置
  .word(GPIO_VIRTUAL_BASE >> 20)                           @ 0x30000000 ~ 0x30100000 映射表项


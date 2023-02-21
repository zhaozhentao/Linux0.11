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

mmu_table:
  .word((SRAM_PHYSICS_BASE >> 20) | MMU_SECDESC_WB)        @ SDRAM 1M 映射设置
  .word(SRAM_VIRTUAL_BASE >> 20)                           @ SDRAM 1M 映射表项
  .word((GPIO_PHYSICS_BASE >> 20) | MMU_SECDESC)           @ 0x30000000 ~ 0x30100000 映射设置
  .word(GPIO_VIRTUAL_BASE >> 20)                           @ 0x30000000 ~ 0x30100000 映射表项

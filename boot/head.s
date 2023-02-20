@ setup.s  (c) 2023 zhaozhentao

.equ MMU_SECDESC,    3090
.equ MMU_SECDESC_WB, 3102
.equ MMU_TLB_BASE,   0x30000600

.global _pg_dir

_pg_dir:
start_up:
  bl create_page_table        @ 设置 MMU 映射

create_page_table:
  ldr  r0, =MMU_TLB_BASE      @ 映射表基地址
  mov  pc, lr                 @ 返回
  

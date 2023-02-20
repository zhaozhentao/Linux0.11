@ setup.s  (c) 2023 zhaozhentao

.equ MMU_SECDESC, 3090
.equ MMU_SECDESC, 3102

.global _pg_dir

_pg_dir:
start_up:
  bl create_page_table        @ 设置 MMU 映射

create_page_table:
  ldr r1, $MMU_SECDESC
  mov pc, lr                  @ 返回

@ setup.s  (c) 2023 zhaozhentao

#define MMU_FULL_ACCESS     (3 << 10)

.global _pg_dir

_pg_dir:
start_up:
  bl create_page_table        @ 设置 MMU 映射

create_page_table:
  mov pc, lr                  @ 返回


# bootsect.s    (C) 2023 zhaozhentao

.global _start

_start:
  bl disable_watch_dog  # 关闭开门狗

disable_watch_dog:
  mov pc, lr            # 返回 
  

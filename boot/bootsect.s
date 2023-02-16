@ bootsect.s    (C) 2023 zhaozhentao

.global _start

_start:
  bl disable_watch_dog  @ 关闭看门狗

disable_watch_dog:
  ldr r0, =0x56000010   @ r0 存入 WATCHDOG 寄存器地址
  mov r1, #0
  str r1, [r0]          @ 向 r0 所指向地址写入 r1 保存的数据，即向地址 0x56000010 写入 0，禁止 WATCHDOG
  mov pc, lr            @ 返回 
  

@ bootsect.s    (C) 2023 zhaozhentao

.global _start

_start:
  bl disable_watch_dog  @ 关闭看门狗

disable_watch_dog:
  ldr r0, WATCHDOG      @ r0 存入 WATCHDOG 寄存器地址, 也可以直接使用 ldr r0, =0x56000010, 让编译器为这个立即数分配存放地址
  mov r1, #0
  str r1, [r0]          @ 向 r0 所指向地址写入 r1 保存的数据，即向地址 0x56000010 写入 0，禁止 WATCHDOG
  mov pc, lr            @ 在执行 bl 指令时，cpu 会自动将下一条指令的地址 (当前 pc + 4) 存入 lr 寄存器，通过 lr 寄存器返回 
  
WATCHDOG:
  .word 0x56000010


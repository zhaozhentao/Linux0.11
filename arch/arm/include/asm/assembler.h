.macro asm_trace_hardirqs_off
#if defined(CONFIG_TRACE_IRQFLAGS)
  这里不会被编译
  stmdb  sp!, {r0-r3, ip, lr}
  bl  trace_hardirqs_off
  ldmia  sp!, {r0-r3, ip, lr}
#endif
.endm


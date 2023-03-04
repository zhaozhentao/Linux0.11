#include <asm/ptrace.h>

.macro asm_trace_hardirqs_off
#if defined(CONFIG_TRACE_IRQFLAGS)
  这里不会被编译
  stmdb  sp!, {r0-r3, ip, lr}
  bl  trace_hardirqs_off
  ldmia  sp!, {r0-r3, ip, lr}
#endif
.endm

.macro asm_trace_hardirqs_on_cond, cond
.endm

.macro enable_irq_notrace
msr    cpsr_c, #SVC_MODE
.endm

.macro asm_trace_hardirqs_on
asm_trace_hardirqs_on_cond al
.endm

.macro enable_irq
asm_trace_hardirqs_on
enable_irq_notrace
.endm


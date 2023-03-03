#include <asm/asm-offsets.h>

.macro	zero_fp
#ifdef CONFIG_FRAME_POINTER
  mov  fp, $0
#endif
.endm

.macro  alignment_trap, rtemp
#ifdef CONFIG_ALIGNMENT_TRAP
  ldr \rtemp, .LCcralign
  ldr \rtemp, [\rtemp]
  mcr	p15, 0, \rtemp, c1, c0
#endif
.endm


.global Ldiv0

Ldiv0:
  str lr, [sp, $-8]!
  bl  __div0
  mov r0, $0                       @ About as wrong as it could be.
  ldr pc, [sp], $8


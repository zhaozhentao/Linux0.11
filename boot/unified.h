#define ARM(x...)	x
#define THUMB(x...)
#define W(instr)    instr

#define ENDPROC(name) \
  .type name, %function; \
  END(name)

#define SYS_ERROR0 10420224

#ifndef __ALIGN
#define __ALIGN     .align 4,0x90
#define __ALIGN_STR ".align 4,0x90"
#endif

#define ALIGN __ALIGN

#ifndef ENTRY
#define ENTRY(name) \
  .global name; \
  ALIGN; \
  name:
#endif

#ifndef END
#define END(name) \
  .size name, .-name
#endif

#ifndef ENDPROC
#define ENDPROC(name) \
  .type name, %function; \
  END(name)
#endif

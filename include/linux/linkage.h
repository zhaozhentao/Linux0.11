#ifndef ENTRY
#define ENTRY(name) \
  .globl name; \
  ALIGN; \
  name:
#endif

#ifndef END
#define END(name) \
  .size name, .-name
#endif


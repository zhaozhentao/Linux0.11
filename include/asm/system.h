#define _set_gate(gate_addr,type,dpl,addr) \
__asm__ (""                                \
:                                          \
:                                          \
 )                                         \

#define set_trap_gate(n,addr) _set_gate(&idt[n],15,0,addr)

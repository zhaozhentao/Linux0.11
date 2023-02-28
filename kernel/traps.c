#include <asm/system.h>

void divide_error(void);

void trap_init(void) {
    int i;

    set_trap_gate(0, &divide_error);
}
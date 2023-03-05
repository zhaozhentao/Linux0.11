#include <asm/system.h>

void divide_error(void);
void __vectors_start(void);

asmlinkage void do_undefinstr() {

}

void trap_init(void) {
    int i;

    long vector = &__vectors_start;
    vector = vector + 1;
    set_trap_gate(0, &divide_error);
    set_trap_gate(0, &__vectors_start);
}

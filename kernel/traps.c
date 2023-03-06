#include <asm/system.h>

void divide_error(void);
void __vectors_start(void);

asmlinkage void do_undefinstr() {

}

asmlinkage void __div0(void) {
    printk("Division by zero in kernel.\n");
}

void trap_init(void) {
    int i;

    long vector = &__vectors_start;
    vector = vector + 1;
    set_trap_gate(0, &divide_error);
    set_trap_gate(0, &__vectors_start);
}

#include <linux/sched.h>

long user_stack[PAGE_SIZE >> 2];

struct {
    long *a;
} stack_start = {&user_stack[PAGE_SIZE >> 2]};

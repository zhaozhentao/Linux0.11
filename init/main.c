#include <linux/fs.h>

extern void mem_init(long start, long end);

#define EXT_MEM_K (*(unsigned short *)0x30090002)
#define DRIVE_INFO (*(struct drive_info *)0x30090080)
#define ORIG_ROOT_DEV (*(unsigned short *)0x300901FC)

static long memory_end = 0;
static long buffer_memory_end = 0;
static long main_memory_start = 0;

struct drive_info {
    char dummy[32];
} drive_info;

/* This really IS void, no error here. */
void main(void) {
    /* The startup routine assumes (well, ...) this */
    /*
     * Interrupts are still disabled. Do necessary setups, then
     * enable them
     */
    int a, b;
    float c;
    a = 1;
    b = 0;
    c = a / b;

    //ROOT_DEV = ORIG_ROOT_DEV;
    //drive_info = DRIVE_INFO;
    //memory_end = (1 << 20) + (EXT_MEM_K << 10);
    //memory_end &= 0xfffff000;
    //if (memory_end > 16 * 1024 * 1024)
    //    memory_end = 16 * 1024 * 1024;

    //if (memory_end > 12 * 1024 * 1024) {
    //    buffer_memory_end = 4 * 1024 * 1024;
    //} else if (memory_end > 6 * 1024 * 1024) {
    //    buffer_memory_end = 2 * 1024 * 1024;
    //} else {
    //    buffer_memory_end = 1 * 1024 * 1024;
    //}
    //main_memory_start = buffer_memory_end;
    //// todo ramdisk

    //mem_init(main_memory_start,memory_end);
    //trap_init();

    //while (1) {

    //}
}

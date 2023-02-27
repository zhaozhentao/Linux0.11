#include <linux/fs.h>

#define EXT_MEM_K (*(unsigned short *)0x90002)
#define DRIVE_INFO (*(struct drive_info *)0x90080)
#define ORIG_ROOT_DEV (*(unsigned short *)0x901FC)

static long memory_end = 0;
static long buffer_memory_end = 0;

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
    ROOT_DEV = ORIG_ROOT_DEV;
    drive_info = DRIVE_INFO;
    memory_end = (1 << 20) + (EXT_MEM_K << 10);
    memory_end &= 0xfffff000;
    if (memory_end > 16 * 1024 * 1024)
        memory_end = 16 * 1024 * 1024;

    if (memory_end > 12 * 1024 * 1024)
        buffer_memory_end = 4 * 1024 * 1024;

    while (1) {

    }
}

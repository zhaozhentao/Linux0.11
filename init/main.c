#include <linux/fs.h>

#define DRIVE_INFO (*(struct drive_info *)0x90080)
#define ORIG_ROOT_DEV (*(unsigned short *)0x901FC)

struct drive_info { char dummy[32]; } drive_info;

/* This really IS void, no error here. */
void main(void) {
    /* The startup routine assumes (well, ...) this */
    /*
     * Interrupts are still disabled. Do necessary setups, then
     * enable them
     */
    ROOT_DEV = ORIG_ROOT_DEV;
    drive_info = DRIVE_INFO;

    while (1) {

    }
}

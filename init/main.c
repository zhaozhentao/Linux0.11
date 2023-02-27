#define ORIG_ROOT_DEV (*(unsigned short *)0x901FC)

ROOT_DEV = ORIG_ROOT_DEV;

void main(void) {
    ROOT_DEV = ORIG_ROOT_DEV;

    while(1) {

    }
}

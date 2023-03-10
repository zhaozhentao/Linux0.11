#define GSTATUS1        (*(volatile unsigned int *)0x560000B0)
#define BUSY            1
#define NAND_SECTOR_SIZE    512
#define NAND_BLOCK_MASK     (NAND_SECTOR_SIZE - 1)

typedef unsigned int S3C24X0_REG32;

/* NAND FLASH (see S3C2440 manual chapter 6, www.100ask.net) */
typedef struct {
    S3C24X0_REG32 NFCONF;
    S3C24X0_REG32 NFCONT;
    S3C24X0_REG32 NFCMD;
    S3C24X0_REG32 NFADDR;
    S3C24X0_REG32 NFDATA;
    S3C24X0_REG32 NFMECCD0;
    S3C24X0_REG32 NFMECCD1;
    S3C24X0_REG32 NFSECCD;
    S3C24X0_REG32 NFSTAT;
    S3C24X0_REG32 NFESTAT0;
    S3C24X0_REG32 NFESTAT1;
    S3C24X0_REG32 NFMECC0;
    S3C24X0_REG32 NFMECC1;
    S3C24X0_REG32 NFSECC;
    S3C24X0_REG32 NFSBLK;
    S3C24X0_REG32 NFEBLK;
} S3C2440_NAND;

static S3C2440_NAND *s3c2440nand = (S3C2440_NAND *) 0x4e000000;

/* 供外部调用的函数 */
void nand_init(void);

void nand_read(unsigned char *buf, unsigned long start_addr, int size);

/* NAND Flash操作的总入口 */
static void nand_reset(void);

static void wait_idle(void);

static void nand_select_chip(void);

static void nand_deselect_chip(void);

static void write_cmd(int cmd);

static void write_addr(unsigned int addr);

static unsigned char read_data(void);

/* S3C2440的NAND Flash处理函数 */
static void s3c2440_nand_select_chip(void);

/* 发出片选信号 */
static void s3c2440_nand_select_chip(void) {
    int i;
    s3c2440nand->NFCONT &= ~(1 << 1);
    for (i = 0; i < 10; i++);
}

static void nand_select_chip(void) {
    int i;
    s3c2440_nand_select_chip();
    for (i = 0; i < 10; i++);
}

/* 复位 */
/* 在第一次使用NAND Flash前，复位一下NAND Flash */
static void nand_reset(void) {
    s3c2440_nand_select_chip();
    write_cmd(0xff);  // 复位命令
    wait_idle();
    nand_deselect_chip();
}

/* 等待NAND Flash就绪 */
static void wait_idle(void) {
    int i;
    volatile unsigned char *p = (volatile unsigned char *) &s3c2440nand->NFSTAT;
    while (!(*p & BUSY))
        for (i = 0; i < 10; i++);
}

/* 取消片选信号 */
static void nand_deselect_chip(void) {
    s3c2440nand->NFCONT |= (1 << 1);
}

/* 发出命令 */
static void write_cmd(int cmd) {
    volatile unsigned char *p = (volatile unsigned char *) &s3c2440nand->NFCMD;
    *p = cmd;
}

/* 发出地址 */
static void write_addr(unsigned int addr) {
    int i;
    volatile unsigned char *p = (volatile unsigned char *) &s3c2440nand->NFADDR;

    *p = addr & 0xff;
    for (i = 0; i < 10; i++);
    *p = (addr >> 9) & 0xff;
    for (i = 0; i < 10; i++);
    *p = (addr >> 17) & 0xff;
    for (i = 0; i < 10; i++);
    *p = (addr >> 25) & 0xff;
    for (i = 0; i < 10; i++);
}

/* 读取数据 */
static unsigned char read_data(void) {
    volatile unsigned char *p = (volatile unsigned char *) &s3c2440nand->NFDATA;
    return *p;
}

/* 初始化NAND Flash */
void nand_init(void) {
#define TACLS   0
#define TWRPH0  3
#define TWRPH1  0

    /* 设置时序 */
    s3c2440nand->NFCONF = (TACLS << 12) | (TWRPH0 << 8) | (TWRPH1 << 4);
    /* 使能NAND Flash控制器, 初始化ECC, 禁止片选 */
    s3c2440nand->NFCONT = (1 << 4) | (1 << 1) | (1 << 0);

    /* 复位NAND Flash */
    nand_reset();
}

/* 读函数 */
void nand_read(unsigned char *buf, unsigned long start_addr, int size) {
    int i, j;

    if ((start_addr & NAND_BLOCK_MASK) || (size & NAND_BLOCK_MASK)) {
        return;    /* 地址或长度不对齐 */
    }

    /* 选中芯片 */
    nand_select_chip();

    for (i = start_addr; i < (start_addr + size);) {
        /* 发出READ0命令 */
        write_cmd(0);

        /* Write Address */
        write_addr(i);
        wait_idle();

        for (j = 0; j < NAND_SECTOR_SIZE; j++, i++) {
            *buf = read_data();
            buf++;
        }
    }

    /* 取消片选信号 */
    nand_deselect_chip();

    return;
}

static long HIGH_MEMORY = 0;

/* these are not to be changed without changing head.s etc */
#define LOW_MEM 0x100000
#define PAGING_MEMORY (15*1024*1024)
#define PAGING_PAGES (PAGING_MEMORY>>12)
#define MAP_NR(addr) (((addr)-LOW_MEM)>>12)
#define USED 100

static unsigned char mem_map[PAGING_PAGES] = {0,};

/*
* 用于段描述符的一些宏定义
*/
#define MMU_FULL_ACCESS     (3 << 10)   /* 访问权限 */
#define MMU_DOMAIN          (0 << 5)    /* 属于哪个域 */
#define MMU_SPECIAL         (1 << 4)    /* 必须是1 */
#define MMU_CACHEABLE       (1 << 3)    /* cacheable */
#define MMU_BUFFERABLE      (1 << 2)    /* bufferable */
#define MMU_SECTION         (2)         /* 表示这是段描述符 */
#define MMU_SECDESC         (MMU_FULL_ACCESS | MMU_DOMAIN | MMU_SPECIAL | \
                             MMU_SECTION)
#define MMU_SECDESC_WB      (MMU_FULL_ACCESS | MMU_DOMAIN | MMU_SPECIAL | \
                             MMU_CACHEABLE | MMU_BUFFERABLE | MMU_SECTION)
#define MMU_SECTION_SIZE    0x00100000

void create_page_table(void) {
    unsigned long virtuladdr, physicaladdr;
    unsigned long *mmu_tlb_base = (unsigned long *) 0x30000000;

    /*
     * Steppingstone的起始物理地址为0，第一部分程序的起始运行地址也是0，
     * 为了在开启MMU后仍能运行第一部分的程序，
     * 将0～1M的虚拟地址映射到同样的物理地址
     */
    virtuladdr = 0;
    physicaladdr = 0;
    *(mmu_tlb_base + (virtuladdr >> 20)) = (physicaladdr & 0xFFF00000) | MMU_SECDESC_WB;

    virtuladdr = 0x30000000;
    physicaladdr = 0x30000000;
    *(mmu_tlb_base + (virtuladdr >> 20)) = (physicaladdr & 0xFFF00000) | MMU_SECDESC_WB;
}

void mmu_init(void) {
    unsigned long ttb = 0x30000000;

    __asm__(
            "mov    r0, #0\n"
            "mcr    p15, 0, r0, c7, c7, 0\n"    /* 使无效ICaches和DCaches */

            "mcr    p15, 0, r0, c7, c10, 4\n"   /* drain write buffer on v4 */
            "mcr    p15, 0, r0, c8, c7, 0\n"    /* 使无效指令、数据TLB */

            "mov    r4, %0\n"                   /* r4 = 页表基址 */
            "mcr    p15, 0, r4, c2, c0, 0\n"    /* 设置页表基址寄存器 */

            "mvn    r0, #0\n"
            "mcr    p15, 0, r0, c3, c0, 0\n"    /* 域访问控制寄存器设为0xFFFFFFFF，
                                                 * 不进行权限检查
                                                 */
            /*
             * 对于控制寄存器，先读出其值，在这基础上修改感兴趣的位，
             * 然后再写入
             */
            "mrc    p15, 0, r0, c1, c0, 0\n"    /* 读出控制寄存器的值 */

            /* 控制寄存器的低16位含义为：.RVI ..RS B... .CAM
             * R : 表示换出Cache中的条目时使用的算法，
             *     0 = Random replacement；1 = Round robin replacement
             * V : 表示异常向量表所在的位置，
             *     0 = Low addresses = 0x00000000；1 = High addresses = 0xFFFF0000
             * I : 0 = 关闭ICaches；1 = 开启ICaches
             * R、S : 用来与页表中的描述符一起确定内存的访问权限
             * B : 0 = CPU为小字节序；1 = CPU为大字节序
             * C : 0 = 关闭DCaches；1 = 开启DCaches
             * A : 0 = 数据访问时不进行地址对齐检查；1 = 数据访问时进行地址对齐检查
             * M : 0 = 关闭MMU；1 = 开启MMU
             */

            /*
             * 先清除不需要的位，往下若需要则重新设置它们
             */
            /* .RVI ..RS B... .CAM */
            "bic    r0, r0, #0x3000\n"          /* ..11 .... .... .... 清除V、I位 */
            "bic    r0, r0, #0x0300\n"          /* .... ..11 .... .... 清除R、S位 */
            "bic    r0, r0, #0x0087\n"          /* .... .... 1... .111 清除B/C/A/M */

            /*
             * 设置需要的位
             */
            "orr    r0, r0, #0x0002\n"          /* .... .... .... ..1. 开启对齐检查 */
            "orr    r0, r0, #0x0004\n"          /* .... .... .... .1.. 开启DCaches */
            "orr    r0, r0, #0x1000\n"          /* ...1 .... .... .... 开启ICaches */
            "orr    r0, r0, #0x0001\n"          /* .... .... .... ...1 使能MMU */

            "mcr    p15, 0, r0, c1, c0, 0\n"    /* 将修改的值写入控制寄存器 */
            : /* 无输出 */
            : "r" (ttb)
            );
}

void mem_init(long start_mem, long end_mem) {
    int i;

    HIGH_MEMORY = end_mem;
    for (i = 0; i < PAGING_PAGES; i++) {
        mem_map[i] = USED;
    }

    i = MAP_NR(start_mem);
    end_mem -= start_mem;
    end_mem >>= 12;
    while (end_mem-- > 0)
        mem_map[i++] = 0;
}

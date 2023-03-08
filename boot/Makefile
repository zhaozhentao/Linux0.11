include ../Makefile.header

all: bootsect setup interrupt

bootsect: bootsect.s ../arch/arm/mach-s3c2410/nand.o
	@$(AS) -o bootsect.o bootsect.s
	@$(LD) -Tfile.lds bootsect.o ../arch/arm/mach-s3c2410/nand.o -o bootsect_elf
	@$(OBJCOPY) -R .pdr -R .comment -R .note -O binary -S bootsect_elf bootsect
	@$(OBJDUMP) -D -m arm bootsect_elf > bootsect.dis

setup: setup.s
	@$(AS) -o setup.o setup.s
	@$(LD) -Ttext 0x30090200 -g setup.o -o setup_elf
	@$(OBJCOPY) -R .pdr -R .comment -R .note -O binary -S setup_elf setup
	@$(OBJDUMP) -D -m arm setup_elf > setup_elf.dis

interrupt: interrupt.s
	@$(AS) -o interrupt.o interrupt.s
	@$(LD) -Ttext 0x0 -g interrupt.o -o interrupt_elf
	@$(OBJCOPY) -R .pdr -R .comment -R .note -O binary -S interrupt_elf interrupt
	@$(OBJDUMP) -D -m arm interrupt_elf > interrupt_elf.dis

head.o: head.S
	@$(CC)                                       \
	-D__ASSEMBLY__                               \
	-I../include                                 \
	-I../arch/arm/include                        \
	-I../arch/arm/mach-s3c2410/include           \
	-include ../include/linux/autoconf.h         \
	-include ../include/linux/linkage.h          \
	-include ../arch/arm/include/asm/assembler.h \
	-include ../arch/arm/include/asm/unified.h   \
	-include ../arch/arm/include/asm/ptrace.h    \
	-c -o head.o head.S

entry-common.o: entry-common.S
	@$(CC)                                     \
	-include ../include/linux/linkage.h        \
	-include ../arch/arm/include/asm/unified.h \
	-include ../arch/arm/include/asm/ptrace.h  \
	-c -o entry-common.o entry-common.S

../arch/arm/mach-s3c2410/nand.o : ../arch/arm/mach-s3c2410/nand.c
	make nand.o -C ../arch/arm/mach-s3c2410

clean:
	rm -f head.s entry-common.s *.o bootsect setup interrupt *.dis *_elf


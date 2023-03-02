include ../Makefile.header

all: bootsect setup interrupt

bootsect: bootsect.s
	@$(AS) -o bootsect.o bootsect.s
	@$(LD) -Ttext 0x30090000 -g bootsect.o -o bootsect_elf
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
	@$(CC) -include ../include/linux/linkage.h \
	-include ../arch/arm/include/asm/ptrace.h
	-c -o head.o head.S

clean:
	rm -f head.s *.o bootsect setup interrupt *.dis *_elf


include ../Makefile.header

all: bootsect setup

bootsect: bootsect.s
	$(AS) -o bootsect.o bootsect.s
	$(LD) -Ttext 0x30000000 -g bootsect.o -o bootsect_elf
	$(OBJCOPY) -R .pdr -R .comment -R.note -O binary -S bootsect_elf bootsect
	@$(OBJDUMP) -D -m arm bootsect_elf > bootsect.dis

setup: setup.s
	$(AS) -o setup.o setup.s
	$(LD) -Ttext 0x30000200 -g setup.o -o setup_elf
	$(OBJCOPY) -R .pdr -R .comment -R.note -O binary -S setup_elf setup

head.o: head.s
	$(AS) -o head.o head.s

clean:
	rm -f *.o bootsect setup *.dis setup_elf bootsect_elf


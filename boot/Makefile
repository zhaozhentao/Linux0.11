include ../Makefile.header

LDFLAGS	+= -Ttext 0

all: bootsect setup

bootsect: bootsect.s
	@$(AS) -o bootsect.o bootsect.s
	@$(LD) $(LDFLAGS) -g bootsect.o -o bootsect_elf
	@$(OBJCOPY) -R .pdr -R .comment -R.note -O binary -S bootsect_elf bootsect.bin
	@$(OBJDUMP) -D -m arm bootsect_elf > bootsect.dis

setup: setup.s
	@$(AS) -o setup.o setup.s
	@$(LD) $(LDFLAGS) -g setup.o -o setup_elf
	@$(OBJCOPY) -R .pdr -R .comment -R.note -O binary -S setup_elf setup.bin

head.o: head.s
	@$(AS) -o head.o head.s

clean:
	rm -f *.o *.bin setup_elf bootsect_elf 


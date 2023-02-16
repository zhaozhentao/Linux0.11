include ../Makefile.header

LDFLAGS	+= -Ttext 0

all: bootsect setup

bootsect: bootsect.s
	@$(CC) -g -c -o bootsect.o bootsect.s
	@$(LD) $(LDFLAGS) -g bootsect.o -o bootsect_elf
	@$(OBJCOPY) -R .pdr -R .comment -R.note -O binary -S bootsect_elf bootsect.bin

setup: setup.s
	@$(CC) -g -c -o setup.o setup.s
	@$(LD) $(LDFLAGS) -g setup.o -o setup_elf
	@$(OBJCOPY) -R .pdr -R .comment -R.note -O binary -S setup_elf setup.bin

clean:
	rm -f *.o  bootsect_elf *.bin


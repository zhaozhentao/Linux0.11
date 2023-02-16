include ../Makefile.header

LDFLAGS	+= -Ttext 0

bootsect: bootsect.s
	@$(CC) -g -c -o bootsect.o bootsect.s
	@$(LD) $(LDFLAGS) -g bootsect.o -o bootsect_elf
	@$(OBJCOPY) -R .pdr -R .comment -R.note -O binary -S bootsect_elf bootsect.bin

clean:
	rm -f *.o  bootsect_elf *.bin


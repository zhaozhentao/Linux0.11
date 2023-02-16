include ../Makefile.header

bootsect: bootsect.s
	@$(CC) -g -c -o bootsect.o bootsect.s
	@$(LD) -Ttext 0 -g bootsect.o -o bootsect_elf
	@$(OBJCOPY) -R .pdr -R .comment -R.note -O binary -S bootsect_elf bootsect.bin

clean:
	rm -f *.o  bootsect_elf *.bin


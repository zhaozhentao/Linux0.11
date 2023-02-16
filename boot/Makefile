bootsect: bootsect.s
	arm-linux-gcc -g -c -o bootsect.o bootsect.s
	arm-linux-ld -Ttext 0 -g bootsect.o -o bootsect_elf
	arm-linux-objcopy -O binary -S bootsect_elf bootsect

include ../Makefile.header

LDFLAGS	+= -r
CFLAGS	+= -I../include

OBJS = asm.o sched.o traps.o printk.o vsprintf.o

kernel.o : $(OBJS)
	@$(LD) $(LDFLAGS) -o kernel.o $(OBJS)
	@sync

traps.s traps.o : traps.c
	@$(CC)                                   \
	-I../include                             \
	-include ../include/linux/linkage.h      \
	-c traps.c

printk.s printk.o : printk.c ../include/stdarg.h ../include/stddef.h ../include/linux/kernel.h 

vsprintf.s vsprintf.o : vsprintf.c ../include/stdarg.h

clean:
	@rm -f *.o

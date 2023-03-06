include ../Makefile.header

LDFLAGS	+= -r
CFLAGS	+= -nostdinc -I../include

.c.s:
	$(CC) $(CFLAGS) -S -o $*.s $<
.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<


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

vsprintf.s vsprintf.o : vsprintf.c ../include/stdarg.h ../include/string.h

clean:
	@rm -f *.o

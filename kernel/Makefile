include ../Makefile.header

LDFLAGS	+= -r
CFLAGS	+= -I../include

OBJS  = asm.o sched.o traps.o printk.o

kernel.o: $(OBJS)
	@$(LD) $(LDFLAGS) -o kernel.o $(OBJS)
	@sync

traps.s traps.o: traps.c
	@$(CC)                                   \
	-I../include                             \
	-include ../include/linux/linkage.h      \
	-c traps.c

clean:
	@rm -f *.o

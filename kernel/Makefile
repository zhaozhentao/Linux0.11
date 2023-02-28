include ../Makefile.header

LDFLAGS	+= -r
CFLAGS	+= -I../include

OBJS  = asm.o sched.o traps.o

kernel.o: $(OBJS)
	@$(LD) $(LDFLAGS) -o kernel.o $(OBJS)
	@sync

traps.s traps.o: traps.c ../include/asm/system.h

clean:
	@rm -f *.o

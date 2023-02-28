include ../Makefile.header

LDFLAGS	+= -r
CFLAGS	+= -I../include

.s.o:
	@$(AS) -o $*.o $<

OBJS  = sched.o asm.o traps.o

kernel.o: $(OBJS)
	@$(LD) $(LDFLAGS) -o kernel.o $(OBJS)
	@sync

traps.s traps.o: traps.c ../include/asm/system.h

clean:
	@rm -f *.o

include ../Makefile.header

LDFLAGS	+= -r
CFLAGS	+= -I../include

.s.o:
	@$(AS) -o $*.o $<

OBJS  = sched.o asm.o traps.o

kernel.o: $(OBJS)
	@$(LD) $(LDFLAGS) -o kernel.o $(OBJS)
	@sync

clean:
	@rm -f *.o

include ../Makefile.header

LDFLAGS	+= -r

OBJS  = sched.o

kernel.o: $(OBJS)
	@$(LD) $(LDFLAGS) -o kernel.o $(OBJS)

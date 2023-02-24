include ../Makefile.header

LDFLAGS	+= -r

CFLAGS	+= -I../include

OBJS  = sched.o

kernel.o: $(OBJS)
	@$(LD) $(LDFLAGS) -o kernel.o $(OBJS)
	@sync

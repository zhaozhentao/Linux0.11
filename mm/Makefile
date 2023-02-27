include ../Makefile.header

CFLAGS	+= -I../include

.c.o:
	@$(CC) $(CFLAGS) -c -o $*.o $<

OBJS	= memory.o

mm.o: $(OBJS)
	@$(LD) $(LDFLAGS) -o mm.o $(OBJS)

clean:
	rm -f *.o

memory.o: memory.c

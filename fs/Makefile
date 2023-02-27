include ../Makefile.header

CFLAGS	+= -I../include

OBJS  = super.o

fs.o: $(OBJS)
	@$(LD) -r -o fs.o $(OBJS)

clean:
	@rm -f *.o

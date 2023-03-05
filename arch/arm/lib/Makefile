include ../../../Makefile.header

lib.a: lib1funcs.o
	$(AR) rcs lib.a lib1funcs.o

lib1funcs.o: lib1funcs.S
	@$(CC)                                       \
	-include ../../../include/linux/linkage.h          \
	-c -o lib1funcs.o lib1funcs.S

clean:
	rm -f *.a *.o


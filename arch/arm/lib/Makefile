include ../../../Makefile.header

lib.a: lib1funcs.o
	$(AR) rcs lib.a lib1funcs.o

lib1funcs.o: lib1funcs.S
	@$(CC)                                       \
	-c -o lib1funcs.o lib1funcs.S


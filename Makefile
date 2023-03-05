include Makefile.header

print-%  : ; @echo $* = $($*)

LDFLAGS := -L $(shell dirname `$(CC) $(CFLAGS) -print-libgcc-file-name`) -lgcc
LDFLAGS	+= -e _start

ARCHIVES=kernel/kernel.o mm/mm.o fs/fs.o
LIBS	=arch/arm/lib/lib.a

all: Image

.c.s:
	$(CC) $(CFLAGS) -nostdinc -Iinclude -S -o $*.s $<
.s.o:
	$(AS) -c -o $*.o $<
.c.o:
	$(CC) $(CFLAGS) -nostdinc -Iinclude -c -o $*.o $<

Image: boot/bootsect boot/setup boot/interrupt tools/system
	cp -f tools/system system.tmp
	$(STRIP) system.tmp
	$(OBJCOPY) -R .pdr -R .comment -R .note -O binary -S system.tmp tools/kernel
	$(OBJDUMP) -D -m arm tools/system > tools/system.dis
	tools/build.sh boot/bootsect boot/setup boot/interrupt tools/kernel Image

tools/system: boot/head.o boot/entry-common.o init/main.o $(LIBS) \
	$(ARCHIVES)
	$(LD) -Tfile.lds  boot/head.o boot/entry-common.o init/main.o \
	$(ARCHIVES) \
	$(LIBS) \
	-o tools/system $(LDFLAGS)

kernel/kernel.o:
	make -C kernel

mm/mm.o:
	make -C mm

fs/fs.o:
	make -C fs

boot/head.o: boot/head.S
	make head.o -C boot/

boot/entry-common.o: boot/entry-common.S
	make entry-common.o -C boot/

boot/interrupt: boot/interrupt.s
	make interrupt -C boot

arch/arm/lib/lib.a:
	make lib.a -C arch/arm/lib

boot/setup: boot/setup.s
	make setup -C boot

boot/bootsect: boot/bootsect.s
	make bootsect -C boot

clean:
	rm -f Image system.map boot/bootsect boot/setup boot/interrupt
	rm -f init/*.o tools/system tools/kernel tools/system.dis
	for i in mm kernel boot arch/arm; do make clean -C $$i; done

init/main.o: init/main.c  \
	include/linux/sched.h \
	include/linux/fs.h    \
	include/linux/mm.h
	$(CC) $(CFLAGS) -nostdinc -Iinclude -c -o $*.o $<

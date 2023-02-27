include Makefile.header

print-%  : ; @echo $* = $($*)

LDFLAGS	+= -e _start

ARCHIVES=kernel/kernel.o fs/fs.o

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

tools/system: boot/head.o init/main.o \
	$(ARCHIVES)
	$(LD) -Tfile.lds $(LDFLAGS) boot/head.o init/main.o \
	$(ARCHIVES) \
	-o tools/system

kernel/kernel.o:
	make -C kernel

fs/fs.o:
	make -C fs

boot/head.o: boot/head.s
	make head.o -C boot/

boot/interrupt: boot/interrupt.s
	make interrupt -C boot

boot/setup: boot/setup.s
	make setup -C boot

boot/bootsect: boot/bootsect.s
	make bootsect -C boot

clean:
	rm -f Image system.map boot/bootsect boot/setup boot/interrupt
	rm -f init/*.o tools/system tools/kernel tools/system.dis
	for i in kernel boot; do make clean -C $$i; done

init/main.o: init/main.c \
	include/linux/sched.h \
	include/linux/fs.h \
	include/linux/mm.h

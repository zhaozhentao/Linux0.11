include Makefile.header

LDFLAGS	+= -Ttext 0 -e startup_32

all: Image

.c.o:
	@$(CC) $(CFLAGS) -c -o $*.o $<

Image: boot/bootsect boot/setup boot/interrupt tools/system
	@cp -f tools/system system.tmp
	@$(STRIP) system.tmp
	@$(OBJCOPY) -O binary -R .note -R .comment system.tmp tools/kernel
	@tools/build.sh boot/bootsect boot/setup boot/interrupt tools/kernel Image
	@$(OBJDUMP) -D -m arm tools/system > tools/system.dis

tools/system: boot/head.o init/main.o
	@$(LD) $(LDFLAGS) boot/head.o init/main.o -o tools/system

boot/head.o: boot/head.s
	@make head.o -C boot/

boot/interrupt: boot/interrupt.s
	@make interrupt -C boot

boot/setup: boot/setup.s
	@make setup -C boot

boot/bootsect: boot/bootsect.s
	@make bootsect -C boot

clean:
	@rm -f Image system.map boot/bootsect boot/setup boot/interrupt
	@rm -f tools/system
	@for i in boot; do make clean -C $$i; done

init/main.o: init/main.c


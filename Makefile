include Makefile.header

LDFLAGS	+= -Ttext 0 -e startup_32

all: Image

Image: boot/bootsect boot/setup tools/system
	@cp -f tools/system system.tmp
	@$(STRIP) system.tmp
	@$(OBJCOPY) -O binary -R .note -R .comment system.tmp tools/kernel
	@tools/build.sh boot/bootsect boot/setup tools/kernel Image

tools/system: boot/head.o
	@$(LD) $(LDFLAGS) boot/head.o -o tools/system 

boot/head.o: boot/head.s
	@make head.o -C boot/

boot/setup: boot/setup.s
	@make setup -C boot

boot/bootsect: boot/bootsect.s
	@make bootsect -C boot

clean:
	@rm -f Image System.map boot/bootsect boot/setup
	@rm -f tools/system
	@for i in boot; do make clean -C $$i; done


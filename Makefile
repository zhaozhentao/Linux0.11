include Makefile.header

all: Image

Image: boot/bootsect boot/setup 
	@tools/build.sh boot/bootsect boot/setup Image

boot/setup: boot/setup.s
	@make setup -C boot

boot/bootsect: boot/bootsect.s
	@make bootsect -C boot

clean:
	@rm -f Image boot/bootsect boot/setup
	@for i in boot; do make clean -C $$i; done


include Makefile.header

all: Image

Image: boot/bootsect boot/setup 
	echo Image

boot/setup: boot/setup.s
	@make setup -C boot

boot/bootsect: boot/bootsect.s
	@make bootsect -C boot


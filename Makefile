include Makefile.header

all: Image

Image: boot/bootsect boot/setup 
	echo Image


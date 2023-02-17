#!/bin/bash

bootsect=$1
setup=$2
IMAGE=$3

# Write bootsect (512 bytes, one sector) to stdout
[ ! -f "$bootsect" ] && echo "there is no bootsect binary file there" && exit -1
dd if=$bootsect bs=512 count=1 of=$IMAGE 2>&1 >/dev/null


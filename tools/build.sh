#!/bin/bash

bootsect=$1
setup=$2
system=$3
IMAGE=$4

# Write bootsect (512 bytes, one sector) to stdout
[ ! -f "$bootsect" ] && echo "there is no bootsect binary file there" && exit -1
dd if=$bootsect bs=512 count=1 of=$IMAGE 2>&1 >/dev/null

# Write setup(4 * 512bytes, four sectors) to stdout
[ ! -f "$setup" ] && echo "there is no setup binary file there" && exit -1
dd if=$setup seek=1 bs=512 count=4 of=$IMAGE 2>&1 >/dev/null

[ ! -f "$system" ] && echo "there is no system binary file there" && exit -1
system_size=`wc -c $system |cut -d" " -f1`
[ $system_size -gt $SYS_SIZE ] && echo "the system binary is too big" && exit -1
dd if=$system seek=5 bs=512 count=$((2888-1-4)) of=$IMAGE 2>&1 >/dev/null


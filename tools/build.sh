#!/bin/bash

bootsect=$1
setup=$2
interrupt=$3
system=$4
IMAGE=$5

# Set the biggest sys_size
# # Changes from 0x20000 to 0x30000 by tigercn to avoid oversized code.
SYS_SIZE=$((0x3000*16))

# Write bootsect (512 bytes, one sector) to stdout
[ ! -f "$bootsect" ] && echo "there is no bootsect binary file there" && exit -1
dd if=$bootsect bs=512 count=1 of=$IMAGE 2>&1 >/dev/null

# Write setup (512 bytes, one sectors) to stdout
[ ! -f "$setup" ] && echo "there is no setup binary file there" && exit -1
dd if=$setup seek=1 bs=512 count=1 of=$IMAGE 2>&1 >/dev/null

# todo just make module as small as it can during testing stage

# Write interrupt(8 * 512bytes, eight sectors) to stdout
[ ! -f "$interrupt" ] && echo "there is no interrupt binary file there" && exit -1
dd if=$interrupt seek=2 bs=512 count=1 of=$IMAGE 2>&1 >/dev/null

[ ! -f "$system" ] && echo "there is no system binary file there" && exit -1
system_size=`wc -c $system |cut -d" " -f1`
[ $system_size -gt $SYS_SIZE ] && echo "the system binary is too big" && exit -1
dd if=$system seek=3 bs=512 count=$((2888-1-4)) of=$IMAGE 2>&1 >/dev/null


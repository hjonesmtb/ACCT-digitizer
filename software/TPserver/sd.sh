#!/bin/sh x
# Mount SDcard

echo "Mount SDcard for FPGA configuration upgrade"
echo "to /mnt/SD"
fdisk -l
mount -t vfat /dev/mmcblk0p1 /mnt/SD
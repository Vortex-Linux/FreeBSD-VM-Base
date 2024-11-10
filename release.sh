#!/bin/bash 

echo "Shutting down the FreeBSD VM..." 

echo y | ship --vm shutdown freebsd-vm-base 

echo "Compressing the FreeBSD VM disk image..."

ship --vm compress freebsd-vm-base 

echo "Copying the FreeBSD VM disk image to generate the release package for 'freebsd-vm-base'..."

DISK_IMAGE=$(sudo virsh domblklist freebsd-vm-base | grep .qcow2 | awk '{print $2}')

cp "$DISK_IMAGE" output/freebsd.qcow2

echo "Splitting the copied disk image into two parts..."

split -b $(( $(stat -c%s "output/freebsd.qcow2") / 2 )) -d -a 3 "output/freebsd.qcow2" "output/freebsd.qcow2."

echo "The release package for 'freebsd-vm-base' has been generated and split successfully!"



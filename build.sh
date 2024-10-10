#!/bin/bash

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
XML_FILE="/tmp/freebsd-vm-base.xml"

LATEST_IMAGE=$(lynx -dump -listonly -nonumbers https://bsd-cloud-image.org | grep freebsd | grep zfs | sort -V | tail -n 1)

echo y | ship --vm delete freebsd-vm-base 

echo n | ship --vm create freebsd-vm-base --source "$LATEST_IMAGE"

sed -i '/<\/devices>/i \
  <console type="pty">\
    <target type="virtio"/>\
  </console>' "$XML_FILE"

virsh -c qemu:///system undefine freebsd-vm-base
virsh -c qemu:///system define "$XML_FILE"

ship --vm start freebsd-vm-base 

#./setup.sh
./view_vm.sh


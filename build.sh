#!/bin/bash

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
XML_FILE="/tmp/freebsd-vm-base.xml"

LATEST_IMAGE=$(lynx -dump -listonly -nonumbers https://download.freebsd.org/releases/VM-IMAGES | tail -n 2 | head -n 1 | xargs lynx -dump -listonly -nonumbers | grep amd64 | sed 's|$|Latest|' | xargs lynx -dump -listonly -nonumbers | sort -V | grep -v CLOUDINIT | grep zfs | grep qcow)

echo y | ship --vm delete freebsd-vm-base 

echo n | ship --vm create freebsd-vm-base --source "$LATEST_IMAGE"

sed -i '/<\/devices>/i \
  <console type="pty">\
    <target type="virtio"/>\
  </console>\
  <serial type="pty">\
    <target port="0"/>\
  </serial>' "$XML_FILE"

virsh -c qemu:///system undefine freebsd-vm-base
virsh -c qemu:///system define "$XML_FILE"

ship --vm start freebsd-vm-base 

#./setup.sh
./view_vm.sh


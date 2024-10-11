#!/bin/bash

COMMANDS=$(cat <<'EOF'
root
EOF
)

while IFS= read -r command; do
    if [[ -n "$command" ]]; then
        tmux send-keys -t freebsd-vm-base "$command" C-m
        sleep 1
    fi
done <<< "$COMMANDS"

COMMANDS=$(cat <<EOF
KEYMAP="us" && 
kbdcontrol -l /usr/share/syscons/keymaps/${KEYMAP}.kbd &&

TARGET_DISK="vtbd0" && 
gpart destroy -F ${TARGET_DISK} >/dev/null 2>&1 && 
gpart create -s GPT ${TARGET_DISK} && 

gpart add -t freebsd-boot -s 512k ${TARGET_DISK} && 
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 ${TARGET_DISK} &&

gpart add -t freebsd-zfs -l zfsroot -a 1m ${TARGET_DISK} && 

kldload zfs &&

zpool create -f -o ashift=12 \
  -O compression=lz4 \  
  -O atime=off \  
  -O mountpoint=none \ 
  zroot /dev/gpt/zfsroot
&& 
zfs create -o mountpoint=none zroot/ROOT  &&
zfs create -o mountpoint=/mnt zroot/ROOT/default &&

zfs set reservation=none zroot &&
zfs set refquota=none zroot &&
zfs set refreservation=none zroot &&

zpool set bootfs=zroot/ROOT/default zroot &&

zfs create -o mountpoint=/mnt/tmp zroot/tmp && 
zfs create -o mountpoint=/mnt/usr zroot/usr &&
zfs create -o mountpoint=/mnt/var zroot/var &&

chmod 1777 /mnt/tmp && 

DISTRIBUTIONS="base.txz kernel.txz" && 
bsdinstall fetch &&
bsdinstall install /mnt ${DISTRIBUTIONS} && 

echo 'zfs_load="YES"' >> /mnt/boot/loader.conf &&
echo 'vfs.root.mountfrom="zfs:zroot/ROOT/default"' >> /mnt/boot/loader.conf && 

touch /mnt/etc/fstab &&
echo 'hostname="freebsd"' > /mnt/etc/rc.conf &&
echo 'sshd_enable="YES"' >> /mnt/etc/rc.conf &&
echo 'zfs_enable="YES"' >> /mnt/etc/rc.conf && 

ROOT_PASSWORD="freebsd" && 
chroot /mnt /bin/sh -c "echo 'root:${ROOT_PASSWORD}' | chpasswd" &&

USER="bsd"  
PASSWORD="freebsd"  
chroot /mnt /bin/sh -c "pw useradd ${USER} -m -s /bin/sh -h 0 -G wheel"  
chroot /mnt /bin/sh -c "echo '${USER}:${PASSWORD}' | chpasswd" 

zfs umount -a &&
zfs set mountpoint=legacy zroot/ROOT/default && 
zpool export zroot 
EOF
)

tmux send-keys -t freebsd-vm-base "$COMMANDS" C-m


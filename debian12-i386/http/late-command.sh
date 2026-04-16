#!/bin/sh
set -eux

# Install extlinux bootloader (GRUB hangs on i386 QEMU)
extlinux --install /boot
ROOTUUID=$(blkid -s UUID -o value /dev/sda1)
KERNEL=$(basename $(ls /boot/vmlinuz-* | sort -V | tail -1))
INITRD=$(basename $(ls /boot/initrd.img-* | sort -V | tail -1))
cat > /boot/extlinux.conf <<EOF
DEFAULT debian
LABEL debian
  KERNEL /boot/$KERNEL
  APPEND root=UUID=$ROOTUUID ro net.ifnames=0 biosdevname=0
  INITRD /boot/$INITRD
EOF
dd if=/usr/lib/syslinux/mbr/mbr.bin of=/dev/sda bs=440 count=1

# Enable root SSH login for Packer, accept RSA keys
cat > /etc/ssh/sshd_config.d/packer.conf <<EOF
PermitRootLogin yes
PubkeyAcceptedAlgorithms +ssh-rsa
HostKeyAlgorithms +ssh-rsa
EOF

# Add virtio modules to initrd
echo virtio_net >> /etc/initramfs-tools/modules
echo virtio_pci >> /etc/initramfs-tools/modules
echo virtio_blk >> /etc/initramfs-tools/modules
update-initramfs -u

# Configure eth0 for DHCP (net.ifnames=0 ensures consistent naming)
cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp
EOF
rm -rf /etc/network/interfaces.d
rm -f /etc/udev/rules.d/70-persistent-net.rules

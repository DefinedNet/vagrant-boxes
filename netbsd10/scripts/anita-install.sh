#!/bin/sh
# Drive anita to produce a NetBSD disk image that packer can boot and SSH into.
#
# Two stages:
#   1. anita install: runs sysinst over the QEMU console to lay down a base
#      install at $WORKDIR/wd0.img.
#   2. anita boot --persist: boots the install once, drops the vagrant insecure
#      public key into /root/.ssh/authorized_keys and enables sshd, then halts.
#
# After this script finishes, packer can use $WORKDIR/wd0.img as a base disk
# and SSH in as root with $WORKDIR/vagrant to run scripts/provision.sh.

set -eux

WORKDIR="${WORKDIR:-anita-work}"
RELEASE_URL="${RELEASE_URL:-https://cdn.netbsd.org/pub/NetBSD/NetBSD-10.1/amd64/}"

mkdir -p "$WORKDIR"

# Vagrant's insecure ssh keypair. Public on github, baked into every vagrant
# install. We need both halves: the public key to trust on the box, the private
# key for packer to ssh in with.
if [ ! -f "$WORKDIR/vagrant.pub" ]; then
    curl -fsSL -o "$WORKDIR/vagrant.pub" \
        https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub
fi
if [ ! -f "$WORKDIR/vagrant" ]; then
    curl -fsSL -o "$WORKDIR/vagrant" \
        https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant
    chmod 600 "$WORKDIR/vagrant"
fi

if [ ! -f "$WORKDIR/wd0.img" ]; then
    anita --workdir="$WORKDIR" install "$RELEASE_URL"
fi

if [ ! -f "$WORKDIR/.bootstrapped" ]; then
    PUBKEY=$(cat "$WORKDIR/vagrant.pub")
    BOOTSTRAP="
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo '$PUBKEY' > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
echo sshd=YES >> /etc/rc.conf
echo dhcpcd=YES >> /etc/rc.conf
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
"
    anita --workdir="$WORKDIR" boot --no-install --persist \
        --run "$BOOTSTRAP" "$RELEASE_URL"
    touch "$WORKDIR/.bootstrapped"
fi

# Anita writes a raw image, but packer's qemu builder uses -F qcow2 when
# use_backing_file is set. Produce a qcow2 copy for packer to back from.
if [ ! -f "$WORKDIR/wd0.qcow2" ] || [ "$WORKDIR/wd0.img" -nt "$WORKDIR/wd0.qcow2" ]; then
    qemu-img convert -O qcow2 "$WORKDIR/wd0.img" "$WORKDIR/wd0.qcow2.tmp"
    mv "$WORKDIR/wd0.qcow2.tmp" "$WORKDIR/wd0.qcow2"
fi

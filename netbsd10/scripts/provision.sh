#!/bin/sh
set -eux

# Non-interactive SSH skips /etc/profile, so PATH is sshd's minimal default.
# Set it explicitly so we find pkg_add, useradd, chown, etc.
export PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/pkg/sbin:/usr/pkg/bin:/usr/local/sbin:/usr/local/bin

# QEMU user-mode advertises an IPv6 prefix that doesn't actually route to the
# public internet. libfetch tries v6 first, waits through retries, then falls
# back to v4 -- compounded across pkg_add's dep chain that's minutes of waste.
# Strip non-link-local v6 addresses and the v6 default route. Don't bring the
# interface down, that kills SSH.
for a in $(ifconfig vioif0 | awk '/inet6/ && !/fe80::/ {sub(/\/.*/,"",$2); print $2}'); do
    ifconfig vioif0 inet6 "$a" delete || true
done
route delete -inet6 default 2>/dev/null || true

# Pull binary packages from the matching NetBSD release repo. ftp.netbsd.org no
# longer carries 9.x packages, which is what triggered building this box in the
# first place.
export PKG_PATH="https://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/amd64/10.1/All/"

# Network sanity. Hard-timeout each probe so we never silently hang.
echo "=== sanity ==="
ifconfig vioif0 | grep -E 'inet |status' || true
cat /etc/resolv.conf || true
echo "--- https probe ---"
timeout 20 ftp -V -o - "https://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/amd64/10.1/All/" 2>&1 | head -10 || echo "https probe exit $?"
echo "--- http probe ---"
timeout 20 ftp -V -o - "http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/amd64/10.1/All/" 2>&1 | head -10 || echo "http probe exit $?"
echo "=== /sanity ==="

# Install rsync (the reason this box exists) plus the usual vagrant box bits.
pkg_add -v sudo rsync bash curl

# Sudo for the vagrant user.
cat >> /usr/pkg/etc/sudoers <<'EOF'

Defaults:vagrant !requiretty
vagrant ALL=(ALL) NOPASSWD: ALL
EOF

# Vagrant user. No password set, key-only login. NetBSD's useradd defaults
# primary group to the username, so the group has to exist first.
groupadd vagrant
useradd -m -g vagrant -G wheel -s /usr/pkg/bin/bash vagrant

mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
ftp -o /home/vagrant/.ssh/authorized_keys \
    https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Shrink the disk image post-processor will see.
rm -rf /tmp/* /var/tmp/*
dd if=/dev/zero of=/tmp/zero bs=1m 2>/dev/null || true
rm -f /tmp/zero

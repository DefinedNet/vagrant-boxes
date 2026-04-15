#!/bin/sh
set -eux

# Install sudo
pkg_add -I sudo--

# Configure sudo for vagrant user
mkdir -p /etc/sudoers.d
cat > /etc/sudoers <<EOF
#includedir /etc/sudoers.d
EOF
cat > /etc/sudoers.d/vagrant <<EOF
Defaults:vagrant !requiretty
vagrant ALL=(ALL) NOPASSWD: ALL
EOF
chmod 440 /etc/sudoers /etc/sudoers.d/vagrant

# Configure SSH
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#UseDNS.*/UseDNS no/' /etc/ssh/sshd_config

# Install vagrant insecure public key
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
ftp -o /home/vagrant/.ssh/authorized_keys https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Install useful packages
pkg_add -I bash curl

# Clean up
pkg_delete -a
rm -rf /tmp/*
dd if=/dev/zero of=/tmp/zero bs=1m 2>/dev/null || true
rm -f /tmp/zero

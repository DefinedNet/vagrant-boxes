#!/bin/sh
set -eux

# Configure sudo for vagrant user
echo "vagrant ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vagrant
chmod 440 /etc/sudoers.d/vagrant

# Configure SSH
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#UseDNS.*/UseDNS no/' /etc/ssh/sshd_config

# Install vagrant insecure public key
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
wget -q -O /home/vagrant/.ssh/authorized_keys https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Clean up
apt-get clean
rm -rf /tmp/*
dd if=/dev/zero of=/tmp/zero bs=1M 2>/dev/null || true
rm -f /tmp/zero

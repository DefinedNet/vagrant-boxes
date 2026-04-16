#!/bin/sh
set -eux

# Install vagrant insecure public key (preseed already did this but ensure it's present)
sudo mkdir -p /home/vagrant/.ssh
sudo chmod 700 /home/vagrant/.ssh
sudo wget -q -O /home/vagrant/.ssh/authorized_keys https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub
sudo chmod 600 /home/vagrant/.ssh/authorized_keys
sudo chown -R vagrant:vagrant /home/vagrant/.ssh

# Clean up
sudo apt-get clean
sudo rm -rf /tmp/*
sudo dd if=/dev/zero of=/tmp/zero bs=1M 2>/dev/null || true
sudo rm -f /tmp/zero

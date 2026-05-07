packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
    vagrant = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "version" {
  type    = string
  default = "10.1"
}

# Disk image produced by scripts/anita-install.sh. Anita drives sysinst over
# the console to install NetBSD into wd0.img, then boots the result once with
# --persist to install the vagrant insecure public key for root and enable
# sshd. Packer takes over from there over SSH.
variable "base_image" {
  type    = string
  default = "anita-work/wd0.qcow2"
}

variable "ssh_private_key_file" {
  type    = string
  default = "anita-work/vagrant"
}

source "qemu" "netbsd10" {
  iso_url              = var.base_image
  iso_checksum         = "none"
  disk_image           = true
  use_backing_file     = true
  ssh_username         = "root"
  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout          = "15m"
  shutdown_command     = "/sbin/shutdown -p now"
  disk_size            = "20G"
  memory               = 2048
  cpus                 = 2
  headless             = true
  vnc_port_min         = 5950
  vnc_port_max         = 5950
  accelerator          = "kvm"
  format               = "qcow2"

  boot_wait = "30s"
}

build {
  sources = ["source.qemu.netbsd10"]

  provisioner "shell" {
    script = "scripts/provision.sh"
  }

  post-processor "vagrant" {
    output = "netbsd10-libvirt.box"
  }
}

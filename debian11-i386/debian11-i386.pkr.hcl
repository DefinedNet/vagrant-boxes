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

variable "iso_url" {
  type    = string
  default = "https://cdimage.debian.org/cdimage/archive/11.11.0/i386/iso-cd/debian-11.11.0-i386-netinst.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:cc7bb888562a02e9f49bc93233c49be1f2decdb9934bd5b805f114a4eeb9e052"
}

source "qemu" "debian11-i386" {
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  ssh_timeout      = "30m"
  shutdown_command = "sudo /sbin/shutdown -h now"
  disk_size        = "20G"
  memory           = 2048
  cpus             = 2
  headless         = true
  vnc_port_min     = 5950
  vnc_port_max     = 5950
  accelerator      = "kvm"
  format           = "qcow2"
  machine_type     = "pc"
  disk_interface   = "ide"
  qemuargs         = [
    ["-serial", "file:serial.log"],
  ]

  http_directory = "http"

  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<enter>",
  ]
}

build {
  sources = ["source.qemu.debian11-i386"]

  provisioner "shell" {
    script = "scripts/provision.sh"
  }

  post-processor "vagrant" {
    output = "debian11-i386-libvirt.box"
  }
}

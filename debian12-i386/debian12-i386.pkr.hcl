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
  default = "https://cdimage.debian.org/cdimage/archive/12.13.0/i386/iso-cd/debian-12.13.0-i386-netinst.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:61e5dbec68c511713611ffec58e40ba26c76487864b7dddfc59f8e55bacbe56a"
}

source "qemu" "debian12-i386" {
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
    ["-cpu", "EPYC-Rome"],
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
  sources = ["source.qemu.debian12-i386"]

  provisioner "shell" {
    script = "scripts/provision.sh"
  }

  post-processor "vagrant" {
    output = "debian12-i386-libvirt.box"
  }
}

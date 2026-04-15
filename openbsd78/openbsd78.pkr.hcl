packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "version" {
  type    = string
  default = "7.8"
}

variable "iso_url" {
  type    = string
  default = "https://cdn.openbsd.org/pub/OpenBSD/7.8/amd64/install78.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:a228d0a1ef558b4d9ec84c698f0d3ffd13cd38c64149487cba0f1ad873be07b2"
}

source "virtualbox-iso" "openbsd78" {
  guest_os_type    = "OpenBSD_64"
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  ssh_username     = "root"
  ssh_password     = "vagrant"
  ssh_timeout      = "30m"
  shutdown_command = "halt -p"
  disk_size        = 20000
  memory           = 2048
  cpus             = 2
  headless         = true

  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--nat-localhostreachable1", "on"]
  ]

  http_directory = "http"

  boot_wait = "30s"
  boot_command = [
    "A<enter>",
    "<wait10>",
    "http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.conf<enter>",
  ]
}

build {
  sources = ["source.virtualbox-iso.openbsd78"]

  provisioner "shell" {
    script = "scripts/provision.sh"
  }

  post-processor "vagrant" {
    output = "openbsd78-virtualbox.box"
  }
}

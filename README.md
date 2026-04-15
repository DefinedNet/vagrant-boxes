# vagrant-boxes

Packer templates for building Vagrant boxes used by the nebula smoke tests.

## Boxes

### OpenBSD 7.8 (amd64, libvirt)

Minimal OpenBSD 7.8 box with vagrant user, sudo, and SSH configured.

```sh
cd openbsd78
packer init openbsd78.pkr.hcl
packer build openbsd78.pkr.hcl
```

Produces `openbsd78-libvirt.box`.

### Debian 12 i386 (libvirt)

Minimal 32-bit Debian 12 box for testing i386 binaries. Uses extlinux as the bootloader because GRUB hangs on i386 under QEMU.

```sh
cd debian12-i386
packer init debian12-i386.pkr.hcl
packer build debian12-i386.pkr.hcl
```

Produces `debian12-i386-libvirt.box`.

## Building locally

Requires KVM. Both boxes use QEMU with KVM acceleration.

To add a box locally without publishing:

```sh
vagrant box add --name DefinedNet/<box-name> <box-file>.box
```

## CI

Boxes are built automatically via GitHub Actions on pushes to `main` and published to the HCP Vagrant Registry as `DefinedNet/<box-name>`.

Requires `HCP_CLIENT_ID` and `HCP_CLIENT_SECRET` repository secrets from an HCP service principal.

## Adding a new box

1. Create a directory named `<os><version>` (e.g., `netbsd10`)
2. Add a Packer template, install config, and provisioning scripts
3. Add a workflow in `.github/workflows/`

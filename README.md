# vagrant-boxes

Packer templates for building Vagrant boxes used by the nebula smoke tests.

## Boxes

### OpenBSD 7.8 (amd64, libvirt)

Minimal OpenBSD 7.8 box with vagrant user, sudo, and SSH configured.

**Build locally (requires KVM):**

```sh
cd openbsd78
packer init openbsd78.pkr.hcl
packer build openbsd78.pkr.hcl
```

Produces `openbsd78-libvirt.box`.

**Add locally (without HCP Vagrant Registry):**

```sh
vagrant box add --name DefinedNet/openbsd78 openbsd78-libvirt.box
```

## CI

Boxes are built automatically via GitHub Actions on pushes to `main` and published to the HCP Vagrant Registry as `DefinedNet/<box-name>`.

Requires `HCP_CLIENT_ID` and `HCP_CLIENT_SECRET` repository secrets from an HCP service principal.

## Adding a new box

1. Create a directory named `<os><version>` (e.g., `netbsd10`)
2. Add a Packer template, autoinstall config, and provisioning scripts
3. Add a workflow in `.github/workflows/`

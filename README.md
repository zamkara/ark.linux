<picture>
  <source media="(prefers-color-scheme: dark)" srcset="/data/assets/ic_light.svg">
  <source media="(prefers-color-scheme: light)" srcset="/data/assets/ic_dark.svg">
  <img alt="Ark Linux Logo" src="/data/assets/ic_dark.svg" width="256">
</picture>

# Vanilla Immutable Arch Linux
[![Contributing](https://img.shields.io/badge/contributions-open-brightgreen?style=flat-square)](https://github.com/zamkara/ark.linux/pulls)
[![Status](https://img.shields.io/badge/status-early%20stage-orange?style=flat-square)]()
[![Arch Linux](https://img.shields.io/badge/base-Arch%20Linux-1793D1?style=flat-square&logo=arch-linux&logoColor=white)](https://archlinux.org)
[![Podman](https://img.shields.io/badge/runtime-Podman-892CA0?style=flat-square&logo=podman&logoColor=white)](https://podman.io)
[![GNOME](https://img.shields.io/badge/desktop-GNOME-4A86CF?style=flat-square&logo=gnome&logoColor=white)](https://www.gnome.org)
[![Nix](https://img.shields.io/badge/declarative-Nix-5277C3?style=flat-square&logo=nixos&logoColor=white)](https://nixos.org)
[![Distrobox](https://img.shields.io/badge/containerized-Distrobox-000000?style=flat-square&logo=podman&logoColor=white)](https://distrobox.it)
[![Shell](https://img.shields.io/badge/shells-zsh%20|%20fish-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)]()

Build scripts 'n configs for spinnin' up a bootable Live ISO of an immutable Arch Linux env powered by OSTree 'n bootc.

<img width="1920" height="1080" alt="Screenshot from 2026-06-04 21-47-25" src="https://github.com/user-attachments/assets/bafc559d-e24f-48d7-bf8c-99adb8525217" />

Not a separate distro — underneath it's pure Arch Linux, delivered as an immutable image. Declarative package management's built right in with Nix, pin host packages alongside the system image. Distrobox is pre-configured, dev-ready outta the box — no setup needed, just use it.

> ⚠️ **Heads up — this is very early stage.** Expect bugs. Lotta 'em. For testin' only, don't run this on anythin' ya care about. Ya been warned.

## System Architecture

Three things're holdin' this together. **OSTree + bootc** handles image-based deployments — system state always matches whatcha tested in the build, no surprises. **Alga**'s the native installer; GTK4 Rust-based, async ops, real-time progress, graceful cancellation — it's got it handled. And the **CI/CD pipeline**'s automatin' everythin' else: GitHub Actions + OCI Containerfiles, push → ISO, that's it.

## What's Included

| Software | Details |
|----------|---------|
| GNOME | Full desktop environment |
| Podman + Distrobox | Pre-configured containerization |
| Nix | Declarative host package management |
| Plymouth | Boot splash screen |
| MoreWaita | Extended Adwaita icon theme |
| starship, fastfetch | Shell prompt and system info |
| zsh, fish | Alternative shells |

## Build Requirements

- `podman`
- `wget`, `curl`, `jq`
- Root (for `mkarchiso`)
- ~10GB free disk space

## Quick Start

### Buildin' the ISO

```bash
sudo bash .github/workflows/build_iso.sh
```

Output lands in `out/`.

### Testin' with QEMU

```bash
qemu-system-x86_64 -m 4096 -cdrom out/install.iso -boot d
```

### Testin' with GNOME Boxes

1. Open GNOME Boxes
2. Hit "+" → new VM
3. Point it at the ISO
4. Follow Alga's prompts

## Repository Structure

- **[ark.linux](https://github.com/zamkara/ark.linux)** ISO generation via `archiso` 'n `bootc-image-builder`
- **[ark-image](https://github.com/zamkara/ark-image)** Base container image defs 'n OS package manifests
- **[alga](https://github.com/zamkara/alga)** GTK4 Rust frontend for `bootc` install 'n system updates
- **[ark-aur](https://github.com/zamkara/ark-aur)** Custom repo for pre-compiled AUR packages

## Docs

All technical docs're livin' in `docs/`:

- **[Architecture and Vision](docs/Architecture-and-Vision.md)** Core design philosophy 'n system anatomy
- **[Bootloader Implementation](docs/Bootloader-Implementation.md)** Bootloader 'n firmware integration
- **[Installer Mechanics](docs/Installer-Mechanics.md)** Technical details of the Alga installer
- **[Builder Mechanics](docs/05-Builder-Mechanics.md)** Automated ISO generation pipeline
- **[Alga Source Code](docs/06-Alga-Source-Code.md)** Source code architecture 'n async patterns
- **[OSTree and bootc](docs/07-OSTree-and-Bootc.md)** Immutable filesystem layout 'n atomic updates
- **[Troubleshooting](docs/08-Troubleshooting.md)** Common issues 'n diagnostics
- **[Local Testing](docs/09-Local-Testing.md)** Virtualization 'n testin' guidelines

## Development

### Prerequisites

- Rust 1.70+ (for Alga builds)
- GTK4 dev libraries
- Podman (or any Containerfile-compatible runtime)

### Buildin' Locally

```bash
git clone https://github.com/zamkara/ark.linux.git
cd ark.linux

# Poke around the Containerfile first
cat Containerfile

# Optional local build
podman build -t ark-os:dev .

# Generate the ISO
sudo bash .github/workflows/build_iso.sh
```

## Installation

1. **Boot from ISO** Write it to a USB or boot directly
2. **Launch Alga** Hit "Install Ark Linux" from the boot menu
3. **Pick target drive** Choose where it's goin'
4. **Wait** Watch progress in the Alga terminal
5. **Reboot** Done. Immutable Arch, ready to go.

## Post-Installation

```bash
# Check for updates
bootc check-update

# Apply 'em — atomic, rollback-capable
bootc upgrade

# Regret it? Roll back.
bootc rollback

# Install packages on host via Nix
nix profile install nixpkgs#htop

# Drop into a full Arch container with pacman
distrobox enter arch

# Switch default shell
chsh -s /usr/bin/fish

# System info
fastfetch
```

## System Layout

```
/                          Immutable root (read-only)
├── /etc                   Config (mutable, 3-way merged on updates)
├── /var                   Variable data, user home (mutable)
├── /usr                   Immutable system binaries 'n libraries
└── /opt                   Additional immutable applications
```

## Powered by

- **[DistroShelf](https://github.com/ranfdev/DistroShelf)** GTK4 GUI for Distrobox — shaped how Distrobox integration's hangin' together in-session
- **[MoreWaita](https://github.com/somepaulo/MoreWaita)** Expanded Adwaita icon theme — keepin' the desktop consistent 'n cohesive outta the box
- **[nixpkgs](https://github.com/nixos/nixpkgs)** The Nix package collection — powerin' declarative host package management

## Credits

Buildin' on the work of:

- **[Fedora Silverblue](https://silverblue.fedoraproject.org/)** Pioneer of container-native Linux desktops
- **[Arch Linux](https://archlinux.org/)** The base. The goat.
- **[OSTree](https://ostreedev.github.io/ostree/)** Git-like versioning for OS binaries
- **[bootc](https://github.com/containers/bootc)** Container-to-bootable-system magic
- **[GNOME](https://www.gnome.org/)** Desktop env 'n dev libraries

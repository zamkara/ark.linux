<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/zamkara/ark.linux/main/assets/ic_dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/zamkara/ark.linux/main/assets/ic_light.svg">
  <img alt="Ark Linux Logo" src="https://raw.githubusercontent.com/zamkara/ark.linux/main/assets/ic_light.svg" width="512">
</picture>

# Ark: Immutable Arch Linux Builder

Build scripts and configurations for generating a bootable Live ISO of an immutable Arch Linux environment powered by OSTree and bootc technology.

This project packages vanilla Arch Linux into an OSTree/bootc-compatible container image and provides an ISO for seamless installation. It is not a separate distribution—the underlying system remains strictly Arch Linux, enhanced with modern container-native deployment mechanisms.

## Features

- 🔒 **Immutable Root Filesystem** - Read-only base system with atomic updates
- 📦 **Container-Native** - OSTree + bootc for reliable, reproducible deployments
- 🎨 **Native GTK4 Installer** - Modern `alga` installer built with Rust and Libadwaita
- 🔄 **Atomic Updates** - A/B updates with automatic rollback on failure
- 📋 **Transparent Installation** - Real-time progress tracking and system logs visible to users
- 🚀 **CI/CD Automation** - Fully automated ISO generation via GitHub Actions
- 📦 **Flatpak Integration** - Sandbox third-party applications for system stability

## System Architecture

Ark Linux is built upon three primary components:

### 1. **OSTree + bootc** - Container-Native Deployments
Modern image-based deployment system ensuring system state matches tested build artifacts.

### 2. **Alga** - Native Installer  
GTK4 Rust-based installer with asynchronous operations, real-time progress extraction, and graceful cancellation handling.

### 3. **CI/CD Pipeline** - Automated ISO Generation
Fully automated build process leveraging GitHub Actions and OCI Containerfiles to generate bootable ISO artifacts.

## Build Requirements

- `podman`
- `wget`, `curl`, `jq`
- Root privileges (for `mkarchiso`)
- Sufficient disk space (~10GB for build artifacts)

## Quick Start

### Building the ISO

```bash
sudo bash .github/workflows/build_iso.sh
```

The resulting ISO will be located in the `out/` directory.

### Testing with QEMU

```bash
qemu-system-x86_64 -m 4096 -cdrom out/install.iso -boot d
```

### Testing with GNOME Boxes

1. Open GNOME Boxes
2. Click "+" to create a new virtual machine
3. Select the generated ISO file
4. Follow the Alga installer prompts

## Repository Structure

- **[ark.linux](https://github.com/zamkara/ark.linux)** - ISO generation using `archiso` and `bootc-image-builder`
- **[ark-image](https://github.com/zamkara/ark-image)** - Base container image definitions and OS package manifests
- **[alga](https://github.com/zamkara/alga)** - GTK4 Rust frontend for `bootc` installation and system updates
- **[ark-aur](https://github.com/zamkara/ark-aur)** - Custom repository for pre-compiled AUR packages

## Documentation

Comprehensive technical documentation is available in the `docs/` directory:

- **[Architecture and Vision](docs/Architecture-and-Vision.md)** - Core design philosophy and system anatomy
- **[Bootloader Implementation](docs/Bootloader-Implementation.md)** - Bootloader and firmware integration
- **[Installer Mechanics](docs/Installer-Mechanics.md)** - Technical details of the Alga installer
- **[Builder Mechanics](docs/05-Builder-Mechanics.md)** - Automated ISO generation pipeline
- **[Alga Source Code](docs/06-Alga-Source-Code.md)** - Source code architecture and async patterns
- **[OSTree and bootc](docs/07-OSTree-and-Bootc.md)** - Immutable filesystem layout and atomic updates
- **[Troubleshooting](docs/08-Troubleshooting.md)** - Common issues and diagnostics
- **[Local Testing](docs/09-Local-Testing.md)** - Virtualization and testing guidelines

## Development

### Prerequisites

- Rust 1.70+ (for Alga installer builds)
- GTK4 development libraries
- Containerfile-compatible runtime (podman recommended)

### Building Locally

```bash
# Clone the repository
git clone https://github.com/zamkara/ark.linux.git
cd ark.linux

# Review the Containerfile structure
cat Containerfile

# Build with podman (optional for development)
podman build -t ark-os:dev .

# Generate ISO
sudo bash .github/workflows/build_iso.sh
```

## Installation Guide

1. **Boot from ISO** - Write the ISO to a USB drive or boot directly
2. **Launch Alga** - Select "Install Ark Linux" from the boot menu
3. **Select Target Drive** - Choose your installation destination
4. **Wait for Completion** - Monitor progress in the Alga terminal
5. **Reboot** - System will restart with immutable Arch Linux ready to use

## Post-Installation

After installation, update your system:

```bash
# Check available updates
bootc check-update

# Apply updates (atomic, with rollback capability)
bootc upgrade

# Rollback if needed
bootc rollback
```

## System Layout

```
/                          - Immutable root (read-only)
├── /etc                   - Configuration (mutable, 3-way merged on updates)
├── /var                   - Variable data, user home (mutable)
├── /usr                   - Immutable system binaries and libraries
└── /opt                   - Additional immutable applications
```

## Credits & Inspiration

This project draws inspiration from and builds upon the excellent work of:

- **[Fedora Silverblue](https://silverblue.fedoraproject.org/)** - Pioneer of container-native Linux desktop environments
- **[Arch Linux](https://archlinux.org/)** - Powerful and flexible Linux distribution with excellent package management
- **[OSTree](https://ostreedev.github.io/ostree/)** - Git-like versioning for OS binaries
- **[bootc](https://github.com/containers/bootc)** - Container-to-bootable-system tool
- **[GNOME](https://www.gnome.org/)** - Modern desktop environment and development libraries

## License

This project and all its contents are proprietary intellectual property of Zamkara.

Unauthorized copying, distribution, modification, reverse engineering, or use of any files within this repository, via any medium, is strictly prohibited without explicit written permission from the author.

---

**Note:** For questions, bug reports, or feature requests, please open an issue on GitHub or contact the maintainers directly.

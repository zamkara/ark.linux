# Builder Mechanics and Automated ISO Generation

This document explains the infrastructure responsible for compiling and generating ark linux. The operating system is fully automated and constructed via GitHub Actions and OCI Containerfiles, eliminating manual build errors.

## 1. The Containerfile Architecture
The `Containerfile` dictates the exact composition of the operating system. Unlike traditional Linux distributions that assemble the OS via prolonged `chroot` scripts during installation, ark linux is pre-assembled as a container image.

Key phases within the `Containerfile`:
- **Base Image Acquisition:** `FROM ghcr.io/zamkara/ark.linux:ark-nvidia:latest`. This utilizes a pre-configured Arch Linux base image containing proprietary NVIDIA drivers and the default desktop environment provided by the upstream maintainers.
- **Local Dependency Injection:** `COPY aur-packages/*.pkg.tar.zst /tmp/`. Custom, locally compiled AUR packages (including the Alga installer itself) are injected directly into the container filesystem.
- **Critical Subsystem Installation:**
  The current `Containerfile` installs a broader set of packages covering the full OSTree stack, GNOME desktop, and developer tooling. Key groups include:

  - **OSTree / bootc stack:** `ostree skopeo composefs bootc`
  - **Container runtime:** `podman distrobox`
  - **Desktop environment:** `gnome-shell gnome-control-center gdm plymouth gnome-console`
  - **Tooling:** `nix git base-devel util-linux openssl efibootmgr dosfstools e2fsprogs xfsprogs btrfs-progs ibus iso-codes shadow sudo nano fastfetch zsh fish starship github-cli`

  Note that `pacman` is intentionally removed from the final image — the host is immutable and changes via pacman would be lost on redeploy. **Nix** is pre-installed for declarative host package management, and **Distrobox** provides access to a full Arch container with pacman when needed.
- **Bootloader Configuration:** In alignment with the native bootloader implementation, `bootupd` dependency handling is minimized, and the image is prepared for native `systemd-boot` initialization during the hardware installation phase.

## 2. GitHub Actions Workflow (`build-iso.yml`)
The cloud-based CI/CD pipeline automates the conversion of the `Containerfile` into a bootable ISO.
- **Trigger:** Initiated upon pushing commits to the primary GitHub repository.
- **Phase 1: Image Construction:** The GitHub Actions runner executes `podman build -t ark-os .`, interpreting the `Containerfile` to construct the OCI image.
- **Phase 2: ISO Generation:** The workflow utilizes the official `bootc-image-builder` utility to ingest the assembled OCI container image and transpile it into a bootable `install.iso` file format.
- **Phase 3: Artifact Distribution:** The generated ISO is securely uploaded to GitHub Releases or Actions Artifacts for end-user distribution.

## 3. The Container-Native Advantage
This architecture guarantees dependency integrity. If a package build fails or a repository is unreachable, the `podman build` process will fail in the CI pipeline. Consequently, corrupted ISOs are never compiled or distributed. This mathematically ensures that every downloaded ISO is structurally verified before release.

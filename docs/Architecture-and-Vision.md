# Architecture and Vision

This document outlines the core architecture and development philosophy of ark linux, providing a foundational understanding for all contributors.

## Core Vision
ark linux is designed as a modern, image-based operating system. The core philosophy centers on immutability, reliable rollbacks, and a container-native distribution model. The objective is to provide a system where the root filesystem is read-only by default, ensuring that the OS state remains predictable and identical to the tested build artifacts.

## System Anatomy

ark linux is built upon three primary components:

### 1. OSTree and Container-Native Deployments (bootc)
ark linux is distributed as an OCI container image rather than a traditional package repository. 
Using `bootc` (Bootable Containers), the OCI image is fetched and deployed directly to the filesystem using OSTree architecture. This ensures atomic updates and guarantees that the deployed system is bit-for-bit identical to the image generated in the CI/CD pipeline.

### 2. Alga: The Native Installer
Instead of relying on generic installers like Calamares, ark linux utilizes a custom-built installer named **Alga**.
- **Technology Stack:** Written in Rust, utilizing the `tokio` asynchronous runtime for high-performance, non-blocking execution.
- **User Interface:** Built with GTK4 and Libadwaita to provide a modern, responsive, and seamless graphical experience.
- **Responsibilities:** Alga handles disk partitioning (BTRFS), executes the `bootc install to-disk` routine, parses backend logs for progress tracking, and natively configures the system bootloader.

### 3. CI/CD Pipeline (Automated ISO Generation)
The entire OS generation process is automated. The base image resides at `ghcr.io/zamkara/ark.linux:ark-nvidia:latest`. The `ark.linux` repository utilizes a `Containerfile` to layer local dependencies (e.g., AUR packages) on top of the base image, compiles the Alga installer, and relies on GitHub Actions to securely package the final `.iso` artifact.

### 4. Pre-Built Package Management (Nix + Distrobox)
Since the host filesystem is immutable (`/usr` read-only), traditional Arch package management via `pacman` is unavailable on the host. Two alternatives come pre-installed:

- **Nix** — declarative, per-user package management for the host. Use `nix profile install nixpkgs#<package>` to install software alongside the system image. Packages are stored in `/nix` and survive image updates.
- **Distrobox** — spins up a full Arch Linux container with pacman inside. Run `distrobox enter arch` for a seamless terminal session where `sudo pacman -S` works as expected. The container shares the host home directory and integrates with the desktop environment.

This approach keeps the host lean and atomic while giving users full access to the Arch ecosystem when needed.

### 5. Default Browser (Helium)
The image ships with **Helium** — a de-Googled, privacy-focused Chromium fork from [imputnet/helium-linux](https://github.com/imputnet/helium-linux). It is installed in all variants via ark-aur and updates automatically on the Mon/Wed/Fri ark-aur rebuild cycle.

### 6. Developer Tooling (Pre-Installed)
The image ships with a curated set of developer tools to be productive immediately:
- **Shells:** `zsh` and `fish` with `starship` prompt pre-configured
- **Tools:** `git`, `nano`, `fastfetch`, `github-cli`
- **Build:** `base-devel` for compiling packages

## Architectural Advantages
By adopting a container-native approach, ark linux eliminates traditional dependency resolution failures on the client side. If a package build fails, it fails in the GitHub Actions pipeline, preventing broken images from ever reaching the end user.

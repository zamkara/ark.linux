# Architecture and Vision

This document outlines the core architecture and development philosophy of Apollo OS, providing a foundational understanding for all contributors.

## Core Vision
Apollo OS is designed as a modern, image-based operating system. The core philosophy centers on immutability, reliable rollbacks, and a container-native distribution model. The objective is to provide a system where the root filesystem is read-only by default, ensuring that the OS state remains predictable and identical to the tested build artifacts.

## System Anatomy

Apollo OS is built upon three primary components:

### 1. OSTree and Container-Native Deployments (bootc)
Apollo OS is distributed as an OCI container image rather than a traditional package repository. 
Using `bootc` (Bootable Containers), the OCI image is fetched and deployed directly to the filesystem using OSTree architecture. This ensures atomic updates and guarantees that the deployed system is bit-for-bit identical to the image generated in the CI/CD pipeline.

### 2. Alga: The Native Installer
Instead of relying on generic installers like Calamares, Apollo OS utilizes a custom-built installer named **Alga**.
- **Technology Stack:** Written in Rust, utilizing the `tokio` asynchronous runtime for high-performance, non-blocking execution.
- **User Interface:** Built with GTK4 and Libadwaita to provide a modern, responsive, and seamless graphical experience.
- **Responsibilities:** Alga handles disk partitioning (BTRFS), executes the `bootc install to-disk` routine, parses backend logs for progress tracking, and natively configures the system bootloader.

### 3. CI/CD Pipeline (Automated ISO Generation)
The entire OS generation process is automated. The base image resides at `ghcr.io/apollo-linux/apollo-nvidia:latest`. The `apollo.builder` repository utilizes a `Containerfile` to layer local dependencies (e.g., AUR packages) on top of the base image, compiles the Alga installer, and relies on GitHub Actions to securely package the final `.iso` artifact.

## Architectural Advantages
By adopting a container-native approach, Apollo OS eliminates traditional dependency resolution failures on the client side. If a package build fails, it fails in the GitHub Actions pipeline, preventing broken images from ever reaching the end user.

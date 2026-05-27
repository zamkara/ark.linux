# Apollo OS Documentation

Welcome to the official documentation for Apollo OS. This repository contains the technical blueprints, architecture decisions, and operational guidelines that define the project.

This knowledge base serves as a permanent reference for developers and contributors to ensure consistency and prevent the loss of critical context.

## Table of Contents

1. **[Architecture and Vision](Architecture-and-Vision.md)**
   An overview of the Apollo OS architecture, combining OSTree, bootc containers, and the custom GTK4 Rust installer (`alga`).
   
2. **[Bootloader Implementation](Bootloader-Implementation.md)**
   Documentation detailing the technical decisions regarding the bootloader, specifically the transition from upstream `bootupd` to a native `bootctl install` approach via the installer.

3. **[Installer Mechanics](Installer-Mechanics.md)**
   A technical breakdown of the `alga` installer, covering robust partition management (btrfs locks), cancellation handling (disk zeroing), and progress extraction.

4. **[Git Workflow and Remotes](Git-Workflow-and-Remotes.md)**
   Guidelines on the repository's dual-remote structure (GitLab and GitHub) and the primary pipeline triggers.

5. **[Builder Mechanics](05-Builder-Mechanics.md)**
   A deep dive into the `Containerfile` and the GitHub Actions workflow responsible for automated ISO generation.

6. **[Alga Source Code](06-Alga-Source-Code.md)**
   An architectural review of the `/src/main.rs` codebase, explaining the asynchronous execution model (Tokio) and GTK4 UI thread management.

7. **[OSTree and Bootc](07-OSTree-and-Bootc.md)**
   A comprehensive guide to the immutable filesystem layout, atomic A/B updates, and derived container images.

8. **[Troubleshooting](08-Troubleshooting.md)**
   Diagnostic procedures for kernel locks, boot failures, and accessing emergency TTY consoles during installation.

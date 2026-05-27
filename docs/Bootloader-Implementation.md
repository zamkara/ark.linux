# Bootloader Implementation

This document details the engineering decisions behind Apollo OS's bootloader installation process, specifically the shift from `bootupd` to a native `bootctl` approach.

## Background Context
By default, the `bootc` utility delegates bootloader installation and configuration to a backend service called `bootupd`. However, `bootupd` was primarily designed for Fedora-based systems and expects specific bootloader binaries and cryptographic signatures (e.g., `shim` for Secure Boot).

Apollo OS is based on **Arch Linux**, which ships standard, unsigned `systemd-boot` EFI binaries (`systemd-bootx64.efi`). 

## Technical Challenges with `bootupd`
During development, integrating Arch Linux's `systemd-boot` with `bootupd` proved incompatible:
1. **Metadata Generation Failures:** Running `bootupctl backend generate-update-metadata` within the build environment resulted in internal assertion panics (`assertion failed: efi_components.len() > 1`).
2. **Path Hardcoding:** System tracing (`strace`) revealed that `bootupd` is strictly hardcoded to search for EFI components in paths specific to Fedora OSTree deployments, rejecting generic Arch Linux EFI structures.
3. **Previous Workarounds:** Initial attempts to bypass this involved creating placeholder GRUB configurations in the `Containerfile`. While this allowed the build to pass, it resulted in empty EFI partitions during hardware installation, rendering the system unbootable.

## The Native Implementation
To ensure a robust and reliable boot sequence, Apollo OS completely bypasses the incompatible `bootupd` implementation in favor of a native approach.

**The Current Workflow:**
1. **Container Cleanup:** All placeholder bootloader configurations and `bootupctl` commands have been removed from the `Containerfile` to maintain image purity.
2. **Bootc Delegation:** During installation, the Alga installer explicitly instructs `bootc` to skip bootloader management by passing the `--bootloader none` argument.
3. **Native Installation:** Immediately after `bootc` successfully deploys the root filesystem, the Alga installer assumes control. It dynamically locates the EFI System Partition (via GUID `c12a7328-f81f-11d2-ba4b-00a0c93ec93b`), mounts it, and executes the native `bootctl install --esp-path=...` command.

**Result:** Apollo OS utilizes a pure, native `systemd-boot` implementation that fully complies with the Boot Loader Specification (BLS) and integrates seamlessly with OSTree deployments without relying on fragile workarounds.

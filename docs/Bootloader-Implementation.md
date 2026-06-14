# Bootloader Implementation

This document details the engineering decisions behind ark linux's bootloader installation process, specifically the shift from `bootupd` to a native `bootctl` approach.

## Background Context
By default, the `bootc` utility delegates bootloader installation and configuration to a backend service called `bootupd`. However, `bootupd` was primarily designed for Fedora-based systems and expects specific bootloader binaries and cryptographic signatures (e.g., `shim` for Secure Boot).

ark linux is based on **Arch Linux**, which ships standard, unsigned `systemd-boot` EFI binaries (`systemd-bootx64.efi`). 

## Technical Challenges with `bootupd`
During development, integrating Arch Linux's `systemd-boot` with `bootupd` proved incompatible:
1. **Metadata Generation Failures:** Running `bootupctl backend generate-update-metadata` within the build environment resulted in internal assertion panics (`assertion failed: efi_components.len() > 1`).
2. **Path Hardcoding:** System tracing (`strace`) revealed that `bootupd` is strictly hardcoded to search for EFI components in paths specific to Fedora OSTree deployments, rejecting generic Arch Linux EFI structures.
3. **Previous Workarounds:** Initial attempts to bypass this involved creating placeholder GRUB configurations in the `Containerfile`. While this allowed the build to pass, it resulted in empty EFI partitions during hardware installation, rendering the system unbootable.

## The Native Implementation
To ensure a robust and reliable boot sequence, ark linux completely bypasses the incompatible `bootupd` implementation in favor of a native approach.

**The Current Workflow:**
1. **Container Cleanup:** All placeholder bootloader configurations and `bootupctl` commands have been removed from the `Containerfile` to maintain image purity.
2. **Bootc Delegation:** During installation, the Alga installer explicitly instructs `bootc` to skip bootloader management by passing the `--bootloader none` argument.
3. **Native Installation:** Immediately after `bootc` successfully deploys the root filesystem, the Alga installer assumes control. It dynamically locates the EFI System Partition (via GUID `c12a7328-f81f-11d2-ba4b-00a0c93ec93b`), mounts it, and executes the native `bootctl install --esp-path=...` command.

**Result:** ark linux utilizes a pure, native `systemd-boot` implementation that fully complies with the Boot Loader Specification (BLS) and integrates seamlessly with OSTree deployments without relying on fragile workarounds.

## BLS Entry Management (`bls-sync.sh`)

Boot entries are not managed by bootc or ostree directly. Instead, a custom script `bls-sync.sh` (embedded in Alga as `BLS_SYNC_SCRIPT` and also at `ark-image/.github/bls-sync.sh`) handles all entry lifecycle:

- **Discovery:** Reads all deployments directly from `$DEPLOY_BASE/` via `ls -d` (primary), falling back to `ostree admin status`. Using the filesystem directly ensures staged and rollback deployments are always included.
- **Entry naming:** `Arch Linux YYYYMMDDHHMMSS` derived from the deployment directory's modification time.
- **Cleanup:** Removes entries for deployments no longer on disk, and removes any auto-generated `ostree:` entries.
- **boot.0 symlink:** Creates `/sysroot/ostree/boot.0/default/$bootcsum/$bootserial` required by `ostree-prepare-root`.
- **Runs:** On every boot (`ark-bls-sync.service`), and after every upgrade (`bootc-finalize-staged.service.d/bls-sync.conf`).

**Important:** `BLS_SYNC_SCRIPT` in `alga/src/main.rs` and `ark-image/.github/bls-sync.sh` must always be kept identical. When calling via `pkexec`, env vars (`SYSROOT`, `ESP`) must be embedded inline (`export SYSROOT=...; export ESP=...; <script>`) since `pkexec` strips environment variables.

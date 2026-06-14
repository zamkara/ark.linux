# Installer Mechanics (Alga)

The Alga installer manages the low-level complexities of the installation process while providing a seamless user experience. The following sections detail the core mechanisms implemented in `src/main.rs`.

## 1. Disk Partitioning

Alga is **UEFI only** — no legacy BIOS/MBR support. The installer uses `sfdisk` to create a GPT partition table with exactly 2 partitions:

| # | Size | Type | Filesystem | Label |
|---|------|------|------------|-------|
| 1 | 1024 MiB | EFI System (`C12A7328-...`) | FAT32 | `EFI-SYSTEM` |
| 2 | Remaining | Linux filesystem (`0FC63DAF-...`) | btrfs | `root` |

Partition detection uses `lsblk -rno PATH` with `grep -vxF` (exact whole-line match) to exclude the disk itself, then `sort` to get stable ordering by position.

## 2. Btrfs Subvolumes

After formatting, Alga creates 8 btrfs subvolumes before running `bootc install to-filesystem`:

| Subvolume | Mount Point | Notes |
|-----------|------------|-------|
| `@` | `/` | Root — managed by OSTree |
| `@var` | `/var` | Persistent state (home, logs, etc.) |
| `@var-log` | `/var/log` | Logs — excluded from snapshots |
| `@var-cache` | `/var/cache` | Cache — excluded from snapshots |
| `@var-tmp` | `/var/tmp` | Volatile temp |
| `@tmp` | `/tmp` | Volatile temp |
| `@snapshots` | `/.snapshots` | Timeshift snapshot target |
| `@opt` | `/opt` | Optional software |

All subvolumes are mounted with `compress=zstd,noatime`. Mount order matters: `@var` is mounted before its children (`@var-log`, `@var-cache`, `@var-tmp`) so mountpoints are created inside `@var`, not inside `@`.

fstab entries for all subvolumes (except `/` — handled by `ostree-prepare-root`) are written to the deployment's `/etc/fstab` post-install.

## 3. OS Installation

After all subvolumes are mounted:

```
bootc install to-filesystem --source-imgref docker://<variant> --bootloader none /mnt
```

The `--bootloader none` flag delegates all bootloader management to Alga (see Bootloader-Implementation.md).

## 4. Log Sanitization and Progress Extraction

The backend `bootc` process generates verbose technical output. Alga implements `sanitize_log` to process this stream:
- Scans for percentage patterns to update the UI window title dynamically.
- Suppresses irrelevant I/O metrics and low-level subsystem logs.
- Translates technical phases into user-friendly status messages.

## 5. Kernel Cache Management (Anti-Device Busy)

Prior to partitioning, Alga executes `btrfs device scan --forget` to flush cached block device mappings, ensuring the target drive is unlocked and ready.

## 6. Orphan Process Management

Alga aggressively cleans the process tree by issuing `killall -9 bootc skopeo` at the beginning of every installation sequence and during cancellation, guaranteeing a clean operational state.

## 7. Cancellation Protocol (Zeroing Sequence)

Upon receiving a cancellation signal, Alga:
1. Terminates the active installation thread.
2. Executes recursive lazy unmounting (`umount -l`) on all subvolume mounts and ESP.
3. Runs `wipefs -af` to erase all filesystem signatures.
4. Executes `dd if=/dev/zero of=<DISK> bs=1M count=10` to destroy GPT structures.
5. Issues `partprobe` to force the kernel to re-read the cleared partition table.
</content>
</invoke>
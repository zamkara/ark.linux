# Installer Mechanics (Alga)

The Alga installer is engineered to manage the low-level complexities of the installation process while providing a seamless user experience. The following sections detail the core mechanisms implemented in `src/main.rs`.

## 1. Log Sanitization and Progress Extraction
The backend `bootc` process generates verbose, highly technical standard output. Presenting this raw data directly to the end user is suboptimal.

Alga implements a custom `sanitize_log` function to process this output:
- It intercepts stdout stream lines asynchronously via `tokio::process`.
- It scans for percentage patterns (e.g., `[=====] 45%`) to extract numeric progress data, which is then used to update the UI window title dynamically.
- It utilizes a blacklist to suppress irrelevant I/O metrics and low-level subsystem logs.
- It translates technical phases into user-friendly status messages (e.g., translating "initializing ostree layout" to "Initializing immutable system layout...").

## 2. Kernel Cache Management (Anti-Device Busy)
Linux kernel filesystems (specifically BTRFS) frequently cache block device layouts. Attempting to overwrite a cached device often triggers a `Device or resource busy` error, halting the installation.

**Implementation:**
Prior to initiating the `bootc install to-disk` command, Alga executes `btrfs device scan --forget`. This forces the kernel to flush cached block device mappings, ensuring the target drive is unlocked and ready for partitioning.

## 3. Orphan Process Management
Interruptions or failures during the installation process can leave `bootc` or `skopeo` processes orphaned in the background, consuming memory and locking target drives.

**Implementation:**
Alga aggressively cleans the process tree by issuing `killall -9 bootc skopeo` at the beginning of an installation sequence and during cancellation protocols, guaranteeing a clean operational state.

## 4. Cancellation Protocol (Zeroing Sequence)
When a user cancels an installation, the system must revert the target drive to a pristine, unallocated state. Leaving partially written partition tables is unacceptable.

**Implementation:**
Upon receiving a cancellation signal, Alga executes the following sequence:
1. Terminates the active installation thread.
2. Executes recursive lazy unmounting (`umount -l`) to release filesystem locks.
3. Runs `wipefs -af` to securely erase filesystem signatures and magic strings.
4. Executes `dd if=/dev/zero of=<DISK> bs=1M count=10` to physically overwrite the first 10 Megabytes of the drive, destroying both Master Boot Record (MBR) and GUID Partition Table (GPT) structures.
5. Issues `partprobe` to force the kernel to re-read the cleared partition table.

This protocol ensures that a canceled installation leaves the drive strictly unformatted.

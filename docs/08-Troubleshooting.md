# Troubleshooting and Debugging Guide

Operating system development at the container level introduces unique failure states, including kernel panics, bootloops, and block device locks. This guide details standard operating procedures for resolving these critical issues.

## 1. Resolving "Device or resource busy" (BTRFS Cache Locks)
If the installation fails because the target disk refuses to unmount, it is highly likely that the BTRFS kernel module has locked the block device mapping.
**Emergency Procedure:**
1. Execute from the host or installer terminal: `btrfs device scan --forget`
2. Follow up with recursive lazy unmounting: `for p in /dev/sda*; do umount -l $p; done`
3. Force block identity erasure: `wipefs -af /dev/sda*`

## 2. Bootloader Not Found (Blank Screen on Virtual Machines)
If the ISO successfully installs, but booting from the target drive results in a blank screen or a "No bootable medium" error.
**Diagnosis:**
This indicates that `systemd-boot` was not written correctly to the EFI System Partition.
**Investigation Protocol:**
- Open a terminal within the QEMU/Live ISO environment.
- Inspect the partition tree: `tree -L 4 /run/media/<user>/EFI-SYSTEM` or `tree -L 4 /run/bootc/mounts/boot/efi`.
- If the directory is empty or lacks the `systemd-bootx64.efi` binary, the Alga bootloader configuration in `main.rs` must be audited. `bootctl` likely failed to copy the necessary EFI components.

## 3. Accessing the Emergency TTY Console
If the Alga GTK4 graphical interface crashes (e.g., via a Segmentation Fault) leaving you with a blank screen and a blinking cursor, the underlying system is still operational.
**Recovery Steps:**
- Press `Ctrl + Alt + F2` or `Ctrl + Alt + F3` (In GNOME Boxes, utilize the "Send Keys" menu in the top right corner).
- This will drop you into the TTY Console.
- Login using the `root` account.
- From this interface, you can inspect system logs via `journalctl -xe` or execute `bootc install to-disk` manually to view unfiltered standard output.

## 4. Tracing Backend Execution (`strace`)
When investigating cryptic failures in binaries like `bootupctl` (e.g., unexpected Rust panics), system call tracing is the most effective diagnostic tool.
```bash
strace -e trace=file bootupctl backend generate-update-metadata /
```
This command traces all file access attempts, allowing you to identify exactly which directories the binary is attempting to access before crashing.

## 5. Restoring Git Remote Configurations
If the local repository loses its remote tracking data, restore it using the following canonical configuration:
```bash
git remote add origin https://github.com/zamkara/apollo.builder.git
git remote add gitlab git@gitlab.com:zamkara/apollo.build.git
```
**Reminder:** Always use `git push origin HEAD` to trigger automated GitHub Actions builds.

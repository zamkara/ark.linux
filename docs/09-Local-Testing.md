# Local Testing and Virtualization

Testing Apollo OS locally before deploying to bare metal is a critical part of the development lifecycle. This document outlines the standard procedures for virtualized testing.

## Recommended Environment: GNOME Boxes / QEMU
Apollo OS heavily leverages modern Linux kernel features (such as BTRFS and OSTree). Virtualization tools that provide close-to-metal acceleration, like GNOME Boxes (powered by QEMU/KVM), are highly recommended over Type-2 hypervisors like VirtualBox.

### Virtual Machine Configuration
When creating a virtual machine to test the Apollo OS `.iso` artifact, ensure the following parameters are met:
1. **Firmware:** The VM must be configured to use **UEFI**. Apollo OS does not support legacy BIOS booting. Ensure OVMF (Open Virtual Machine Firmware) is active in the hypervisor settings.
2. **Storage:** Allocate a virtual block device of at least 20 GB. The installer (`alga`) expects an unallocated, unformatted drive.
3. **Memory:** Allocate a minimum of 4 GB of RAM to prevent Out-Of-Memory (OOM) errors during the intense I/O operations of the `bootc` deployment phase.

## Pre-Installation Verification
1. Boot the VM from the generated `install.iso`.
2. Once the live environment boots, open the application menu and launch the Apollo Installer.
3. Verify that the correct virtual block device (e.g., `vda` or `sda`) appears in the installer's target drive dropdown menu.

## Post-Installation Protocol
After the Alga installer reports 100% completion:
1. Shut down the virtual machine completely.
2. Remove or unmount the `install.iso` from the virtual optical drive.
3. Power on the VM. It should immediately load the `systemd-boot` menu and boot into the newly deployed OSTree root filesystem.

If the system fails to boot and displays a "No bootable device" error, refer to the [Troubleshooting Guide](08-Troubleshooting.md) to diagnose bootloader or EFI partition issues.

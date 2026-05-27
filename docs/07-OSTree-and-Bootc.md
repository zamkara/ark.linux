# OSTree and Bootc Architecture

Understanding the foundational technologies driving Apollo OS is critical for advanced development and maintenance. The filesystem structure deviates significantly from traditional package-based Linux distributions.

## 1. OSTree: "Git for Operating Systems"
OSTree is a technology designed to manage bootable, immutable, and versionable filesystem trees. It operates on the concept of content-addressable object stores, similar to Git, but optimized for operating system binaries.
- The root filesystem (`/usr`) is immutable (Read-Only) and cannot be modified via standard package managers (`pacman` or `apt`).
- The entire operating system state is stored as binary objects within `/ostree/repo`.
- During the boot process, the kernel mounts hardlinks from the object store in `/ostree` to construct the active root filesystem. This architecture ensures rapid boot times, prevents accidental user corruption, and mathematically eliminates dependency conflicts.

## 2. A/B Partitioning and Atomic Updates
Apollo OS implements atomic updates. System upgrades never overwrite the active, running filesystem.

**The Update Lifecycle:**
1. The user initiates a system update via `bootc upgrade`.
2. The `bootc` daemon fetches the latest OCI container image delta from the remote registry (`ghcr.io`) in the background.
3. `bootc` constructs a completely new filesystem tree (Deployment B) parallel to the currently running system (Deployment A). The active system remains untouched.
4. If a power failure or network interruption occurs during the download, the system state remains intact because the active deployment was never modified.
5. Upon successful verification of the new tree, `bootc` updates the Boot Loader Specification (BLS) entries in the EFI System Partition to point to the new deployment.
6. A system reboot transitions the user into the updated environment.
7. **Instant Rollbacks:** If the new update causes kernel panics or graphical failures, the user can reboot, intercept the `systemd-boot` menu, and select the previous deployment to instantly revert the system state.

## 3. Filesystem Mutability Topography
Because `/usr` is immutable, applications and user configurations must adapt to the OSTree topography.
- `/etc` (Configuration): Fully mutable. OSTree performs a 3-way merge during updates to ensure custom user configurations are preserved.
- `/var` (Variable Data): Fully mutable. This directory stores dynamic state data, application logs, and user directories (`/var/home`).
- **Application Distribution:** Third-party applications should be installed via Flatpak. Flatpak sandboxing ensures that base OS updates will never conflict with user-installed software dependencies.

## 4. Derived Container Images
The primary advantage of `bootc` is the triviality of creating derived operating systems.
Creating a specialized variant of Apollo OS requires only a standard Containerfile:
```dockerfile
FROM ghcr.io/apollo-linux/apollo-nvidia:latest
RUN pacman -S --noconfirm steam lutris
```
This enables developers to construct tailored, bootable infrastructure images seamlessly.

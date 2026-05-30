# Ark: Archlinux immutable builder

Build scripts and configurations for generating the bootable Live ISO of an immutable Arch Linux environment.

This project packages vanilla Arch Linux into an OSTree/bootc-compatible container image and provides an ISO for installation. It is not a separate distribution. The underlying system remains strictly Arch Linux.

## Build Requirements
- `podman`
- `wget`, `curl`, `jq`
- Root privileges (for `mkarchiso`)

## Build ISO
```bash
sudo bash .github/workflows/build_iso.sh
```
The resulting image will be located in the `out/` directory.

## Repository Structure
- **ark.linux**: ISO generation using `archiso`.
- **[ark-image](https://github.com/zamkara/ark-image)**: OCI container definitions and OS package manifests.
- **[alga](https://github.com/zamkara/alga)**: GTK4 frontend for `bootc` installation and system updates.
- **[ark-aur](https://github.com/zamkara/ark-aur)**: Custom repository for pre-compiled AUR packages.

## License
MIT

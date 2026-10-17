#!/bin/bash
set -euo pipefail

# Update and install dependencies
pacman -Syu --noconfirm archiso base-devel git sudo grub

# Create custom local pacman repository for the ISO
mkdir -p /work/.github/workflows/archiso/custom_repo
# Official packages come from the same sync databases used by mkarchiso.
# Only AUR/local archives belong in our override repository.
for archive in /work/aur-packages/*.pkg.tar.zst; do
    read -r name version < <(pacman -Qp "$archive")
    case "$name" in
        *-debug|linux-headers|linux-zen-headers|linux-lts-headers|linux-hardened-headers) continue ;;
    esac
    if ! pacman -Si "$name" >/dev/null 2>&1; then
        cp "$archive" /work/.github/workflows/archiso/custom_repo/
    fi
done
repo-add /work/.github/workflows/archiso/custom_repo/custom.db.tar.gz /work/.github/workflows/archiso/custom_repo/*.pkg.tar.zst

# ISO rootfs is populated by pacman packages from custom_repo

# Run mkarchiso
sed -i 's/airootfs\.sfs/originium.sfs/g' /usr/bin/mkarchiso
sed -i 's/airootfs\.sha512/originium.sha512/g' /usr/bin/mkarchiso
mkarchiso -v -w /work/workdir/ -o /work/out/ /work/.github/workflows/archiso/

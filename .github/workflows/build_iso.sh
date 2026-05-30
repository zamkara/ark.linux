#!/bin/bash
set -e

# Update and install dependencies
pacman -Syu --noconfirm archiso base-devel git sudo

# Create custom local pacman repository for the ISO
mkdir -p /work/.github/workflows/archiso/custom_repo
cp /work/aur-packages/*.pkg.tar.zst /work/.github/workflows/archiso/custom_repo/
repo-add /work/.github/workflows/archiso/custom_repo/custom.db.tar.gz /work/.github/workflows/archiso/custom_repo/*.pkg.tar.zst

# Copy Alga Binary into Live ISO
mkdir -p /work/.github/workflows/archiso/airootfs/usr/bin
cp /work/alga-binary/alga /work/.github/workflows/archiso/airootfs/usr/bin/alga
chmod +x /work/.github/workflows/archiso/airootfs/usr/bin/alga

# Run mkarchiso
sed -i 's|mcopy -i "${efibootimg}" -s "${work_dir}/loader" ::/|mcopy -i "${efibootimg}" -s "${work_dir}/loader" ::/\n    if [[ -f "${profile}/efiboot/splash.bmp" ]]; then mcopy -i "${efibootimg}" "${profile}/efiboot/splash.bmp" ::/splash.bmp; fi|' /usr/bin/mkarchiso
sed -i 's/airootfs.sfs/originium.sfs/g' /usr/bin/mkarchiso
mkarchiso -v -w /work/workdir/ -o /work/out/ /work/.github/workflows/archiso/

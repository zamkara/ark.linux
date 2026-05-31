#!/usr/bin/env bash
set -e

# Patch archiso initcpio hook to use originium.sfs instead of airootfs.sfs
sed -i 's/airootfs\.sfs/originium.sfs/g' /usr/lib/initcpio/hooks/archiso || true
sed -i 's/airootfs\.sha512/originium.sha512/g' /usr/lib/initcpio/hooks/archiso || true

# L1: Only keep: Ark Wizard, Disk (gnome-disk-utility), Ptyxis, Settings
# Remove ALL other .desktop files except the ones we need
find /usr/share/applications -name "*.desktop" | while read f; do
    base=$(basename "$f")
    case "$base" in
        org.gnome.DiskUtility.desktop|\
        org.gnome.Ptyxis.desktop|\
        org.gnome.Settings.desktop|\
        com.zamkara.alga.desktop)
            ;;  # keep these
        *)
            rm -f "$f" || true
            ;;
    esac
done

# L2: Rename Ptyxis to Terminal in live ISO
sed -i 's/^Name=.*/Name=Terminal/' /usr/share/applications/org.gnome.Ptyxis.desktop 2>/dev/null || true

# Compile schemas to ensure MoreWaita and app folders apply
glib-compile-schemas /usr/share/glib-2.0/schemas || true

# Generate only English locale for the Live ISO
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen || true
locale-gen

# Ensure GDM and NetworkManager are enabled
systemctl enable gdm NetworkManager
systemctl set-default graphical.target
systemctl mask ostree-prepare-root.service

# Disable GNOME Initial Setup for the live ark user (not for installed system)
mkdir -p /home/ark/.config
echo "yes" > /home/ark/.config/gnome-initial-setup-done
chown -R 10000:10000 /home/ark

# Rebuild initramfs so the patched hook is included!
mkinitcpio -P

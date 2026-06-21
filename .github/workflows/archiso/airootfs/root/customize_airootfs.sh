#!/usr/bin/env bash
set -e

# Patch archiso initcpio hook to use originium.sfs instead of airootfs.sfs
sed -i 's/airootfs\.sfs/originium.sfs/g' /usr/lib/initcpio/hooks/archiso || true
sed -i 's/airootfs\.sha512/originium.sha512/g' /usr/lib/initcpio/hooks/archiso || true

# L1: Remove only specific bloatware .desktop files.
# Keep everything else (gnome-control-center panels etc. must remain intact).
for f in bssh.desktop bvnc.desktop avahi-discover.desktop qv4l2.desktop \
         qvidcap.desktop stoken-gui.desktop stoken-gui-small.desktop \
         org.gnome.Extensions.desktop org.gnome.TextEditor.desktop \
         lstopo.desktop hwloc-ls.desktop org.gnome.Logs.desktop \
         ibus.desktop ibus-setup.desktop \
         ibus-wayland.desktop; do
    rm -f "/usr/share/applications/$f" 2>/dev/null || true
done

# L2: Rename Console to Terminal in live ISO
sed -i 's/^Name=.*/Name=Terminal/' /usr/share/applications/org.gnome.Console.desktop 2>/dev/null || true

# L3: Ensure alga desktop entry is correct regardless of package version
cat > /usr/share/applications/com.zamkara.alga.desktop << 'EOF'
[Desktop Entry]
Name=Ark Wizard
GenericName=System Installer
Comment=Install Ark Linux to your system
Exec=alga
Icon=drive-harddisk-solidstate
Terminal=false
Type=Application
Categories=System;
StartupNotify=true
EOF

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

# Mask pacman-related services before removing binaries
# ln -sf used instead of systemctl mask: pacman-init.service, etc-pacman.d-gnupg.mount,
# choose-mirror.service already exist as regular files in /etc/systemd/system/ so
# systemctl mask errors with "File already exists"; ln -sf forces replacement
for _unit in pacman-init.service etc-pacman.d-gnupg.mount choose-mirror.service reflector.service reflector.timer; do
    ln -sf /dev/null "/etc/systemd/system/$_unit"
done

# Remove pacman — not needed in live ISO, alga installs via bootc
rm -rf \
    /usr/bin/pacman* \
    /usr/bin/makepkg* \
    /usr/bin/repo-add \
    /usr/bin/repo-elephant \
    /usr/bin/repo-remove \
    /usr/bin/testpkg \
    /usr/bin/vercmp \
    /usr/lib/libalpm.so* \
    /usr/include/alpm* \
    /usr/lib/pkgconfig/libalpm.pc \
    /usr/share/bash-completion/completions/pacman* \
    /usr/share/bash-completion/completions/makepkg* \
    /usr/share/zsh/site-functions/_pacman* \
    /usr/share/man/man8/pacman* \
    /usr/share/man/man8/makepkg* \
    /usr/share/man/man8/repo-* \
    /usr/share/man/man8/vercmp* \
    /usr/share/man/man8/testpkg* \
    /etc/pacman.d/hooks/

# Rebuild initramfs so the patched hook is included!
mkinitcpio -P

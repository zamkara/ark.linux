# Signature: emFta2FyYQ==
ARG VARIANT=ark

# Final Image (ark linux)
FROM docker.io/archlinux:latest
ARG VARIANT

LABEL ostree.bootable="true"
LABEL containers.bootc="1"

COPY aur-packages/*.pkg.tar.zst /tmp/
COPY alga-binary/alga /usr/bin/alga
RUN chmod +x /usr/bin/alga

# Determine kernel based on variant
RUN KERNEL="linux"; \
    if [[ "$VARIANT" == *"-zen"* ]]; then KERNEL="linux-zen"; fi; \
    if [[ "$VARIANT" == *"-lts"* ]]; then KERNEL="linux-lts"; fi; \
    if [[ "$VARIANT" == *"-hardened"* ]]; then KERNEL="linux-hardened"; fi; \
    pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    base $KERNEL linux-firmware networkmanager mkinitcpio zram-generator \
    gnome-shell gnome-control-center gnome-disk-utility gnome-keyring gnome-session gnome-settings-daemon gnome-text-editor nautilus xdg-desktop-portal-gnome xdg-user-dirs-gtk gnome-backgrounds gnome-console gnome-initial-setup gdm plymouth \
    util-linux openssl grub efibootmgr dosfstools ostree skopeo btrfs-progs podman composefs distrobox && \
    if [[ "$VARIANT" == *"-nvidia" ]]; then \
        if [ "$KERNEL" = "linux" ]; then \
            pacman -S --noconfirm nvidia-open nvidia-utils nvidia-settings; \
        else \
            pacman -S --noconfirm nvidia-open-dkms ${KERNEL}-headers dkms nvidia-utils nvidia-settings; \
        fi \
    fi && \
    pacman -U --noconfirm /tmp/*.pkg.tar.zst && \
    rm -f /tmp/*.pkg.tar.zst && \
    pacman -Scc --noconfirm

# Enable plymouth and ostree in mkinitcpio, and configure Plymouth BGRT theme for silent boot
RUN sed -i 's/^HOOKS=.*/HOOKS=(base systemd microcode modconf kms keyboard sd-vconsole block plymouth ostree filesystems fsck)/g' /etc/mkinitcpio.conf && \
    mkdir -p /etc/plymouth && echo -e "[Daemon]\nTheme=bgrt" > /etc/plymouth/plymouthd.conf && \
    mkinitcpio -P && \
    KVER=$(ls -1 /usr/lib/modules | grep -v 'extramodules' | head -n 1) && \
    IMG=$(ls -1 /boot/initramfs-*.img | grep -v 'fallback' | head -n 1) && \
    cp $IMG /usr/lib/modules/$KVER/initramfs.img && \
    rm -rf /boot/* /var/lib/pacman/sync/* /var/log/* /tmp/* /usr/share/doc/* /usr/share/man/* /usr/share/info/*

# Setup kernel args for completely silent boot (just BIOS logo + spinner)
RUN mkdir -p /usr/lib/bootc/kargs.d && \
    echo 'kargs = ["quiet", "splash", "loglevel=3", "rd.udev.log_priority=3", "vt.global_cursor_default=0", "boot.shell_on_fail=1"]' > /usr/lib/bootc/kargs.d/01-silent-boot.toml


# Setup ark linux Updater desktop file
RUN echo "[Desktop Entry]" > /usr/share/applications/alga-updater.desktop && \
    echo "Name=Software Updater" >> /usr/share/applications/alga-updater.desktop && \
    echo "Comment=Update Arch Linux" >> /usr/share/applications/alga-updater.desktop && \
    echo "Exec=alga" >> /usr/share/applications/alga-updater.desktop && \
    echo "Icon=software-update-available-symbolic" >> /usr/share/applications/alga-updater.desktop && \
    echo "Type=Application" >> /usr/share/applications/alga-updater.desktop && \
    echo "Categories=System;Settings;" >> /usr/share/applications/alga-updater.desktop

# Hide bloatware from GNOME Menu
RUN for app in rygel rygel-preferences org.freedesktop.IBus.Setup org.freedesktop.IBus.Panel.Emojier org.freedesktop.IBus.Panel.Extension.Gtk3 org.freedesktop.IBus.Panel.Wayland.Gtk3 orca org.gnome.ColorProfileViewer org.gnome.Tecla htop vim cups org.freedesktop.MalcontentControl org.gnome.Extensions; do \
        if [ -f "/usr/share/applications/$app.desktop" ]; then \
            echo "NoDisplay=true" >> "/usr/share/applications/$app.desktop"; \
        fi; \
    done

# Prepare automatic app-export pacman hooks for Distrobox
RUN mkdir -p /usr/share/ark-distrobox/hooks && \
    echo "[Trigger]" > /usr/share/ark-distrobox/hooks/99-distrobox-export-install.hook && \
    echo "Operation = Install" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-install.hook && \
    echo "Operation = Upgrade" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-install.hook && \
    echo "Type = Path" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-install.hook && \
    echo "Target = usr/share/applications/*.desktop" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-install.hook && \
    echo "[Action]" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-install.hook && \
    echo "Description = Exporting applications to host..." >> /usr/share/ark-distrobox/hooks/99-distrobox-export-install.hook && \
    echo "When = PostTransaction" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-install.hook && \
    echo "NeedsTargets" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-install.hook && \
    echo "Exec = /usr/bin/bash -c 'while read -r f; do distrobox-export --app \"\$(basename \"\$f\" .desktop)\" --export-label \"none\" 2>/dev/null || true; done'" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-install.hook && \
    echo "[Trigger]" > /usr/share/ark-distrobox/hooks/99-distrobox-export-remove.hook && \
    echo "Operation = Remove" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-remove.hook && \
    echo "Type = Path" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-remove.hook && \
    echo "Target = usr/share/applications/*.desktop" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-remove.hook && \
    echo "[Action]" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-remove.hook && \
    echo "Description = Un-exporting applications from host..." >> /usr/share/ark-distrobox/hooks/99-distrobox-export-remove.hook && \
    echo "When = PreTransaction" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-remove.hook && \
    echo "NeedsTargets" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-remove.hook && \
    echo "Exec = /usr/bin/bash -c 'while read -r f; do distrobox-export -d --app \"\$(basename \"\$f\" .desktop)\" 2>/dev/null || true; done'" >> /usr/share/ark-distrobox/hooks/99-distrobox-export-remove.hook

# Automatically create and enter Arch Linux distrobox for interactive user shells
RUN echo 'if [[ $- == *i* ]] && [ -z "$CONTAINER_ID" ]; then' > /etc/profile.d/99-arch-distrobox.sh && \
    echo '    if [ "$EUID" -ne 0 ]; then' >> /etc/profile.d/99-arch-distrobox.sh && \
    echo '        if ! distrobox list | grep -q "arch"; then' >> /etc/profile.d/99-arch-distrobox.sh && \
    echo '            echo "Initializing Arch Linux environment..."' >> /etc/profile.d/99-arch-distrobox.sh && \
    echo '            distrobox create --name arch --image docker.io/archlinux:latest --init-hooks "mkdir -p /etc/pacman.d/hooks && cp /run/host/usr/share/ark-distrobox/hooks/*.hook /etc/pacman.d/hooks/" -Y > /dev/null 2>&1' >> /etc/profile.d/99-arch-distrobox.sh && \
    echo '        fi' >> /etc/profile.d/99-arch-distrobox.sh && \
    echo '        exec distrobox enter arch' >> /etc/profile.d/99-arch-distrobox.sh && \
    echo '    fi' >> /etc/profile.d/99-arch-distrobox.sh && \
    echo 'fi' >> /etc/profile.d/99-arch-distrobox.sh && \
    echo 'source /etc/profile.d/99-arch-distrobox.sh' >> /etc/bash.bashrc

# Enable critical system services
RUN systemctl enable gdm NetworkManager

# Ensure bootupd is executable and accessible from common paths
RUN chmod +x /usr/libexec/bootupd /usr/bin/bootupctl && \
    ln -sf /usr/libexec/bootupd /usr/sbin/bootupd && \
    ln -sf /usr/libexec/bootupd /usr/bin/bootupd && \
    echo "=== Verifying bootupd installation ===" && \
    bootupctl --version && \
    which bootupctl && \
    which bootupd && \
    ls -lah /usr/libexec/bootupd && \
    ls -lah /usr/sbin/bootupd && \
    ls -lah /usr/bin/bootupd && \
    test -x /usr/libexec/bootupd && \
    test -x /usr/sbin/bootupd && \
    test -x /usr/bin/bootupd && \
    echo "✓ bootupd successfully installed in multiple paths" && \
    echo 'VERSION_ID="rolling"' >> /usr/lib/os-release

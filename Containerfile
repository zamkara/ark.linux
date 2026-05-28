# Signature: emFta2FyYQ==
ARG VARIANT=ark

# Final Image (ark linux)
FROM docker.io/archlinux:latest
ARG VARIANT

COPY aur-packages/*.pkg.tar.zst /tmp/
COPY alga-binary/alga /usr/bin/alga
RUN chmod +x /usr/bin/alga

# Install core system, GNOME, and bootc dependencies
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    base linux linux-firmware networkmanager mkinitcpio \
    gnome gdm \
    util-linux openssl grub efibootmgr dosfstools ostree skopeo btrfs-progs podman composefs distrobox && \
    if [ "$VARIANT" = "ark-nvidia" ]; then pacman -S --noconfirm nvidia-open nvidia-utils nvidia-settings; fi && \
    pacman -U --noconfirm /tmp/*.pkg.tar.zst && \
    rm -f /tmp/*.pkg.tar.zst

# Enable ostree in mkinitcpio (Required for Bootc to work on Arch)
RUN sed -i 's/\bblock filesystems\b/block ostree filesystems/g' /etc/mkinitcpio.conf && \
    mkinitcpio -P


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

# Automatically create and enter Arch Linux distrobox for interactive user shells
RUN echo 'if [[ $- == *i* ]] && [ -z "$CONTAINER_ID" ]; then' > /etc/profile.d/99-arch-distrobox.sh && \
    echo '    if [ "$EUID" -ne 0 ]; then' >> /etc/profile.d/99-arch-distrobox.sh && \
    echo '        if ! distrobox list | grep -q "arch"; then' >> /etc/profile.d/99-arch-distrobox.sh && \
    echo '            echo "Initializing Arch Linux environment..."' >> /etc/profile.d/99-arch-distrobox.sh && \
    echo '            distrobox create --name arch --image docker.io/archlinux:latest -Y > /dev/null 2>&1' >> /etc/profile.d/99-arch-distrobox.sh && \
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

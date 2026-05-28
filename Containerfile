# Signature: emFta2FyYQ==
ARG BASE_IMAGE=ghcr.io/apollo-linux/apollo-nvidia:latest

# Stage 1: Build Alga Updater
FROM docker.io/archlinux:latest AS alga-builder
RUN pacman -Syu --noconfirm rust pkgconf gtk4 libadwaita base-devel git
COPY .github/workflows/alga /src
WORKDIR /src
RUN cargo build --release

# Stage 2: Final Image
FROM ${BASE_IMAGE}

COPY aur-packages/*.pkg.tar.zst /tmp/

# Install runtime dependencies including ostree, skopeo, bootc, and bootupd
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm util-linux openssl grub efibootmgr dosfstools ostree skopeo btrfs-progs podman composefs distrobox && \
    pacman -U --noconfirm /tmp/*.pkg.tar.zst && \
    rm -f /tmp/*.pkg.tar.zst

# Copy Alga binary into the system
COPY --from=alga-builder /src/target/release/alga /usr/bin/alga

# Setup Apollo Updater desktop file
RUN echo "[Desktop Entry]" > /usr/share/applications/alga-updater.desktop && \
    echo "Name=Software Updater" >> /usr/share/applications/alga-updater.desktop && \
    echo "Comment=Update Apollo OS" >> /usr/share/applications/alga-updater.desktop && \
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
RUN echo 'if [[ $- == *i* ]] && [ -z "$CONTAINER_ID" ]; then' > /etc/profile.d/99-apollo-distrobox.sh && \
    echo '    if [ "$EUID" -ne 0 ]; then' >> /etc/profile.d/99-apollo-distrobox.sh && \
    echo '        if ! distrobox list 2>/dev/null | grep -q "\barch\b"; then' >> /etc/profile.d/99-apollo-distrobox.sh && \
    echo '            echo "✨ Welcome to Apollo OS!"' >> /etc/profile.d/99-apollo-distrobox.sh && \
    echo '            echo "📦 Initializing your Arch Linux subsystem for the first time..."' >> /etc/profile.d/99-apollo-distrobox.sh && \
    echo '            distrobox create --name arch --image archlinux:latest -Y' >> /etc/profile.d/99-apollo-distrobox.sh && \
    echo '        fi' >> /etc/profile.d/99-apollo-distrobox.sh && \
    echo '        exec distrobox enter arch' >> /etc/profile.d/99-apollo-distrobox.sh && \
    echo '    fi' >> /etc/profile.d/99-apollo-distrobox.sh && \
    echo 'fi' >> /etc/profile.d/99-apollo-distrobox.sh && \
    chmod +x /etc/profile.d/99-apollo-distrobox.sh && \
    echo '[ -r /etc/profile.d/99-apollo-distrobox.sh ] && source /etc/profile.d/99-apollo-distrobox.sh' >> /etc/bash.bashrc

# Ensure bootupd is executable and accessible from common paths
# bootc looks for bootupd in PATH during installation
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

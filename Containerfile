# Signature: emFta2FyYQ==
ARG BASE_IMAGE=ghcr.io/apollo-linux/apollo-nvidia:latest
FROM ${BASE_IMAGE}

COPY aur-packages/*.pkg.tar.zst /tmp/

# Install runtime dependencies including ostree, skopeo, bootc, and bootupd
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm util-linux openssl grub efibootmgr dosfstools ostree skopeo btrfs-progs podman composefs distrobox && \
    pacman -U --noconfirm /tmp/*.pkg.tar.zst && \
    rm -f /tmp/*.pkg.tar.zst

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
    chmod +x /etc/profile.d/99-apollo-distrobox.sh

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

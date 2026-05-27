ARG BASE_IMAGE=ghcr.io/apollo-linux/apollo-nvidia:latest
FROM ${BASE_IMAGE} as builder

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git sudo && \
    useradd -m builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /home/builder
RUN git clone https://aur.archlinux.org/bootupd.git && \
    chown -R builder:builder bootupd

WORKDIR /home/builder/bootupd
RUN sudo -u builder makepkg -s --noconfirm && \
    pacman -U --noconfirm *.pkg.tar.zst

# Copy final image from base
FROM ${BASE_IMAGE}

# Install runtime dependencies
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm util-linux openssl grub efibootmgr dosfstools

# Copy bootupd from builder stage to multiple standard paths
COPY --from=builder /usr/libexec/bootupd /usr/libexec/bootupd
COPY --from=builder /usr/bin/bootupctl /usr/bin/bootupctl
COPY --from=builder /usr/lib/bootupd /usr/lib/bootupd
COPY --from=builder /usr/lib/systemd/system/bootloader-update.service /usr/lib/systemd/system/

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
    echo -e '#!/bin/bash\necho "dummy-1.0-1,1700000000 "' > /usr/bin/rpm && \
    chmod +x /usr/bin/rpm && \
    mkdir -p /usr/lib/efi/dummy/1/EFI/BOOT && touch /usr/lib/efi/dummy/1/EFI/BOOT/BOOTX64.EFI && \
    (bootupctl backend generate-update-metadata / || true) && \
    rm -f /usr/bin/rpm && \
    echo 'VERSION_ID="rolling"' >> /usr/lib/os-release

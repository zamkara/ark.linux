# Signature: emFta2FyYQ==
ARG BASE_IMAGE=ghcr.io/apollo-linux/apollo-nvidia:latest
FROM ${BASE_IMAGE}

COPY aur-packages/*.pkg.tar.zst /tmp/

# Install runtime dependencies including ostree, skopeo, bootc, and bootupd
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm util-linux openssl grub efibootmgr dosfstools ostree skopeo btrfs-progs podman composefs && \
    pacman -U --noconfirm /tmp/*.pkg.tar.zst && \
    rm -f /tmp/*.pkg.tar.zst

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
    mkdir -p /usr/lib/efi/dummy/1/EFI/BOOT && grub-mkimage -O x86_64-efi -o /usr/lib/efi/dummy/1/EFI/BOOT/BOOTX64.EFI -p /boot/grub fat ext2 btrfs part_gpt part_msdos normal linux efi_gop search configfile && \
    (bootupctl backend generate-update-metadata / || true) && \
    rm -f /usr/bin/rpm && \
    echo 'VERSION_ID="rolling"' >> /usr/lib/os-release

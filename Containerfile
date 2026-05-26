FROM ghcr.io/apollo-linux/apollo-nvidia:latest as builder

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git sudo && \
    useradd -m builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /home/builder
RUN git clone https://aur.archlinux.org/bootupd.git && \
    chown -R builder:builder bootupd

WORKDIR /home/builder/bootupd
RUN sudo -u builder makepkg -s --noconfirm && \
    # Verify package was created
    ls -lah *.pkg.tar.zst && \
    # Extract and check contents (only bootupd, not debug)
    tar -I zstd -tf bootupd-0.2.32-2-x86_64.pkg.tar.zst | grep -E "(libexec|bin|lib/bootupd|systemd)" && \
    # Install the package
    pacman -U --noconfirm *.pkg.tar.zst && \
    # Comprehensive verification
    echo "=== Verifying bootupd installation ===" && \
    which bootupctl && \
    bootupctl --version && \
    file /usr/libexec/bootupd && \
    file /usr/bin/bootupctl && \
    ls -lah /usr/libexec/bootupd && \
    ls -lah /usr/bin/bootupctl && \
    ls -lah /usr/lib/bootupd/ && \
    ls -lah /usr/lib/systemd/system/bootloader-update.service

# Copy final image from base
FROM ghcr.io/apollo-linux/apollo-nvidia:latest

# Install bootupd and runtime dependencies in final image
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm bootupd util-linux openssl grub efibootmgr dosfstools && \
    echo "✓ bootupd installed via pacman"

# Copy additional bootupd files from builder if needed (for overrides)
COPY --from=builder /usr/lib/bootupd /usr/lib/bootupd

# Verify bootupd is accessible
RUN which bootupctl && \
    bootupctl --version && \
    echo "=== Final verification ===" && \
    ls -lah /usr/libexec/bootupd && \
    ls -lah /usr/bin/bootupctl && \
    test -x /usr/libexec/bootupd && \
    echo "✓ bootupd successfully installed in final image"

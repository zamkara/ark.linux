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
    # Extract and check contents
    tar -tzf bootupd-*.pkg.tar.zst | grep -E "(libexec|bin|lib/bootupd|systemd)" && \
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

# Copy bootupd binaries and libraries from builder stage
COPY --from=builder /usr/libexec/bootupd /usr/libexec/bootupd
COPY --from=builder /usr/bin/bootupctl /usr/bin/bootupctl
COPY --from=builder /usr/lib/bootupd /usr/lib/bootupd
COPY --from=builder /usr/lib/systemd/system/bootloader-update.service /usr/lib/systemd/system/

# Set proper permissions and final verification
RUN chmod +x /usr/libexec/bootupd /usr/bin/bootupctl && \
    echo "=== Final verification ===" && \
    ls -lah /usr/libexec/bootupd && \
    ls -lah /usr/bin/bootupctl && \
    bootupctl --version && \
    test -x /usr/libexec/bootupd && \
    echo "✓ bootupd successfully installed in final image"

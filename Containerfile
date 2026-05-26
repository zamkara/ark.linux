FROM ghcr.io/apollo-linux/apollo-nvidia:latest as builder

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git sudo && \
    useradd -m builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    sudo -u builder bash -c ' \
      cd /tmp && \
      git clone https://aur.archlinux.org/bootupd.git && \
      cd bootupd && \
      makepkg -si --noconfirm \
    '

# Copy final image from base
FROM ghcr.io/apollo-linux/apollo-nvidia:latest

# Copy bootupd packages from builder stage
COPY --from=builder /tmp/bootupd/*.pkg.tar.zst /tmp/
RUN pacman -U --noconfirm /tmp/*.pkg.tar.zst && \
    rm /tmp/*.pkg.tar.zst

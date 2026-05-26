FROM ghcr.io/apollo-linux/apollo-nvidia:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git sudo && \
    useradd -m builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    sudo -u builder bash -c ' \
      cd /tmp && \
      git clone https://aur.archlinux.org/bootupd.git && \
      cd bootupd && \
      makepkg -si --noconfirm \
    ' && \
    userdel -r builder && \
    rm -rf /tmp/bootupd

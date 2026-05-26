FROM ghcr.io/apollo-linux/apollo-nvidia:latest

RUN pacman -Syu --noconfirm bootupd

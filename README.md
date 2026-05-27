# Apollo Linux Unofficial ISO Builder

This repository serves as an unofficial automated builder for [Apollo Linux](https://github.com/apollo-linux/apollo). It is designed to create a Live Installer ISO that seamlessly deploys the Apollo OCI bootc container to your disk.

## Building the ISO
The ISO is built automatically via GitHub Actions, which builds variants for standard AMD/Intel as well as Nvidia GPUs.

If you wish to build it manually on an Arch Linux system:
### 1. Install the build tools
```bash
sudo pacman -S archiso podman
```
### 2. Pull the repository
```bash
git clone https://github.com/zamkara/apollo.builder.git
cd apollo.builder
```
### 3. Build the Installer ISO
```bash
# Set your desired base image (e.g., ghcr.io/apollo-linux/apollo-nvidia:latest)
podman build --build-arg BASE_IMAGE=ghcr.io/apollo-linux/apollo-nvidia:latest -t apollo-bootupd:latest -f Containerfile .
mkdir -p archiso/airootfs/root/
podman save apollo-bootupd:latest -o archiso/airootfs/root/apollo-image.tar
sudo mkarchiso -v -w workdir/ -o out/ archiso/
```

## Credits
This project wouldn't be possible without the incredible open-source community:
- The base Archiso template was adapted from **blendOS** (https://git.blendos.co/blendOS/image-builder), which in turn was based on **Arkane Linux's** ISO build scripts.
- The Archiso project by **Arch Linux**.

## Development
Contributions are welcome! Please ensure that you do not include specific branding unless it relates to Apollo Linux.

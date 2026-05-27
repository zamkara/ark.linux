#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="apollo-installer"
iso_label="APOLLO_$(date +%Y%m)"
iso_publisher="Apollo Linux <https://github.com/zamkara/apollo>"
iso_application="Apollo Linux Installer"
iso_version="$(date +%Y.%m.%d)"
install_dir="apollo"
buildmodes=('iso')
bootmodes=(
  'bios.syslinux'
  'uefi.systemd-boot'
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '22' '-b' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/generate_locale"]="0:0:755"
  ["/etc/default/useradd"]="0:0:600"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/sudoers"]="0:0:400"
  ["/etc/locale.gen"]="0:0:644"
  ["/usr/local/bin/apollo-installer"]="0:0:755"
  ["/etc/skel/Desktop/apollo-installer.desktop"]="0:0:755"
  ["/usr/share/applications/apollo-installer.desktop"]="0:0:755"
  ["/etc/pacman.d/hooks/99-hide-apps.hook"]="0:0:644"
)

# Signature: emFta2FyYQ==
#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="ark-installer"
iso_label="ark_$(date +%Y%m)"
iso_publisher="ark linux <https://github.com/zamkara/ark>"
iso_application="ark linux Installer"
iso_version="$(date +%Y.%m.%d)"
install_dir="ark"
buildmodes=('iso')
bootmodes=(
  'uefi.grub'
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '3' '-b' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/etc/default/useradd"]="0:0:600"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/sudoers"]="0:0:400"
  ["/etc/locale.gen"]="0:0:644"
  ["/usr/share/applications/com.zamkara.alga.desktop"]="0:0:755"
  ["/etc/skel/.config/autostart/com.zamkara.alga.desktop"]="0:0:755"
  ["/etc/pacman.d/hooks/99-hide-apps.hook"]="0:0:644"
  ["/usr/local/bin/set-wallpaper.sh"]="0:0:755"
  ["/etc/skel/.config/autostart/set-wallpaper.desktop"]="0:0:755"
)

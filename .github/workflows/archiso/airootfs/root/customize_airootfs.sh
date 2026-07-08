#!/usr/bin/env bash
set -e

# Patch archiso initcpio hook to use originium.sfs instead of airootfs.sfs
sed -i 's/airootfs\.sfs/originium.sfs/g' /usr/lib/initcpio/hooks/archiso || true
sed -i 's/airootfs\.sha512/originium.sha512/g' /usr/lib/initcpio/hooks/archiso || true

# L1: Remove only specific bloatware .desktop files.
# Keep everything else (gnome-control-center panels etc. must remain intact).
for f in bssh.desktop bvnc.desktop avahi-discover.desktop qv4l2.desktop \
         qvidcap.desktop stoken-gui.desktop stoken-gui-small.desktop \
         org.gnome.Extensions.desktop org.gnome.TextEditor.desktop \
         lstopo.desktop hwloc-ls.desktop org.gnome.Logs.desktop \
         ibus.desktop ibus-setup.desktop \
         ibus-wayland.desktop; do
    rm -f "/usr/share/applications/$f" 2>/dev/null || true
done

# L2: Rename Console to Terminal in live ISO
sed -i 's/^Name=.*/Name=Terminal/' /usr/share/applications/org.gnome.Console.desktop 2>/dev/null || true

# L3: Ensure alga desktop entry is correct regardless of package version
cat > /usr/share/applications/com.zamkara.alga.desktop << 'EOF'
[Desktop Entry]
Name=Ark Wizard
GenericName=System Installer
Comment=Install Ark Linux to your system
Exec=alga
Icon=drive-harddisk-solidstate
Terminal=false
Type=Application
Categories=System;
StartupNotify=true
EOF

# Compile schemas to ensure MoreWaita and app folders apply
glib-compile-schemas /usr/share/glib-2.0/schemas || true

# Generate only English locale for the Live ISO
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen || true
locale-gen

# Ensure GDM and NetworkManager are enabled
systemctl enable gdm NetworkManager
systemctl set-default graphical.target
systemctl mask ostree-prepare-root.service

# Enable Plymouth for boot splash
systemctl unmask plymouth-start.service
systemctl enable plymouth-start.service

# Disable GNOME Initial Setup for the live ark user (not for installed system)
mkdir -p /home/ark/.config
echo "yes" > /home/ark/.config/gnome-initial-setup-done
chown -R 10000:10000 /home/ark

# Mask pacman-related services before removing binaries
# ln -sf used instead of systemctl mask: pacman-init.service, etc-pacman.d-gnupg.mount,
# choose-mirror.service already exist as regular files in /etc/systemd/system/ so
# systemctl mask errors with "File already exists"; ln -sf forces replacement
for _unit in pacman-init.service etc-pacman.d-gnupg.mount choose-mirror.service reflector.service reflector.timer; do
    ln -sf /dev/null "/etc/systemd/system/$_unit"
done

# Remove pacman — not needed in live ISO, alga installs via bootc
rm -rf \
    /usr/bin/pacman* \
    /usr/bin/makepkg* \
    /usr/bin/repo-add \
    /usr/bin/repo-elephant \
    /usr/bin/repo-remove \
    /usr/bin/testpkg \
    /usr/bin/vercmp \
    /usr/lib/libalpm.so* \
    /usr/include/alpm* \
    /usr/lib/pkgconfig/libalpm.pc \
    /usr/share/bash-completion/completions/pacman* \
    /usr/share/bash-completion/completions/makepkg* \
    /usr/share/zsh/site-functions/_pacman* \
    /usr/share/man/man8/pacman* \
    /usr/share/man/man8/makepkg* \
    /usr/share/man/man8/repo-* \
    /usr/share/man/man8/vercmp* \
    /usr/share/man/man8/testpkg* \
    /etc/pacman.d/hooks/

# ── DEBLOAT ────────────────────────────────────────────────────────────────────

# Large /usr/share data — man pages, docs, help, locale
rm -rf /usr/share/man
rm -rf /usr/share/doc
rm -rf /usr/share/info
rm -rf /usr/share/gtk-doc
rm -rf /usr/share/help
rm -rf /usr/share/installed-tests

# Keep only English locale data
find /usr/share/locale -mindepth 1 -maxdepth 1 -type d \
    ! -name 'en' ! -name 'en_US' ! -name 'C' ! -name 'POSIX' \
    -exec rm -rf {} + 2>/dev/null || true

# Dev / build files
rm -rf /usr/share/aclocal
rm -rf /usr/share/gir-1.0
rm -rf /usr/share/vala
rm -rf /usr/share/cmake
rm -rf /usr/share/glade
rm -rf /usr/share/gettext-1.0
rm -rf /usr/share/libtool

# Misc runtime data not needed in live installer
rm -rf /usr/share/emacs
rm -rf /usr/share/common-lisp
rm -rf /usr/share/powershell
rm -rf /usr/share/elvish
rm -rf /usr/share/slsh
rm -rf /usr/share/fish
rm -rf /usr/share/lv2specgen
rm -rf /usr/share/java
rm -rf /usr/share/awk
rm -rf /usr/share/tabset
rm -rf /usr/share/vim
rm -rf /usr/share/nano
rm -rf /usr/share/licenses
rm -rf /usr/share/makepkg
rm -rf /usr/share/makepkg-template
rm -rf /usr/share/dict
rm -rf /usr/share/hwloc
rm -rf /usr/share/gupnp-dlna-2.0
rm -rf /usr/share/WebP
rm -rf /usr/share/wayland-eglstream
rm -rf /usr/share/factory
rm -rf /usr/share/ladspa
rm -rf /usr/share/sounds

# Kerberos
rm -f /usr/bin/k5srvutil /usr/bin/kadmin /usr/bin/kadmind /usr/bin/kadmin.local \
    /usr/bin/kdb5_ldap_util /usr/bin/kdb5_util /usr/bin/kdestroy /usr/bin/kinit \
    /usr/bin/klist /usr/bin/kpasswd /usr/bin/kprop /usr/bin/kpropd \
    /usr/bin/kproplog /usr/bin/krb5-config /usr/bin/krb5kdc \
    /usr/bin/krb5-send-pr /usr/bin/ksu /usr/bin/kswitch \
    /usr/bin/ktutil /usr/bin/kvno

# V4L2 / DVB / TV tuner
rm -f /usr/bin/dvb-fe-tool /usr/bin/dvb-format-convert /usr/bin/dvbv5-daemon \
    /usr/bin/dvbv5-scan /usr/bin/dvbv5-zap /usr/bin/cx18-ctl /usr/bin/ivtv-ctl \
    /usr/bin/rds-ctl /usr/bin/v4l2-compliance /usr/bin/v4l2-ctl /usr/bin/v4l2-dbg \
    /usr/bin/v4l2-sysfs-path /usr/bin/v4l2-tracer /usr/bin/decode_tm6000 \
    /usr/bin/media-ctl

# SPIRV / GLSL shader dev tools
rm -f /usr/bin/spirv-as /usr/bin/spirv-cfg /usr/bin/spirv-diff /usr/bin/spirv-dis \
    /usr/bin/spirv-lesspipe.sh /usr/bin/spirv-link /usr/bin/spirv-lint \
    /usr/bin/spirv-objdump /usr/bin/spirv-opt /usr/bin/spirv-reduce \
    /usr/bin/spirv-val \
    /usr/bin/glslang /usr/bin/glslangValidator /usr/bin/glslc

# idevice / iOS tools (libimobiledevice)
rm -f /usr/bin/idevicebackup /usr/bin/idevicebackup2 /usr/bin/idevicebtlogger \
    /usr/bin/idevicecrashreport /usr/bin/idevicedate /usr/bin/idevicedebug \
    /usr/bin/idevicedebugserverproxy /usr/bin/idevicedevmodectl \
    /usr/bin/idevicediagnostics /usr/bin/ideviceenterrecovery \
    /usr/bin/idevice_id /usr/bin/ideviceimagemounter /usr/bin/ideviceinfo \
    /usr/bin/idevicename /usr/bin/idevicenotificationproxy /usr/bin/idevicepair \
    /usr/bin/ideviceprovision /usr/bin/idevicescreenshot \
    /usr/bin/idevicesetlocation /usr/bin/idevicesyslog \
    /usr/bin/inetcat /usr/bin/iproxy

# NFS server tools (nfs-utils client tetap ada)
rm -f /usr/bin/exportfs /usr/bin/nfsdcld /usr/bin/nfsdclddb /usr/bin/nfsdclnts \
    /usr/bin/nfsdctl /usr/bin/rpc.mountd /usr/bin/rpc.nfsd \
    /usr/bin/start-statd /usr/bin/sm-notify \
    /usr/bin/gssproxy /usr/bin/gss-client /usr/bin/gss-server \
    /usr/bin/nfsiostat /usr/bin/nfsrahead /usr/bin/nfsref

# SMB / Samba
rm -f /usr/bin/smb2-quota /usr/bin/smbcacls /usr/bin/smbclient \
    /usr/bin/smbcquotas /usr/bin/smbget /usr/bin/smbinfo /usr/bin/smbspool \
    /usr/bin/smbtar /usr/bin/smbtree /usr/bin/nmblookup /usr/bin/rpcclient \
    /usr/bin/cifscreds /usr/bin/mount.cifs /usr/bin/mount.smb3 \
    /usr/bin/cifs.idmap /usr/bin/cifs.upcall

# Audio codec CLI tools
rm -f /usr/bin/amrnb-dec /usr/bin/amrnb-enc /usr/bin/amrwb-dec \
    /usr/bin/dlc3 /usr/bin/elc3 \
    /usr/bin/freeaptxdec /usr/bin/freeaptxenc \
    /usr/bin/lame /usr/bin/mpg123 /usr/bin/mpg123-id3dump /usr/bin/mpg123-strip \
    /usr/bin/out123 /usr/bin/openmpt123 \
    /usr/bin/sbcdec /usr/bin/sbcenc /usr/bin/sbcinfo \
    /usr/bin/sndfile-cmp /usr/bin/sndfile-concat /usr/bin/sndfile-convert \
    /usr/bin/sndfile-deinterleave /usr/bin/sndfile-info /usr/bin/sndfile-interleave \
    /usr/bin/sndfile-metadata-get /usr/bin/sndfile-metadata-set \
    /usr/bin/sndfile-play /usr/bin/sndfile-salvage \
    /usr/bin/speexdec /usr/bin/speexenc \
    /usr/bin/twolame /usr/bin/mp3rtp \
    /usr/bin/wavpack /usr/bin/wvgain /usr/bin/wvtag /usr/bin/wvunpack \
    /usr/bin/flac /usr/bin/metaflac \
    /usr/bin/rubberband /usr/bin/rubberband-r3 \
    /usr/bin/bs2bconvert /usr/bin/bs2bstream

# Video codec CLI tools
rm -f /usr/bin/dav1d /usr/bin/aomdec /usr/bin/aomenc \
    /usr/bin/rav1e /usr/bin/SvtAv1EncApp \
    /usr/bin/vpxdec /usr/bin/vpxenc \
    /usr/bin/x264 /usr/bin/x265 /usr/bin/vmaf \
    /usr/bin/ffmpeg /usr/bin/ffplay /usr/bin/ffprobe \
    /usr/bin/qt-faststart \
    /usr/bin/muxer /usr/bin/remuxer \
    /usr/bin/timelineeditor /usr/bin/vspipe \
    /usr/bin/srt-ffplay /usr/bin/srt-file-transmit \
    /usr/bin/srt-live-transmit /usr/bin/srt-tunnel \
    /usr/bin/yuvconvert \
    /usr/bin/fftwf-wisdom /usr/bin/fftwl-wisdom /usr/bin/fftwq-wisdom \
    /usr/bin/fftw-wisdom /usr/bin/fftw-wisdom-to-conf

# Image codec / conversion CLI tools
rm -f /usr/bin/avifdec /usr/bin/avifenc /usr/bin/avifgainmaputil \
    /usr/bin/cjpeg /usr/bin/cjpegli /usr/bin/djpeg /usr/bin/djpegli \
    /usr/bin/jxlinfo /usr/bin/djxl /usr/bin/cjxl \
    /usr/bin/opj_compress /usr/bin/opj_decompress /usr/bin/opj_dump \
    /usr/bin/tiff2bw /usr/bin/tiff2pdf /usr/bin/tiff2ps /usr/bin/tiff2rgba \
    /usr/bin/tiffcmp /usr/bin/tiffcp /usr/bin/tiffcrop /usr/bin/tiffdither \
    /usr/bin/tiffdump /usr/bin/tiffgt /usr/bin/tiffinfo /usr/bin/tiffmedian \
    /usr/bin/tiffset /usr/bin/tiffsplit /usr/bin/tificc \
    /usr/bin/ppm2tiff /usr/bin/raw2tiff \
    /usr/bin/gifbuild /usr/bin/gifclrmp /usr/bin/giffix \
    /usr/bin/giftext /usr/bin/giftool \
    /usr/bin/png2pnm /usr/bin/pngfix /usr/bin/png-fix-itxt /usr/bin/pnm2png \
    /usr/bin/rsvg-convert \
    /usr/bin/pal2rgb /usr/bin/xpstojpeg /usr/bin/xpstopdf \
    /usr/bin/xpstopng /usr/bin/xpstops /usr/bin/xpstosvg \
    /usr/bin/tjbench \
    /usr/bin/woff2_compress /usr/bin/woff2_decompress /usr/bin/woff2_info \
    /usr/bin/bd_info /usr/bin/bd_list_titles /usr/bin/bd_splice

# hwloc
rm -f /usr/bin/hwloc-annotate /usr/bin/hwloc-bind /usr/bin/hwloc-calc \
    /usr/bin/hwloc-compress-dir /usr/bin/hwloc-diff /usr/bin/hwloc-distrib \
    /usr/bin/hwloc-dump-hwdata /usr/bin/hwloc-gather-cpuid \
    /usr/bin/hwloc-gather-topology /usr/bin/hwloc-info /usr/bin/hwloc-ls \
    /usr/bin/hwloc-patch /usr/bin/hwloc-ps \
    /usr/bin/lstopo /usr/bin/lstopo-no-graphics

# gettext dev tools
rm -f /usr/bin/autopoint /usr/bin/gettextize /usr/bin/xgettext \
    /usr/bin/msgattrib /usr/bin/msgcat /usr/bin/msgcmp /usr/bin/msgcomm \
    /usr/bin/msgconv /usr/bin/msgen /usr/bin/msgexec /usr/bin/msgfilter \
    /usr/bin/msgfmt /usr/bin/msggrep /usr/bin/msginit /usr/bin/msgmerge \
    /usr/bin/msgpre /usr/bin/msgunfmt /usr/bin/msguniq \
    /usr/bin/printf_gettext /usr/bin/printf_ngettext \
    /usr/bin/recode-sr-latin /usr/bin/po-fetch /usr/bin/yat2m

# Profiling / instrumentation tools
rm -f /usr/bin/gprofng /usr/bin/gprofng-archive /usr/bin/gprofng-collect-app \
    /usr/bin/gprofng-display-html /usr/bin/gprofng-display-src \
    /usr/bin/gprofng-display-text /usr/bin/gprofng-gmon \
    /usr/bin/gprof \
    /usr/bin/pcprofiledump /usr/bin/sprof /usr/bin/sotruss \
    /usr/bin/memusage /usr/bin/memusagestat \
    /usr/bin/cairo-trace

# ASCII art (libcaca / aalib)
rm -f /usr/bin/aafire /usr/bin/aainfo /usr/bin/aalib-config \
    /usr/bin/aasavefont /usr/bin/aatest \
    /usr/bin/cacaclock /usr/bin/caca-config /usr/bin/cacademo \
    /usr/bin/cacafire /usr/bin/cacaplay /usr/bin/cacaserver \
    /usr/bin/cacaview /usr/bin/img2txt

# protobuf / wayland-scanner dev
rm -f /usr/bin/wayland-scanner \
    /usr/bin/protoc /usr/bin/protoc-c /usr/bin/protoc-gen-c \
    /usr/bin/protoc-gen-upb /usr/bin/protoc-gen-upbdefs \
    /usr/bin/protoc-gen-upb_minitable \
    /usr/bin/protoc-35.1.0 /usr/bin/protoc-gen-upb-35.1.0 \
    /usr/bin/protoc-gen-upbdefs-35.1.0 \
    /usr/bin/protoc-gen-upb_minitable-35.1.0

# PDF tools (poppler)
rm -f /usr/bin/pdfattach /usr/bin/pdfdetach /usr/bin/pdffonts \
    /usr/bin/pdfimages /usr/bin/pdfinfo /usr/bin/pdfseparate \
    /usr/bin/pdfsig /usr/bin/pdftocairo /usr/bin/pdftohtml \
    /usr/bin/pdftoppm /usr/bin/pdftops /usr/bin/pdftotext /usr/bin/pdfunite

# GObject introspection dev CLI
rm -f /usr/bin/gi-compile-repository /usr/bin/gi-decompile-typelib \
    /usr/bin/gi-inspect-typelib /usr/bin/gobject-query \
    /usr/bin/libtool /usr/bin/libtoolize /usr/bin/libtool-next-version

# GStreamer CLI tools (library tetap ada untuk GNOME)
rm -f /usr/bin/gst-device-monitor-1.0 /usr/bin/gst-discoverer-1.0 \
    /usr/bin/gst-inspect-1.0 /usr/bin/gst-launch-1.0 /usr/bin/gst-play-1.0 \
    /usr/bin/gst-stats-1.0 /usr/bin/gst-tester-1.0 \
    /usr/bin/gst-transcoder-1.0 /usr/bin/gst-typefind-1.0

# ICU dev tools
rm -f /usr/bin/genbrk /usr/bin/gencat /usr/bin/genccode /usr/bin/gencfu \
    /usr/bin/gencmn /usr/bin/gencnval /usr/bin/gendict /usr/bin/gennorm2 \
    /usr/bin/genrb /usr/bin/gensprep /usr/bin/icuexportdata /usr/bin/icupkg \
    /usr/bin/derb /usr/bin/uconv /usr/bin/icuinfo /usr/bin/icu-config \
    /usr/bin/pkgdata /usr/bin/trietool /usr/bin/trietool-0.2 \
    /usr/bin/makeconv

# Wireless tools (digantikan NetworkManager + iw)
rm -f /usr/bin/iwconfig /usr/bin/iwevent /usr/bin/iwgetid /usr/bin/iwlist \
    /usr/bin/iwpriv /usr/bin/iwspy /usr/bin/ifrename /usr/bin/ifstat

# Test / debug / input device tools
rm -f /usr/bin/manette-test /usr/bin/mtdev-test /usr/bin/libevdev-tweak-device \
    /usr/bin/testcontroller /usr/bin/testlibraw /usr/bin/proptest \
    /usr/bin/mouse-dpi-tool /usr/bin/mouse-test /usr/bin/touchpad-edge-detector \
    /usr/bin/libwacom-list-devices /usr/bin/libwacom-list-local-devices \
    /usr/bin/libwacom-show-stylus /usr/bin/libwacom-update-db

# NSS / TLS testing tools
rm -f /usr/bin/certutil /usr/bin/cmsutil /usr/bin/crlutil /usr/bin/modutil \
    /usr/bin/pk12util /usr/bin/signtool /usr/bin/signver /usr/bin/ssltap \
    /usr/bin/symkeyutil /usr/bin/shlibsign \
    /usr/bin/gnutls-cli /usr/bin/gnutls-cli-debug /usr/bin/gnutls-serv \
    /usr/bin/ocsptool /usr/bin/psktool \
    /usr/bin/nettle-hash /usr/bin/nettle-lfib-stream /usr/bin/nettle-pbkdf2 \
    /usr/bin/pkcs1-conv /usr/bin/sexp-conv \
    /usr/bin/sasldblistusers2 /usr/bin/saslpasswd2 \
    /usr/bin/fido2-assert /usr/bin/fido2-cred /usr/bin/fido2-token

# DV video / RDF / DRM test / misc dev
rm -f /usr/bin/dvconnect /usr/bin/dvcont /usr/bin/dubdv /usr/bin/encodedv \
    /usr/bin/serdi /usr/bin/sordi /usr/bin/sord_validate \
    /usr/bin/drmdevice /usr/bin/vbltest /usr/bin/modetest \
    /usr/bin/nbd-trdump /usr/bin/nbd-trplay /usr/bin/nbd-server \
    /usr/bin/bssh /usr/bin/bvnc \
    /usr/bin/fy-compose /usr/bin/fy-dump /usr/bin/fy-filter \
    /usr/bin/fy-join /usr/bin/fy-testsuite /usr/bin/fy-tool /usr/bin/fy-ypath \
    /usr/bin/uchardet /usr/bin/exiv2 /usr/bin/exempi \
    /usr/bin/lv2_validate /usr/bin/lv2specgen.py \
    /usr/bin/usbreset \
    /usr/bin/taglib-config /usr/bin/cups-config \
    /usr/bin/json-glib-format /usr/bin/json-glib-validate \
    /usr/bin/appstreamcli \
    /usr/bin/desktop-file-edit /usr/bin/desktop-file-install \
    /usr/bin/desktop-file-validate \
    /usr/bin/gpgscm /usr/bin/gpgme-json /usr/bin/gpgme-tool \
    /usr/bin/gpg-mail-tube /usr/bin/gpgparsemail \
    /usr/bin/spa-acp-tool /usr/bin/spa-inspect /usr/bin/spa-json-dump \
    /usr/bin/spa-monitor /usr/bin/spa-resample \
    /usr/bin/python3.14-config /usr/bin/python3-config /usr/bin/python-config \
    /usr/bin/idle /usr/bin/idle3 /usr/bin/idle3.14 \
    /usr/bin/pydoc /usr/bin/pydoc3 /usr/bin/pydoc3.14 \
    /usr/bin/grub-mkfont /usr/bin/grub-mklayout /usr/bin/grub-kbdcomp \
    /usr/bin/grub-macbless /usr/bin/grub-sparc64-setup \
    /usr/bin/grub-mkpasswd-pbkdf2 /usr/bin/grub-mknetdir \
    /usr/bin/grub-mkstandalone /usr/bin/grub-ofpathname \
    /usr/bin/grub-syslinux2cfg \
    /usr/bin/avahi-bookmarks /usr/bin/avahi-browse \
    /usr/bin/avahi-browse-domains /usr/bin/avahi-discover \
    /usr/bin/avahi-discover-standalone /usr/bin/avahi-dnsconfd \
    /usr/bin/avahi-publish /usr/bin/avahi-publish-address \
    /usr/bin/avahi-publish-service /usr/bin/avahi-resolve \
    /usr/bin/avahi-resolve-address /usr/bin/avahi-resolve-host-name \
    /usr/bin/avahi-set-host-name \
    /usr/bin/ibus /usr/bin/ibus-daemon /usr/bin/ibus-setup \
    /usr/bin/mysofa2json

# ── END DEBLOAT ─────────────────────────────────────────────────────────────────

# Rebuild initramfs so the patched hook is included!
mkinitcpio -P

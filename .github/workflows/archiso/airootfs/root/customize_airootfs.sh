#!/usr/bin/env bash
set -e

# Patch archiso initcpio hook to use originium.sfs instead of airootfs.sfs
sed -i 's/airootfs\.sfs/originium.sfs/g' /usr/lib/initcpio/hooks/archiso || true
sed -i 's/airootfs\.sha512/originium.sha512/g' /usr/lib/initcpio/hooks/archiso || true

# Rebuild initramfs so the patched hook is included!
mkinitcpio -P

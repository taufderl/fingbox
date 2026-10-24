#!/usr/bin/env bash
# Prepare and verify a full backup of the Fingbox eMMC exposed via U-Boot `ums`.
#   step 1: emmc-backup.sh /dev/sdX [image]  -> sanity-checks target, prints dd command
#   step 2: emmc-backup.sh --verify IMAGE    -> writes/checks sha256, lists partitions
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
img_default="$repo/captures/fingbox-emmc-$(date +%Y%m%d).img"

usage() {
  echo "usage: $0 /dev/sdX [image]   |   $0 --verify image"
}

[[ $# -ge 1 ]] || { usage; exit 1; }
[[ $1 == -h ]] && { usage; exit 0; }

if [[ $1 == --verify ]]; then
  img=${2:?image path required}
  [[ -s $img ]] || { echo "error: $img missing or empty" >&2; exit 1; }
  if [[ -f $img.sha256 ]]; then
    (cd "$(dirname "$img")" && sha256sum -c "$(basename "$img").sha256")
  else
    (cd "$(dirname "$img")" && sha256sum "$(basename "$img")" > "$(basename "$img").sha256")
    echo "wrote $img.sha256"
  fi
  fdisk -l "$img"
  dd if="$img" of="${img%.img}-first1M.bin" bs=1M count=1 status=none
  echo "saved first 1 MiB (boot0/SPL + U-Boot) to ${img%.img}-first1M.bin"
  echo "next: sudo losetup -Pfr --show $img  and mount the rootfs read-only"
  exit 0
fi

dev=$1
img=${2:-$img_default}
[[ -b $dev ]] || { echo "error: $dev is not a block device" >&2; exit 1; }

tran=$(lsblk -dno TRAN "$dev" || true)
size=$(lsblk -dbno SIZE "$dev")
lsblk -o NAME,SIZE,TRAN,VENDOR,MODEL,MOUNTPOINTS "$dev"

[[ $tran == usb ]] || { echo "error: $dev is not a USB device (TRAN=$tran)" >&2; exit 1; }
# the ums-exported eMMC is a few GB; refuse anything that looks like a real disk
(( size < 64 * 1000**3 )) || { echo "error: $dev is too big for the Fingbox eMMC" >&2; exit 1; }

mkdir -p "$(dirname "$img")"
echo
echo "run (reads only from $dev):"
echo "  sudo dd if=$dev of=$img bs=4M status=progress conv=fsync && sudo chown $USER: $img"
echo "then:"
echo "  $0 --verify $img"

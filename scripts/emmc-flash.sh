#!/usr/bin/env bash
# Sanity-check and print the command to write an image to the Fingbox eMMC
# exposed via U-Boot `ums`. Refuses to proceed without a verified backup.
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)

usage() {
  echo "usage: $0 image.img[.xz|.gz] /dev/sdX"
}

[[ ${1:-} == -h ]] && { usage; exit 0; }
[[ $# -eq 2 ]] || { usage; exit 1; }
img=$1 dev=$2

[[ -s $img ]] || { echo "error: $img missing" >&2; exit 1; }
[[ -b $dev ]] || { echo "error: $dev is not a block device" >&2; exit 1; }

shopt -s nullglob
backups=("$repo"/captures/fingbox-emmc-*.img.sha256)
(( ${#backups[@]} > 0 )) || {
  echo "error: no verified backup in captures/ (see docs/03-backup.md)" >&2; exit 1; }

tran=$(lsblk -dno TRAN "$dev" || true)
size=$(lsblk -dbno SIZE "$dev")
[[ $tran == usb ]] || { echo "error: $dev is not a USB device (TRAN=$tran)" >&2; exit 1; }
(( size < 64 * 1000**3 )) || { echo "error: $dev is too big for the Fingbox eMMC" >&2; exit 1; }
if lsblk -no MOUNTPOINTS "$dev" | grep -q .; then
  echo "error: $dev has mounted partitions; unmount them first" >&2; exit 1
fi

lsblk -o NAME,SIZE,TRAN,VENDOR,MODEL "$dev"
echo "backup(s): ${backups[*]}"
read -rp "type the device name ($(basename "$dev")) to confirm ERASING it: " answer
[[ $answer == "$(basename "$dev")" ]] || { echo "aborted"; exit 1; }

echo
echo "run:"
case $img in
  *.xz) echo "  xz -dc $img | sudo dd of=$dev bs=4M status=progress conv=fsync" ;;
  *.gz) echo "  gzip -dc $img | sudo dd of=$dev bs=4M status=progress conv=fsync" ;;
  *)    echo "  sudo dd if=$img of=$dev bs=4M status=progress conv=fsync" ;;
esac
echo "  sync"
echo "then Ctrl-C ums on the U-Boot console and run: reset"

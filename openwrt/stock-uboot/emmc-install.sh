#!/bin/sh
# Run on the Fingbox (OpenWrt in RAM). Writes /tmp/fingbox-emmc.img.gz to the
# eMMC while keeping the stock SPL/U-Boot region (8 KiB - 1 MiB) untouched.
set -e
img=/tmp/fingbox-emmc.img.gz
dev=""
for b in /sys/block/mmcblk*; do
	[ -e "$b/../$(basename "$b")boot0" ] || [ -e "/dev/$(basename "$b")boot0" ] && dev=/dev/$(basename "$b")
done
[ -n "$dev" ] || { echo "no eMMC with boot partitions found"; exit 1; }
echo "eMMC: $dev ($(cat /sys/block/$(basename $dev)/size) sectors)"
[ "${1:-}" = "--go" ] || { echo "dry run; pass --go to write"; exit 0; }
grep -q "^/dev/$(basename $dev)" /proc/mounts && { echo "$dev is mounted"; exit 1; }
# unpack first: dd skip= on a pipe skips short reads, not whole blocks
raw=/tmp/fingbox-emmc.img
gunzip -c $img > $raw
size=$(wc -c < $raw)
echo "writing partition table (sector 0-15)"
dd if=$raw of=$dev bs=512 count=16 conv=fsync 2>&1 | tail -1
echo "writing from 1 MiB onwards"
dd if=$raw of=$dev bs=1M skip=1 seek=1 conv=fsync 2>&1 | tail -1
sync
echo "verifying"
want=$(dd if=$raw bs=1M skip=1 2>/dev/null | md5sum | cut -d' ' -f1)
have=$(dd if=$dev bs=1M skip=1 count=$(( (size - 1048576 + 1048575) / 1048576 )) 2>/dev/null | head -c $(( size - 1048576 )) | md5sum | cut -d' ' -f1)
echo "image md5 $want, eMMC md5 $have"
[ "$want" = "$have" ] && echo VERIFY_OK || echo VERIFY_FAIL

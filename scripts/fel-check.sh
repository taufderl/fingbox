#!/usr/bin/env bash
# Check whether the Fingbox is in Allwinner FEL mode and print SoC info. Read-only.
set -euo pipefail

if [[ ${1:-} == -h ]]; then
  echo "usage: $0   (hold 'Uboot', plug micro-USB data cable, release, then run)"
  exit 0
fi

command -v sunxi-fel >/dev/null || { echo "error: install sunxi-tools" >&2; exit 1; }

if ! lsusb -d 1f3a:efe8 >/dev/null 2>&1; then
  echo "no FEL device (1f3a:efe8) on USB."
  echo "- data cable? (not charge-only)  - Uboot button held while plugging in?"
  echo "- micro-USB may be power-only: see docs/01-connect.md"
  exit 1
fi

lsusb -d 1f3a:efe8
sunxi-fel version
echo "SID: $(sunxi-fel sid)"

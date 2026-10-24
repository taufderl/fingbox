#!/usr/bin/env bash
# Open the Fingbox serial console and log everything to captures/.
set -euo pipefail

usage() {
  echo "usage: $0 [-b baud] <tty>   e.g. $0 /dev/ttyUSB0  (default 115200 8N1)"
}

baud=115200
while getopts "b:h" opt; do
  case $opt in
    b) baud=$OPTARG ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done
shift $((OPTIND - 1))
[[ $# -eq 1 ]] || { usage; exit 1; }
tty=$1
[[ -c $tty ]] || { echo "error: $tty is not a character device" >&2; exit 1; }

repo=$(cd "$(dirname "$0")/.." && pwd)
log="$repo/captures/uart-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$repo/captures"
echo "logging to $log  (power the Fingbox on now)"

if command -v tio >/dev/null; then
  exec tio -b "$baud" -d 8 -p none -s 1 -f none --log --log-file "$log" "$tty"
elif command -v picocom >/dev/null; then
  exec picocom -b "$baud" --flow n --logfile "$log" "$tty"
else
  echo "error: install tio or picocom" >&2; exit 1
fi

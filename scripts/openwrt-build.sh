#!/usr/bin/env bash
# Run a command inside the OpenWrt builder container with the OpenWrt tree mounted.
#   scripts/openwrt-build.sh make -j4 V=s
#   scripts/openwrt-build.sh ./scripts/feeds update -a
set -euo pipefail

if [[ ${1:-} == -h || $# -eq 0 ]]; then
  echo "usage: $0 <command...>   (OPENWRT_DIR defaults to ~/git/openwrt)"
  exit 0
fi

openwrt=${OPENWRT_DIR:-$HOME/git/openwrt}
image=fingbox-openwrt-builder
repo=$(cd "$(dirname "$0")/.." && pwd)

if ! docker image inspect "$image" >/dev/null 2>&1; then
  docker build --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" \
    -t "$image" "$repo/docker/openwrt-builder"
fi

mkdir -p "$HOME/.cache/openwrt-ccache"
tty=()
[[ -t 0 ]] && tty=(-it)
exec docker run --rm "${tty[@]}" \
  -v "$openwrt:/src" \
  -v "$HOME/.cache/openwrt-ccache:/home/builder/.ccache" \
  -e CCACHE_DIR=/home/builder/.ccache \
  "$image" "$@"

# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, etc.) working in this repo.

## Goal

Run current OpenWrt on the Fingbox (Allwinner H3) and get the device support
upstream into OpenWrt and Linux. Start at `README.md`; the verified state of the
hardware is in `docs/findings.md`, the OpenWrt work in `docs/07-openwrt.md`.

## Ground rules

- **Facts come from a unit.** Anything not in `docs/findings.md` is a hypothesis,
  whether it comes from teardowns, reference boards, other projects or chatbot
  summaries. Say whether a claim is verified before asking the user to act on it.
  When you learn something from a capture, add it to `docs/findings.md` with its
  source, then update the affected doc.
- **Never touch the vendor U-Boot** (eMMC 8 KiB–1 MiB). There is no FEL over
  micro-USB and no SD socket, so a broken bootloader cannot be recovered.
- **Never write to the eMMC without a verified backup** (image, sha256, loop-mount).
  Scripts that write must refuse to run without an explicit target and a confirmation.
- **Nothing private or proprietary in git.** Raw logs, dumps and stock files stay in
  `captures/` (git-ignored). No MAC addresses, serial numbers, network names,
  IP addresses, Tailscale details or credentials. Do not commit or publish Fing or
  Domotz files, including the Wi-Fi calibration file `eeprom_ar9271.bin`.
- Ask before rebooting or reflashing the device. The user handles anything
  physical (serial wiring, buttons, cables).

## Conventions

- Shell scripts: `bash`, `set -euo pipefail`, usage text on `-h`. No sudo inside
  scripts; when root is needed, print the command for the user instead.
- Docs: Markdown, one topic per file, commands in fenced blocks, unverified values
  marked **(unverified)**.
- OpenWrt builds run in the container from `docker/openwrt-builder` via
  `scripts/openwrt-build.sh`; the build config is `openwrt/fingbox.config`.
- Device support lives in the OpenWrt fork (`taufderl/openwrt`, branch `fingbox`).
  Upstream contributions disclose AI assistance (`Assisted-by:` tag).

## Key references

- OpenWrt fork: https://github.com/taufderl/openwrt (branch `fingbox`)
- linux-sunxi wiki: https://linux-sunxi.org/H3
- kuba2k2's Fingbox v1 port (no license, reference only):
  https://github.com/kuba2k2/alpine-custom-setup/tree/master/board/h3-fingbox-v1
- Teardown: https://goughlui.com/2018/06/21/mega-review-fingbox-network-security-and-troubleshooting-device/

# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, etc.) working in this repo.

## Goal

Replace the stock firmware of a Fingbox FIN-B-001 (Allwinner H3) with mainline
Linux on its eMMC. Start at `README.md`. The docs in `docs/` are numbered
`00` to `05` in the order to follow them.

## Ground rules

- **Facts come from our unit.** Anything not in `docs/findings.md` is a
  hypothesis, whether it comes from teardowns, reference boards or chatbot summaries. When you learn
  something from a capture, add it to `docs/findings.md` with the capture file
  it came from, then update the affected doc.
- **Never write to the eMMC before a verified backup exists.** Per `docs/03-backup.md`, that means
  an image, its sha256 and a successful loop-mount. Scripts that write must refuse to run
  without an explicit target device and a typed confirmation.
- **Never commit eMMC images, keys or stock credentials.** Raw dumps go in
  `captures/` (images are git-ignored). Small text logs may be committed.
- Treat the stock firmware as proprietary and don't publish extracted binaries.
- The user runs anything that touches hardware (serial, FEL, `dd`). Agents
  prepare commands and scripts and analyse the resulting logs.

## Conventions

- Shell scripts: `bash`, `set -euo pipefail`, usage text on `-h`. No sudo inside
  scripts. When root is needed, print the command for the user instead.
- Docs: Markdown, one topic per file, commands in fenced blocks, and unverified
  values marked **(unverified)**.
- The device tree lives in `dts/sun8i-h3-fingbox.dts`, derived from
  `sun8i-h3-nanopi-m1-plus.dts` in mainline Linux. Keep a header comment listing
  which nodes were verified on hardware.
- Pin mainline versions (U-Boot tag, kernel tag) in `docs/04-build.md`.

## Key references

- linux-sunxi wiki: https://linux-sunxi.org/H3, https://linux-sunxi.org/FEL,
  https://linux-sunxi.org/UART
- Mainline U-Boot `configs/nanopi_m1_plus_defconfig`
- Mainline Linux `arch/arm/boot/dts/allwinner/sun8i-h3-nanopi-m1-plus.dts`
- Teardown: https://goughlui.com/2018/06/21/mega-review-fingbox-network-security-and-troubleshooting-device/

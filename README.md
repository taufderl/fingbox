# fingbox: mainline Linux on the Fingbox

This repo holds everything needed to replace the stock Fing firmware on a **Fingbox (FIN-B-001)**
with our own mainline Linux (Debian/Armbian or Alpine) on its internal eMMC.

> Status: **probing.** The UART console works and the first stock boot log is captured.
> The stock box runs a mainline-based U-Boot 2017.01 (Orange Pi Plus 2E config, 2 s
> interruptible autoboot) and Ubuntu Core 16 built by Domotz. See
> [`docs/findings.md`](docs/findings.md).

## Hardware at a glance

| Part        | Value (source: teardown, unverified on our unit) |
|-------------|--------------------------------------------------|
| SoC         | Allwinner H3 (sun8i), 4× Cortex-A7, Mali-400 MP2 |
| RAM         | 2× Samsung K4B4G1646E DDR3 → 1 GiB               |
| Storage     | Samsung KLM8G… eMMC (KLM8G = 8 GB class; teardown says 1 GiB, so verify) |
| SD slot     | footprint present, **not populated**             |
| Ethernet    | Realtek RTL8211E gigabit PHY (H3 EMAC, RGMII)    |
| Wi-Fi       | Atheros AR9271 USB 802.11n (`ath9k_htc`)         |
| LEDs        | NXP PCA9635 I2C LED driver → logo ring           |
| EEPROM      | Atmel 24C02 (2 Kbit, I2C)                        |
| Buttons     | Power, Reset, **Uboot** (likely FEL), Recovery   |
| Debug       | 3-pin UART header (GND/TX/RX, 3.3 V)             |
| Power       | micro-USB 5 V / 2 A (possibly also USB-OTG → FEL)|

Closest mainline reference boards: **FriendlyElec NanoPi M1 Plus**
(H3 + RTL8211E + eMMC + 1 GiB) and **Orange Pi Plus 2E**. See
[`docs/00-hardware.md`](docs/00-hardware.md).

## Plan

1. **Connect:** UART console + FEL over USB → [`docs/01-connect.md`](docs/01-connect.md)
2. **Probe:** capture stock boot log, U-Boot env, partitions, I2C/GPIO map → [`docs/02-probing.md`](docs/02-probing.md)
3. **Back up:** full eMMC image before touching anything → [`docs/03-backup.md`](docs/03-backup.md)
4. **Build:** mainline U-Boot + kernel + `sun8i-h3-fingbox.dts` → [`docs/04-build.md`](docs/04-build.md)
5. **Flash:** write image to eMMC via FEL + U-Boot `ums` → [`docs/05-flashing.md`](docs/05-flashing.md)

The device stays recoverable as long as FEL works. The H3 boot ROM falls back to
FEL when it finds no bootable SPL, and the Uboot/FEL button forces it.

## Layout

```
docs/       step-by-step guides + findings log
scripts/    helper scripts (serial capture, FEL checks, backup, flash)
dts/        device tree for the Fingbox (written after probing)
captures/   raw logs/dumps from our unit (images are git-ignored)
```

## Shopping list

- 3.3 V USB-UART adapter (CP2102/FT232/CH340). It **must be 3.3 V, not 5 V**.
- 3 Dupont jumper wires (the header is already fitted)
- micro-USB **data** cable (for FEL/ums), plus a separate 5 V supply if the
  micro-USB port turns out to be power-only
- Host tools: `tio` or `picocom`, `sunxi-tools` (`sunxi-fel`), `dtc`,
  `arm-linux-gnueabihf` cross toolchain, `swig`, `python3-dev`, `bison`, `flex`

## Corrections to the Gemini summary

What the public sources actually say, compared with the chatbot summary we started from:

- The header is **3-pin** (GND/TX/RX) and already fitted, not "4-pin unpopulated".
- The stock OS is Ubuntu. An nmap scan showed OpenSSH `7.2p2 Ubuntu-4ubuntu2.2`,
  which is Ubuntu 16.04. "Ubuntu Core / snaps" is a guess, not confirmed.
- **SSH was seen open** on the LAN in that review, so "zero open inbound
  ports" is not accurate for at least some firmware versions.
- Luca Bongiorni did use the Fingbox UART in his *Focaccia-Board* write-up. The
  exact `init=/bin/sh` procedure is not confirmed, so verify it on our unit.
- The Fingbox v2 hardware has not been checked. This repo targets FIN-B-001.

Sources:
[Gough Lui teardown (2018)](https://goughlui.com/2018/06/21/mega-review-fingbox-network-security-and-troubleshooting-device/) ·
[Bongiorni: Focaccia-Board](https://lucabongiorni.medium.com/hacking-iot-devices-with-focaccia-board-8c4e009ed488) ·
[The Gadgeteer review](https://the-gadgeteer.com/2017/12/19/fingbox-review/) ·
[linux-sunxi H3](https://linux-sunxi.org/H3) · [linux-sunxi FEL](https://linux-sunxi.org/FEL)

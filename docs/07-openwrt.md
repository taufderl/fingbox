# 07 — OpenWrt for the Fingbox

Decision (2026-10-24): **OpenWrt** as the main OS. The box is meant to be a
VPN access point with Tailscale, and OpenWrt has firewall zones, policy routing,
hostapd, WireGuard and LED triggers built in. A Debian/Armbian build with the same
DT and Wi-Fi patch stays an option for later.

Prior art: kuba2k2's Alpine/Buildroot port
(https://github.com/kuba2k2/alpine-custom-setup/tree/master/board/h3-fingbox-v1)
documented the LED controllers, buttons and the AR9271 EEPROM problem. That repo
has no license, so our DT and patches are written from scratch and checked
against the stock Domotz DT (`captures/stock/`).

## Source

- Fork: https://github.com/taufderl/openwrt, branch `fingbox`
- Local clone: `~/git/openwrt` (`origin` = fork, `upstream` = openwrt/openwrt, push disabled)

| File in the fork | Purpose |
|---|---|
| `target/linux/sunxi/patches-6.18/313-ARM-dts-sun8i-h3-add-Fingbox.patch` | `sun8i-h3-fingbox.dts`: EMAC + RTL8211E, eMMC, I2C1 with 24C02 (MAC NVMEM cells), PCA9633/PCA9635 LED ring, gpio LEDs/keys, AR9271 node on EHCI3 |
| `package/kernel/mac80211/patches/ath9k/560-ath9k_htc-load-EEPROM-from-firmware-file-via-DT.patch` | `ath9k_htc`: `qca,no-eeprom` + `firmware-name` loads calibration with `request_firmware()`; MAC from DT |
| `package/boot/uboot-sunxi/Makefile` | U-Boot target `fingbox` (built from `orangepi_plus2e_defconfig`, same as the stock bootloader) |
| `target/linux/sunxi/image/cortexa7.mk` | Device `fing_fingbox` |
| `target/linux/sunxi/base-files/etc/board.d/01_leds` | LED defaults: ring LED 2 = Ethernet, ring LED 3 = Wi-Fi |

## Wi-Fi calibration file (not redistributable)

The AR9271 has no EEPROM. Its calibration data comes from the stock firmware
(`domotz-platform-kernel` snap, `firmware/eeprom_ar9271.bin`, 1024 bytes,
sha256 `c3b54f3b…f34a`). It must be supplied by the user:

```sh
mkdir -p ~/git/openwrt/files/lib/firmware/ath9k_htc
cp captures/stock/eeprom_ar9271.bin ~/git/openwrt/files/lib/firmware/ath9k_htc/fingbox-eeprom.bin
```

`files/` is git-ignored in OpenWrt, so the blob is baked into local images only.

## Build

All builds run in Docker (`docker/openwrt-builder`), so nothing is installed on the host:

```sh
scripts/openwrt-build.sh ./scripts/feeds update -a
scripts/openwrt-build.sh ./scripts/feeds install -a
cp openwrt/fingbox.config ~/git/openwrt/.config
scripts/openwrt-build.sh make defconfig
scripts/openwrt-build.sh make -j4
```

Result: `bin/targets/sunxi/cortexa7/openwrt-sunxi-cortexa7-fing_fingbox-squashfs-sdcard.img.gz`.

## Install to eMMC

From the Armbian USB system (`06-usb-boot.md`), with the backup verified:

```sh
scp -i ~/.ssh/id_ed25519_fingbox <image>.img.gz root@10.42.0.2:/tmp/
ssh -i ~/.ssh/id_ed25519_fingbox root@10.42.0.2 \
  'gunzip -c /tmp/<image>.img.gz | dd of=/dev/mmcblk2 bs=4M conv=fsync'
```

OpenWrt then boots from eMMC with LAN on `eth0` at 192.168.1.1.

## Recovery

- New U-Boot/SPL broken → FEL (hold UBOOT, micro-USB to PC), see `05-flashing.md`.
- Restore stock: write `captures/fingbox-emmc-20261024.img` back to the eMMC.

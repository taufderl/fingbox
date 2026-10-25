# fingbox: OpenWrt on the Fingbox

The **Fingbox** (Fing / Domotz network monitoring appliance) is an Allwinner H3
board with 1 GiB RAM, 8 GB eMMC, gigabit Ethernet and an AR9271 Wi-Fi chip. Its
cloud service is history, its stock firmware (Ubuntu Core 16, kernel 4.9) no longer
gets updates. This repo documents how to replace it with current **OpenWrt** and
keeps the tooling and notes from the bring-up.

> Status: **OpenWrt (main, kernel 6.18) runs from eMMC** on a real unit, booted
> by the untouched vendor U-Boot. Ethernet, Wi-Fi client and access point, the
> RGB LED ring, the reset button, Tailscale and LuCI work.
> Device support lives in a fork of OpenWrt and is being prepared for upstream.

## Hardware (verified on a unit)

| Part | Details |
|---|---|
| SoC | Allwinner H3, 4× Cortex-A7 |
| RAM | 1 GiB DDR3 (2× Samsung K4B4G1646E) |
| Storage | 8 GB Samsung eMMC (7.28 GiB), no SD socket (footprint only) |
| Ethernet | RTL8211E gigabit PHY on the H3 EMAC |
| Wi-Fi | AR9271 (USB, 2.4 GHz, 1×1), **no EEPROM**: calibration data comes from the stock firmware |
| EEPROM | 24C02 on I2C1, holds the Ethernet and Wi-Fi MAC addresses |
| LEDs | RGB ring of 6 LEDs (PCA9633 + PCA9635 on I2C1), white and green LED on the board |
| Buttons | pin-hole "Reset" on the case (PL4); board buttons RESET (resets the SoC), POWER (not on a GPIO), UBOOT |
| Serial | 3-pin header next to a mounting hole: GND, TX (middle), RX; 115200 8N1, 3.3 V |
| USB | USB-A host port; micro-USB is **power only** (no FEL) |
| Bootloader | vendor U-Boot 2017.01 (Orange Pi Plus 2E config), no FIT support, `bootz`, distro boot, TFTP |

Details and sources for every line: [`docs/findings.md`](docs/findings.md).

## Installing OpenWrt

Because the micro-USB port has no data lines, FEL recovery is not available and
there is no SD socket. The install therefore **never replaces the vendor U-Boot**:

1. Open the case and attach a 3.3 V serial adapter to the header.
2. Interrupt U-Boot (press a key within 2 s) and boot the OpenWrt initramfs over
   TFTP: `tftpboot 0x46000000 <initramfs>; bootz 0x46000000`.
3. In the running OpenWrt, `sysupgrade` the sdcard image. The Fingbox upgrade
   code writes only the partition table and partitions, never 8 KiB–1 MiB.
4. Copy the Wi-Fi calibration file from your own stock firmware (see below).

The full walk-through, including making a complete eMMC backup first, is in
[`docs/07-openwrt.md`](docs/07-openwrt.md).

### Wi-Fi calibration data

The AR9271 has no EEPROM. Domotz shipped its calibration data as
`eeprom_ar9271.bin` in the stock kernel snap. That file is not redistributed
here. Extract it from your own unit's backup and place it at
`/lib/firmware/ath9k_htc/fingbox-eeprom.bin`, then add that path to
`/etc/sysupgrade.conf` so it survives updates.

## Repository layout

```
docs/       bring-up notes in the order they were written, plus findings.md
openwrt/    OpenWrt build config and the stock-U-Boot install helpers
docker/     container with the OpenWrt build dependencies
scripts/    serial capture, backup, flash and build helpers
captures/   local only: logs, dumps and stock files are never committed
```

The early notes (`docs/00`–`05`) assumed FEL recovery over micro-USB. That turned
out to be wrong for this hardware; `findings.md` has the verified state,
`docs/07-openwrt.md` the OpenWrt install, `docs/08-deployment.md` the live
AP + transparent-proxy deployment, and `docs/NEXT-STEPS.md` what remains.

## Related work

- OpenWrt fork with the device support: <https://github.com/taufderl/openwrt> (branch `fingbox`)
- kuba2k2's Alpine/Buildroot port for the Fingbox v1, which documented the LED
  controllers and the Wi-Fi EEPROM problem first:
  <https://github.com/kuba2k2/alpine-custom-setup/tree/master/board/h3-fingbox-v1>
- Teardown with board photos by Gough Lui (2018):
  <https://goughlui.com/2018/06/21/mega-review-fingbox-network-security-and-troubleshooting-device/>

## Disclaimer

Not affiliated with Fing or Domotz. Opening the case voids whatever warranty is
left, and writing to the eMMC can brick the device. No Fing or Domotz software
is included in this repository.

Parts of this work were done with the help of an AI coding assistant (Claude);
every change was reviewed and tested on hardware.

## License

[MIT](LICENSE)

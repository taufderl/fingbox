# 00 — Hardware

Model: **Fingbox FIN-B-001** (2017/2018). Everything below is from the
[Gough Lui teardown](https://goughlui.com/2018/06/21/mega-review-fingbox-network-security-and-troubleshooting-device/)
unless marked otherwise and is **(unverified)** until it appears in
[`findings.md`](findings.md).

## Components

| Function  | Part | Mainline Linux support |
|-----------|------|------------------------|
| SoC       | Allwinner H3 (sun8i-h3) | Excellent (`sun8i-h3.dtsi`) |
| DRAM      | 2× Samsung K4B4G1646E-BCMA DDR3, 4 Gbit each → 1 GiB | U-Boot SPL `CONFIG_DRAM_*` (clock must be tuned) |
| eMMC      | Samsung KLM8G… | `sunxi-mmc` on MMC2 controller, 8-bit |
| Ethernet  | Realtek RTL8211E, RGMII, gigabit | `dwmac-sun8i` external PHY (as NanoPi M1 Plus / OPi Plus 2E) |
| Wi-Fi     | Atheros AR9271-AL3A (USB) | `ath9k_htc` + `htc_9271.fw` from linux-firmware |
| LED ctrl  | NXP PCA9635 (I2C) | `leds-pca963x` |
| EEPROM    | Atmel 24C02N (I2C, 256 bytes) | `at24`, may contain MAC/serial |
| PMIC/reg  | "AXP8036" per teardown (likely a buck regulator, not an X-Powers PMIC) | check: H3 boards normally use SY8106A or GPIO-switched regulators |
| USB-A     | Vertical host port | `ehci/ohci` |
| micro-USB | 5 V input, **may** be wired to USB-OTG (needed for FEL) | `musb` |

Notes:
- The teardown lists the eMMC as 1 GiB, but the `KLM8G` prefix denotes an 8 GB
  part. Read the full marking off the chip, or use `mmc info` in U-Boot.
- The 24C02 is 2 Kbit (256 bytes), not 256 KiB as the teardown says.
- The SD-card footprint is unpopulated. Fitting a micro-SD socket (e.g. Hirose
  DM3AT) gives a second recovery path, because the H3 boot ROM tries SD first.

## Buttons

| Label (PCB) | Expected function |
|-------------|-------------------|
| Power       | Probably PMIC/regulator enable or GPIO |
| Reset       | SoC reset (`RESET#`) |
| **Uboot**   | Probably the **FEL** pin (forces the boot ROM into USB FEL mode) |
| Recovery (on the case edge, labelled "Reset") | Probably a GPIO read by the stock software (factory reset) |

## Boot order of the H3 boot ROM (BROM)

1. SD card on MMC0 (footprint is unpopulated)
2. eMMC on MMC2: SPL (eGON header) at **8 KiB offset** of the user area
3. SPI NOR flash (not fitted, as far as we know)
4. **FEL** USB mode on the OTG port

If FEL is held (Uboot button), the ROM goes straight to FEL. Because of this fallback order,
the board can always be recovered over USB, provided the micro-USB port carries
OTG data lines.

## Reference boards to borrow from

| Board | Why |
|-------|-----|
| FriendlyElec NanoPi M1 Plus | H3, RTL8211E, eMMC, 1 GiB DDR3. Closest match |
| Xunlong Orange Pi Plus 2E   | H3, RTL8211E, eMMC, has a "UBOOT" (FEL) button like ours |

Mainline files:
- U-Boot: `configs/nanopi_m1_plus_defconfig`, `configs/orangepi_plus2e_defconfig`
- Linux: `arch/arm/boot/dts/allwinner/sun8i-h3-nanopi-m1-plus.dts`,
  `sun8i-h3-orangepi-plus2e.dts`

## Things only probing can tell us

- UART pin order and voltage
- Whether micro-USB is OTG (FEL works) or power-only
- Ethernet PHY address, reset GPIO, RGMII TX/RX delays
- eMMC bus width and voltage (1.8 V vs 3.3 V), eMMC reset pin
- I2C bus/address of the PCA9635 and 24C02, LED channel → colour mapping
- GPIOs for Power/Recovery buttons, AR9271 power enable
- DRAM timings that the stock boot0/SPL uses (clock, ZQ, ODT)

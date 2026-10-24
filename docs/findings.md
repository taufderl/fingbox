# Findings on our unit

Verified facts only. Each entry names the date, what was observed, and the source
capture in `captures/`.

| Date | Topic | Observation | Source |
|------|-------|-------------|--------|
| 2026-10-24 | UART | Works at 115200 8N1 via Tigard (3V3). TX/RX had to be swapped versus the first wiring: **middle pin = Fingbox TX**, outer pin = Fingbox RX, pin by mounting hole = GND (confirm) | `uart-20261024-163923.log` |
| 2026-10-24 | Case | 3 security-Torx screws, 6-lobe with pin; TR6 slips and TR7 doesn't fit. Board screws look similar. Case was sawn open. Board side facing the opened case = back side (UBOOT/POWER/RESET buttons); header solder joints are reachable there | user |
| 2026-10-24 | SPL | `U-Boot SPL 2017.01 (Jun 01 2017)`, `DRAM: 1024 MiB`, `Trying to boot from MMC2` (SPL on eMMC). "Failed to set core voltage" (no PMIC, harmless) | same |
| 2026-10-24 | U-Boot | Mainline-based `U-Boot 2017.01 … Allwinner Technology`, **Model: Xunlong Orange Pi Plus 2E**, vendor patches tagged `DOMOTZ:`. **Autoboot 2 s, "Hit any key"**, so the console can be interrupted. Env from `uboot.env` (FAT) | same |
| 2026-10-24 | Boot flow | `mmc 0:1` → `/boot.scr` (3193 B) → reads MAC from EEPROM → `gpio set pa17` → loads `domotz-platform-kernel_9.snap/{kernel.img,initrd.img,dtbs/sun8i-h3-domotz-fingbox-v2.dtb}` | same |
| 2026-10-24 | EEPROM | Soft I2C (U-Boot) on **PA18/PA19**, bus `soft00`. Offset 0: eth MAC (`f0:23:b9:…`), offset 6: Wi-Fi MAC, rest `ff` | same |
| 2026-10-24 | Buttons | Factory-reset pin IDs printed by U-Boot (low 2113543692 / high 292); meaning TBD | same |
| 2026-10-24 | Kernel | `4.9.5-domotz-platform+` (built by Domotz, Ubuntu Xenial toolchain, Jan 2019). DT model "Domotz Platform". Cmdline: `root=/dev/disk/by-label/writable … snap_core=core_10957.snap snap_kernel=domotz-platform-kernel_9.snap panic=-1 ath9k_htc.domotz_ath_hwaddr=…` | same |
| 2026-10-24 | OS | **Ubuntu Core 16** (snaps): `fingbox-agent` (rev 192/193/195), `domotz-platform`, `domotz-kevin`, `dnsfwd`, `carl`, `core`. systemd 229. A serial getty is started on ttyS0 | same |
| 2026-10-24 | eMMC | `mmcblk1`: **7.28 GiB**, name `8WPD3R`, DDR mode; hardware `boot0`/`boot1` 4 MiB each; partitions p1 (FAT `system-boot`), p2, p3 (ext4 `writable`). In U-Boot the eMMC is reached as `mmc 0` (SD slot empty) | same |
| 2026-10-24 | SD slot | Kernel `sunxi-mmc 1c0f000.mmc: Got CD GPIO`, so the SD controller and card-detect are configured although the socket is unpopulated | same |
| 2026-10-24 | USB OTG | `musb-hdrc` present, DT has `usb0_id_detect_pin` and `usb0_vbus` → micro-USB is very likely wired to OTG (FEL plausible) | same |
| 2026-10-24 | Wi-Fi | AR9271 on internal USB (`0cf3:9271`, EHCI 1c1d000) | same |
| 2026-10-24 | Ethernet | `sun8i-emac 1c30000.ethernet`, "phy interface7" (RGMII), PHY regulator `gmac-3v3` | same |
| 2026-10-24 | Regulators | DT has `reg_led-3v3`, `gmac-3v3`, `usb0-vbus`, `vcc3v0`, `vcc5v0` | same |

| 2026-10-24 | U-Boot console | Interrupt works (press Enter during the 2 s countdown). Toolchain Linaro GCC 4.9-2016.02 | `uart-20261024-164216.log` |
| 2026-10-24 | U-Boot cmds | **No `ums`, `fastboot` or `dfu`.** Present: `usb`, `usbboot`, `sysboot` (extlinux), `bootz`, `bootefi`, `dhcp`/`tftpboot`/`pxe`/`nfs`, `mmc`, `part`, `fatls/fatload/fatwrite`, `ext4ls/ext4load`, `i2c`, `gpio`, `fdt`, `md`/`mw`, `loadx/loady` | same |
| 2026-10-24 | U-Boot env | Distro boot: `boot_targets=fel mmc0 mmc1 usb0 pxe dhcp`, `boot_scripts=boot.scr.uimg boot.scr`, `boot_prefixes=/ /boot/`, extlinux and EFI supported. `fdtfile=sun8i-h3-domotz-fingbox-v2.dtb`, `bootdelay=2`. Snappy A/B via `snap_mode`/`snap_try_*` with `saveenv` to `uboot.env` on FAT p1. `ethaddr` set in env. `serial#` is a device ID (not recorded here) | same |

| 2026-10-24 | eMMC (U-Boot) | `mmc list`: `SD/MMC: 1`, `SD/MMC: 0 (eMMC)` → **eMMC = `mmc 0`** in stock U-Boot. MMC 5.0, mfr 0x15 (Samsung), name `8WPD3`, 8-bit, 52 MHz, user 7.3 GiB, boot partitions 4 MiB, RPMB 512 KiB | `uart-20261024-164216.log` |
| 2026-10-24 | Partitions | DOS table. p1 FAT (0x0c, bootable) start 524288 (256 MiB), 262144 sectors (128 MiB). p2 Linux start 786432, 3145728 sectors (1.5 GiB, purpose TBD). p3 Linux (`writable`) start 3932160, 11337372 sectors (~5.4 GiB). **First 256 MiB unpartitioned**: SPL at 8 KiB + U-Boot | same |

| 2026-10-24 | USB boot | Stock U-Boot reads USB sticks on the USB-A port (`usb start`, `fatls usb 0:1`). **Armbian 26.11 (Orange Pi+ 2E, trixie, kernel 6.18.57) boots from USB** with the manual commands in `06-usb-boot.md`. U-Boot 2017.01 reads its ext4 (64bit, metadata_csum_seed) fine | `uart-20261024-170951.log` |
| 2026-10-24 | Mainline Linux | DT model "Xunlong Orange Pi Plus 2E" works: eMMC = `mmcblk2` (+ `boot0`/`boot1`), 991 MiB RAM, AR9271 enumerates on USB bus 4, **Ethernet `end0` works** (dwmac-sun8i, external PHY at `mdio_mux-0.2:01`, Generic PHY driver, rgmii-id), MAC from SID equals stock MAC `f0:23:b9:…`. GPIOs in use: PA15 red LED, PD6 `gmac-3v3`, PL2 usb0-vbus, PL3 `sw4` key, PL10 green LED | same |
| 2026-10-24 | USB stick | The 7.4 GB Phison stick shows `critical medium error` near its end, so it isn't trusted for data | same |
| 2026-10-24 | **Backup** | Full eMMC user area pulled over ssh: `captures/fingbox-emmc-20261024.img`, 7818182656 bytes, sha256 `9c329c2b51302a1bf0626fa12b435462773dd8fa4507062738cf71ac89d446ae`, **identical to `sha256sum /dev/mmcblk2` on the device**. `boot0`/`boot1` are all zeros (unused) | user terminal |

| 2026-10-24 | FEL / micro-USB | Holding UBOOT while powering via micro-USB keeps the console silent (boot ROM in FEL), but **the PC never sees a USB device** with 3 different cables, on a hub and directly on the laptop. The micro-USB port on this unit is power-only, so **FEL recovery is not available**. Plugging in briefly resets a shared USB hub (inrush) | user |
| 2026-10-24 | Buttons | Not yet verified: no button press observed during a 60 s GPIO watch on PL0–PL11 | btnwatch |

| 2026-10-24 | Stock U-Boot | **No FIT support** (`iminfo`: "Unknown image format"), but `bootz` + separate DTB, `tftpboot`, `load usb`, `fatwrite` work. Env file `uboot.env` on FAT p1 uses the **redundant format** (CRC + flags byte, 131072 bytes). Stock bootloader occupies 8–456 KiB of the eMMC; raw stock data (recovery?) also at 2–145 MiB outside partitions | `uart-20261024-222359.log`, backup scan |
| 2026-10-24 | Buttons | Internal **RESET = hardware SoC reset** (no kernel message). External pin-hole button and internal POWER: registered as gpio-keys PL4/PL0, not yet confirmed | serial log |
| 2026-10-24 | LEDs | Ring LEDs 1→6 run **clockwise**; all 18 channels + PL10 white + PA15 green work under OpenWrt (colour order per LED not confirmed) | user |
| 2026-10-24 | **OpenWrt** | main @ b5bc4becb4 + fork `taufderl/openwrt:fingbox`, kernel 6.18.55, installed on eMMC **keeping the stock U-Boot** (zImage + DTB + bootz `boot.scr` + `uboot.env` in p1). Ethernet, Wi-Fi (AR9271 with calibration file, MACs from 24C02), LEDs, Tailscale 1.104.1 and LuCI verified; survives reboot | ssh |
| 2026-10-24 | Wi-Fi radio path | USB bus number of the AR9271 changes between boots (`usb3` vs `usb2`), so OpenWrt's path-based radio config breaks after reboot. Workaround: `wireless.radio0.phy='phy0'` instead of `path` | ssh |

Note on the DTB name: `sun8i-h3-domotz-fingbox-v2` suggests this unit is a
**Fingbox v2** hardware revision, or that Domotz versioned the DT. Check the label
on the case.

## Unit

- Label / model:
- Serial:
- PCB marking / revision:
- Stock firmware: Ubuntu Core 16, kernel snap `domotz-platform-kernel_9`, `fingbox-agent` rev 195

## Open questions

- Confirm UART pin order with a multimeter (middle = TX?)
- Interrupt U-Boot: `printenv`, `help` (is `ums` / `fastboot` compiled in?), `mmc info`
- Does FEL work over micro-USB with the UBOOT button?
- Copy `/boot.scr` and the stock DTB (`sun8i-h3-domotz-fingbox-v2.dtb`) off the box
- Root login on ttyS0? (Ubuntu Core normally has no local password users)

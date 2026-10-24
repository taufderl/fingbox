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

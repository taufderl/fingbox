# 05 — Flashing our Linux to the eMMC

**Prerequisite:** a verified backup (`03-backup.md`). FEL must be confirmed working,
because it is the recovery path if the new image doesn't boot.

## Smoke test first

Before writing our own image, test a known image for the closest board:

1. Download the Armbian (or other) image for **NanoPi M1 Plus**.
2. Flash it to the eMMC (below), boot, watch the UART.
3. Note what works (DRAM, eMMC, Ethernet, USB, Wi-Fi) in `findings.md`.

The first write can also be our own FEL-tested U-Boot plus that rootfs.

## Write via FEL + `ums`

1. Enter FEL and load the tested U-Boot into RAM:
   ```sh
   sunxi-fel -v uboot build/u-boot-sunxi-with-spl.bin
   ```
2. On the UART console: stop autoboot, then `ums 0 mmc 1` (use the eMMC index found
   during probing).
3. On the PC:
   ```sh
   scripts/emmc-flash.sh path/to/image.img /dev/sdX
   ```
   The script checks that the target is a ~8 GB USB disk, shows `lsblk`, asks
   for typed confirmation, and prints the `dd` command to run with sudo.
4. On the console, `Ctrl-C` ends `ums`. Then `reset`.

The image must contain `u-boot-sunxi-with-spl.bin` at **8 KiB offset**. Armbian
and our build both do this. To update only the bootloader:
```sh
sudo dd if=build/u-boot-sunxi-with-spl.bin of=/dev/sdX bs=1k seek=8 conv=fsync
```

## Alternative: from U-Boot over Ethernet

If `ums` isn't available but U-Boot plus Ethernet work, use this path. It suits small images and
the bootloader:
```
setenv serverip <pc-ip>; dhcp
tftp ${kernel_addr_r} u-boot-sunxi-with-spl.bin
mmc dev 1
mmc write ${kernel_addr_r} 0x10 0x800     # 8 KiB = sector 16 (0x10), 1 MiB worth
```
Full rootfs images are better written via `ums` or from a running Linux.

## Recovery

- New image doesn't boot: hold **Uboot**, plug in USB, and the ROM enters FEL.
  Run `sunxi-fel uboot ...`, then `ums`, then restore the backup or fix the image.
- If the eMMC SPL is valid but broken (hangs before FEL check), FEL via the
  button still works because the ROM checks the FEL pin first.
- Last resort: short the eMMC CLK or DAT0 to GND during power-up so the ROM
  can't read the SPL and falls back to FEL. Find the test points from the photos.

## After first boot

- Set the MAC: mainline derives it from the SoC SID, so it is stable but differs from
  stock. Copy the stock MAC from the 24C02 or the backup if wanted.
- Disable everything that isn't needed. This box will sit on the LAN.

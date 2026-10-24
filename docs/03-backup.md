# 03 — Full eMMC backup

**Do not flash anything until this is done and verified.** Without the backup there
is no way back to stock.

## Method A: FEL + U-Boot `ums` (preferred)

`ums` (USB Mass Storage) makes U-Boot expose the eMMC to the PC as a USB disk.
You need a mainline U-Boot with `CONFIG_CMD_USB_MASS_STORAGE=y` and
`CONFIG_USB_MUSB_GADGET=y`, built per `04-build.md`.

1. Enter FEL (hold Uboot, plug in micro-USB).
2. Start the UART console (`scripts/uart-capture.sh`).
3. Load U-Boot into RAM:
   ```sh
   sunxi-fel -v uboot build/u-boot-sunxi-with-spl.bin
   ```
4. Stop autoboot on the console, then:
   ```
   mmc list          # find the eMMC (usually mmc 1 with SD unpopulated → check)
   ums 0 mmc 1
   ```
5. A new block device appears on the PC (`lsblk`, ~7.3 GiB). Note its path (e.g. `/dev/sdX`).
6. Dump and verify:
   ```sh
   scripts/emmc-backup.sh /dev/sdX
   ```
   The script prints the `dd` command for you to run with sudo, then writes a sha256
   next to the image and lists the partitions.

`ums` only exposes the **user area**. The eMMC hardware boot partitions
(`boot0`/`boot1`) and the RPMB partition are not included. The H3 ROM boots from the user
area, so they are probably unused. Check `mmc info` (`Boot partition size`) and,
if they are non-zero, also dump them from stock Linux (`/dev/mmcblkXboot0`) or with
U-Boot `mmc partconf` plus `ums`.

## Method B: from the stock Linux shell

If FEL doesn't work but a root shell does (`02-probing.md` step 3), stream the
eMMC over the network:
```sh
# on PC
nc -l 9000 > captures/fingbox-emmc-$(date +%Y%m%d).img
# on Fingbox
dd if=/dev/mmcblk1 bs=1M | nc <pc-ip> 9000
```
Or use `ssh` if the stock sshd is reachable.

## Verify

```sh
scripts/emmc-backup.sh --verify captures/fingbox-emmc-<date>.img
# writes/checks .sha256, runs fdisk -l, saves the first 1 MiB (boot0 + U-Boot)
sudo losetup -Pf --show -r captures/fingbox-emmc-<date>.img   # -r = read-only
sudo mount -o ro /dev/loopNp<rootfs> /mnt && ls /mnt && sudo umount /mnt
```
Keep at least two copies off the PC. Images are git-ignored and must never be committed.

## Restore

The procedure is the same as flashing (`05-flashing.md`), with the backup image as the
source.

# 06 — Boot Armbian from a USB stick (no eMMC writes)

The stock U-Boot (2017.01, Orange Pi Plus 2E config) can read USB sticks on the
USB-A port. It can boot an Armbian image for the **Orange Pi Plus 2E** from a stick
without touching the eMMC. From that Linux we make the eMMC backup and later install.

Verified: `usb start` / `usb storage` / `fatls usb 0:1` work in stock U-Boot
(`findings.md`).

## 1. Write the image to the stick (PC)

Image: Armbian community, Debian 13 trixie minimal, kernel 6.18 `current`, from
https://www.armbian.com/boards/orangepiplus2e (checksum via the `.sha` link).

```sh
lsblk -o NAME,SIZE,TRAN,MODEL      # identify the stick, e.g. /dev/sdb (TRAN=usb)
xz -dc ~/Downloads/fingbox/Armbian_community_*_Orangepiplus2e_trixie_current_*_minimal.img.xz \
  | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

## 2. Boot it from the stock U-Boot (UART)

The stock env has no `usb_boot` script, so `run bootcmd_usb0` fails. Boot by hand
after interrupting autoboot. Nothing here is saved (**no `saveenv`**):

```
usb start
setenv devtype usb
setenv devnum 0
setenv prefix /boot/
setenv fdtfile sun8i-h3-orangepi-plus2e.dtb
load usb 0:1 ${scriptaddr} /boot/boot.scr
source ${scriptaddr}
```

Armbian's `boot.scr` loads `armbianEnv.txt`, then `uInitrd`, `zImage` and
`dtb/sun8i-h3-orangepi-plus2e.dtb`, and boots with `root=UUID=…`.

Load addresses in the stock env: kernel `0x42000000`, fdt `0x43000000`, ramdisk
`0x43300000`, Armbian `load_addr` `0x45000000`. The 6.18 zImage (~10.5 MB) ends
below the fdt, so they don't overlap.

## 3. First login

Armbian's first-boot wizard runs on the serial console (set the root password,
create a user). Then check:

```sh
cat /proc/device-tree/model; uname -a
lsblk                      # eMMC should be mmcblk1 or mmcblk2
ip -br link; ip -br addr   # end0/eth0 up?
lsusb                      # AR9271 (0cf3:9271)
```

## If it fails

| Symptom | Likely cause | Try |
|---|---|---|
| `** File not found /boot/boot.scr **` / ext4 errors | U-Boot 2017 can't read the new ext4 (64bit, metadata_csum_seed) | Load files manually with `ext4load`, or repartition the stick with a small FAT `/boot` |
| Hang after `Starting kernel ...` | Console or DT mismatch | `setenv extraargs earlycon=uart,mmio32,0x01c28000` before `source` (set it after `armbianEnv.txt` import, e.g. via `armbianEnv.txt`) |
| Boots, but no Ethernet | Fingbox PHY power/reset differs from OPi Plus 2E | Compare with the stock DTB (`sun8i-h3-domotz-fingbox-v2.dtb`), write `dts/sun8i-h3-fingbox.dts` |

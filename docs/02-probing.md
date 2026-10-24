# 02 — Probing

Goal: learn enough from the **stock** system to write a correct device tree and
DRAM config, without writing anything to the eMMC. Save every capture in
`captures/` and summarise it in [`findings.md`](findings.md).

## Step 1: passive boot log

```sh
scripts/uart-capture.sh /dev/ttyUSB0
# then power on the Fingbox and let it boot fully, ~2 min
```

Look for:
- boot0/SPL banner, **DRAM clock and size** (`DRAM CLK = ...`, `dram size = ...`)
- U-Boot version and whether a `Hit any key to stop autoboot` prompt appears
- `bootcmd` / `bootargs`, kernel version, root device (`/dev/mmcblkXpY`)
- Partition table printed by the kernel
- Login prompt (and whether getty runs on ttyS0)

## Step 2: U-Boot console

Reboot and press a key (or spam `Enter`, `Space`, `s`) during the autoboot countdown.
The magic key varies by BSP; the boot log shows it. Then run:

```
version
bdinfo
printenv
mmc list
mmc dev 1        # or 0/2, whichever is the eMMC
mmc info         # capacity, bus width, voltage
mmc part
fdt addr ${fdtcontroladdr}; fdt print /   # if fdt cmd exists
i2c dev 0; i2c probe   # repeat for buses 1, 2
md.l 0x01c20800 0x40  # PIO register dump (pinmux)
```

Copy the full session into `captures/uboot-<date>.log`.

Do **not** run `saveenv`, `mmc write`, `erase`, or `env default -a; saveenv`.

## Step 3: root shell (read-only investigation)

Only needed if the stock Linux has information U-Boot can't give (pin usage,
regulators, loaded drivers). Option A first:

**A. Log in on the console.** Check whether a getty runs on ttyS0. Note any credentials found in
public research in `findings.md`, but don't commit them.

**B. Single-user via bootargs** (non-persistent, RAM only):
```
setenv bootargs ${bootargs} init=/bin/sh
boot                  # or run the stock bootcmd manually; do NOT saveenv
```
Then mount read-only to look around:
```sh
mount -t proc proc /proc; mount -t sysfs sys /sys
mount -o remount,ro /
```

Collect:
```sh
uname -a; cat /proc/cpuinfo; cat /proc/meminfo
cat /proc/partitions; ls -l /dev/mmcblk*; cat /proc/cmdline
cat /sys/kernel/debug/pinctrl/*/pinmux-pins 2>/dev/null
cat /sys/kernel/debug/gpio 2>/dev/null
ls /sys/bus/i2c/devices/; for d in /sys/bus/i2c/devices/*; do echo "$d $(cat $d/name 2>/dev/null)"; done
cat /proc/device-tree/model 2>/dev/null
dmesg
lsmod; lsusb 2>/dev/null
ip link; cat /sys/class/net/eth0/address
hexdump -C /sys/bus/i2c/devices/*/eeprom 2>/dev/null   # 24C02 contents (MAC?)
```
If the stock kernel uses a device tree, copy `/sys/firmware/fdt` (raw DTB) out.
It is the single most useful artifact. To get it off the box, `hexdump`/`base64` it
over the console:
```sh
base64 /sys/firmware/fdt
```
Decode it on the PC with `base64 -d > captures/stock.dtb && dtc -I dtb -O dts captures/stock.dtb`.

The 2017 BSP kernel may still use `script.bin`/FEX instead of a DT. In that case dump
the `script` partition or `/boot/script.bin` and convert it with `bin2fex` (sunxi-tools).

## Step 4: FEL probing (no writes)

With FEL working (`01-connect.md`):
```sh
sunxi-fel version
sunxi-fel sid            # SoC unique ID, used for the MAC address in mainline
```
Next, boot a mainline U-Boot **into RAM only** (see `04-build.md`) and check DRAM init,
eMMC detection and Ethernet:
```sh
sunxi-fel -v uboot build/u-boot-sunxi-with-spl.bin
```
Nothing is written to flash, and a power cycle returns the board to stock.

## Checklist for findings.md

- [ ] UART pinout, baud
- [ ] FEL works over micro-USB? (yes/no)
- [ ] Stock bootloader version, autoboot key
- [ ] DRAM clock / size / type as initialised by boot0
- [ ] eMMC exact part, size, bus width, controller index
- [ ] Partition layout (and boot0 location: 8 KiB offset? boot partitions?)
- [ ] Ethernet PHY addr, reset GPIO, delays; MAC source
- [ ] I2C buses and device addresses (PCA9635, 24C02, others)
- [ ] GPIOs: buttons, LEDs, Wi-Fi power, USB VBUS
- [ ] Stock DTB or script.bin saved

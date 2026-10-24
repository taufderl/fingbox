# 04 — Building mainline U-Boot (and later the kernel)

## Toolchain (Arch / Omarchy)

```sh
sudo pacman -S --needed arm-none-eabi-gcc dtc swig python-setuptools \
  python-pyelftools bison flex bc openssl sunxi-tools
# or the AUR arm-linux-gnueabihf-gcc toolchain; Debian: gcc-arm-linux-gnueabihf
```
U-Boot builds fine with `arm-none-eabi-` for 32-bit sunxi. The kernel prefers
`arm-linux-gnueabihf-`.

## U-Boot for FEL and probing

Start from the NanoPi M1 Plus config (H3 + RTL8211E + eMMC):

```sh
git clone --depth 1 --branch v2025.10 https://source.denx.de/u-boot/u-boot.git build/u-boot
cd build/u-boot
make CROSS_COMPILE=arm-none-eabi- nanopi_m1_plus_defconfig
make CROSS_COMPILE=arm-none-eabi- menuconfig
```
Check in menuconfig:
- `CONFIG_CMD_USB_MASS_STORAGE=y` (`ums`)
- `CONFIG_USB_MUSB_GADGET=y` (peripheral mode on OTG)
- `CONFIG_MMC_SUNXI_SLOT_EXTRA=2` (eMMC on MMC2)
- `CONFIG_DRAM_CLK`: start **conservative (408)**, raise it later to what boot0 used
- `CONFIG_BOOTDELAY=3`

```sh
make CROSS_COMPILE=arm-none-eabi- -j$(nproc)
cp u-boot-sunxi-with-spl.bin ../
```
Run it from RAM: `sunxi-fel -v uboot build/u-boot-sunxi-with-spl.bin`.

If DRAM init fails (hang after `DRAM:`), lower `CONFIG_DRAM_CLK` and try
`CONFIG_DRAM_ZQ` / `CONFIG_DRAM_ODT_EN` values from the stock boot log.

When the config works, commit it as `configs/fingbox_defconfig` (in this repo, and later as an
upstream patch) together with a U-Boot DT `sun8i-h3-fingbox.dts`.

## Kernel and device tree (after probing)

- Copy `sun8i-h3-nanopi-m1-plus.dts` to `dts/sun8i-h3-fingbox.dts`.
- Adjust it from `findings.md`: Ethernet PHY/reset, eMMC, I2C devices
  (`nxp,pca9635`, `atmel,24c02`), buttons (`gpio-keys`), and drop the SD node
  unless a socket is fitted.
- Build with the distro kernel (Armbian `current`/`edge` or Debian `armmp`
  plus a DT overlay), or build mainline with `sunxi_defconfig`.
- Wi-Fi needs `CONFIG_ATH9K_HTC` and `ath9k_htc/htc_9271-1.4.0.fw`.

## Distro

| Option | Notes |
|--------|-------|
| **Armbian** (recommended first) | Build framework supports a custom board config for H3. Use the `nanopim1plus` image as a smoke test, which may boot as-is |
| Debian armhf | Mainline kernel, flash-kernel needs a DT entry |
| Alpine | Small, runs from RAM. Good for an appliance-style box |

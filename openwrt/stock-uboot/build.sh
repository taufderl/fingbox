#!/bin/sh
# Build an eMMC image for the Fingbox that boots with the stock U-Boot 2017.01
# (no FIT support): adds zImage, DTB, a bootz boot.scr and uboot.env to the
# FAT boot partition of the OpenWrt sdcard image. Run inside the builder container.
set -eu
cd /src
H=staging_dir/host/bin
K=build_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/linux-sunxi_cortexa7
W=tmp/fingbox-emmc
gunzip -c bin/targets/sunxi/cortexa7/openwrt-sunxi-cortexa7-fing_fingbox-squashfs-sdcard.img.gz > $W/fingbox-emmc.img
$H/mkimage -C none -A arm -T script -d $W/boot-stock.txt $W/boot.scr >/dev/null
$H/mkenvimage -r -s 131072 -o $W/uboot.env $W/env.txt
FAT="$W/fingbox-emmc.img@@1M"
$H/mcopy -o -i "$FAT" $K/zImage ::zImage
$H/mcopy -o -i "$FAT" $K/linux-6.18.55/arch/arm/boot/dts/allwinner/sun8i-h3-fingbox.dtb ::fingbox.dtb
$H/mcopy -o -i "$FAT" $W/boot.scr ::boot.scr
$H/mcopy -o -i "$FAT" $W/uboot.env ::uboot.env
gzip -9f $W/fingbox-emmc.img
ls -la $W/fingbox-emmc.img.gz

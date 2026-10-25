# Next steps

State as of this session's end. OpenWrt (kernel 6.18) runs from eMMC on the
unit, booted by the vendor U-Boot; Ethernet, Wi-Fi (client + AP), LEDs, reset
button, Tailscale, LuCI and mitmproxy all verified on hardware.

## OpenWrt device support → upstream

- Fork: <https://github.com/taufderl/openwrt> branch `fingbox` (4 commits).
- **Needs you:** the commits carry my `Signed-off-by` + `Claude-Session`
  trailers. An AI must not certify the DCO — review the diff, rebase onto
  current `main`, and reword each commit to drop those trailers and add **your
  own** `Signed-off-by`, keeping one line that discloses AI assistance (OpenWrt
  policy). Then open the PR against `openwrt/openwrt`.
- Ask Claude for a rebase script that strips the trailers and re-adds your
  sign-off (done the same way for the Linux series).

## Linux kernel → upstream

- Tree: `~/git/linux`, branches `fingbox-ath9k-htc` (binding + driver) and
  `fingbox-sunxi` (vendor prefix, board binding, DTS).
- Ready and checked (checkpatch, dt_binding_check, dtbs_check, ath9k build W=1);
  see **`~/git/linux/outgoing/SENDING.md`** for review → sign-off → send steps.
  Send the ath9k series first (the DTS depends on its binding).

## sysupgrade test (blocked)

- A fresh image is built (`~/Downloads/fingbox/openwrt-new/`) with the
  vendor-U-Boot boot flow, partition-preserving sysupgrade, stable Wi-Fi radio
  naming and MMC aliases. **Not yet tested on hardware.**
- Do it **with the serial cable reconnected** (no FEL recovery on this unit):
  `sysupgrade -v <squashfs-sdcard.img.gz>`, confirm it keeps the vendor U-Boot
  and the `/srv` data partition, and that the radio comes up as `wl0`.

## mitmproxy feed

- `~/git/mitmproxy-openwrt` (local): 18 packages build and run on the box.
  Next: upstream the Python deps + mitmproxy to the official OpenWrt packages
  feed so OpenWrt's buildbots build them (then `apk add mitmproxy`, no private
  feed). See that repo's README.
- `mitmproxy-armv7` (public): generic ARMv7 wheels of `mitmproxy_rs`, CI green,
  weekly auto-build. Could be offered to the mitmproxy project.

## Open hardware items

- Wi-Fi AP + transparent proxy deployment is live; see `08-deployment.md`.
- Still unverified: LED colour order per ring LED; long-term AP stability.

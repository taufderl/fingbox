# 01 — Connecting the hardware

Two connections are needed: the **UART console** (to see and control the boot) and
**USB FEL** (to load our own bootloader and write the eMMC).

## Opening the case

The case is clipped together. Remove the rubber foot pads first in case there are
screws under them, then work a plastic spudger around the seam. Take photos of the
board (both sides) and put them in `captures/photos/`. We need them to identify test pads.

## UART console

The 3-pin header is already fitted. The pins are labelled on the silkscreen; write the labels down in
`findings.md`.

**Use a 3.3 V adapter. Never connect the adapter's VCC pin.** The board is
powered by its own micro-USB supply.

```
Fingbox header        USB-UART adapter (3.3 V)
  GND  ─────────────── GND
  TX   ─────────────── RX
  RX   ─────────────── TX
  (no VCC)
```

If the labels are unclear, power the board without RX/TX connected and measure with a multimeter:
- GND: 0 Ω to the USB shield / Ethernet shield
- TX: idles at ~3.3 V and flickers during boot
- RX: ~3.3 V (pull-up) or floating, steady

Settings: **115200 8N1, no flow control** (Allwinner default for both boot0 and U-Boot).

```sh
scripts/uart-capture.sh /dev/ttyUSB0          # logs to captures/uart-<timestamp>.log
```

Power the box only **after** the terminal is open so the first bytes of
boot0/SPL are captured.

If you see garbage, try 1500000 baud (some BSPs use it), then check GND.

## USB FEL

FEL is the H3 boot ROM's USB recovery protocol. It needs the **micro-USB port to be
wired to the SoC's USB-OTG**. We don't know yet whether it is.

1. Install `sunxi-tools` (Arch: `sunxi-tools`, Debian: `sunxi-tools`).
2. Allow non-root access (optional):
   ```sh
   echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="1f3a", ATTRS{idProduct}=="efe8", MODE="0666"' \
     | sudo tee /etc/udev/rules.d/50-sunxi-fel.rules
   sudo udevadm control --reload
   ```
3. Unplug the Fingbox. Hold the **Uboot** button. Plug the micro-USB **data**
   cable from the PC into the Fingbox. Release the button after about 3 s.
4. Run:
   ```sh
   scripts/fel-check.sh
   ```
   Expected: `lsusb` shows `1f3a:efe8 Allwinner ... sunxi SoC OTG connector in FEL/flashing mode`
   and `sunxi-fel version` prints `AWUSBFEX soc=00001680(H3)`.

Power considerations: an H3 board with gigabit PHY can draw over 500 mA. A USB-3 port or
powered hub is usually fine. If FEL enumerates and then drops, power the board from
the 5 V supply through a USB "power + data" Y-cable.

### If FEL doesn't enumerate

- The UART log will show what happens with the button held. If nothing prints, the ROM
  is probably in FEL and the micro-USB is power-only.
- Try the vertical USB-A port with an A-to-A cable. On some boards that port is the OTG port
  (**only with the micro-USB power disconnected**, otherwise two 5 V sources are
  back-fed into each other; check with a multimeter first).
- If neither works, use the U-Boot console route (see `02-probing.md`) or fit
  a micro-SD socket on the unpopulated footprint.

## Ethernet

Connect it to a lab switch/VLAN, not the home LAN. The stock firmware ARP-spoofs by design.
That port also lets U-Boot `tftp`/`dhcp` serve as an alternative flashing path.

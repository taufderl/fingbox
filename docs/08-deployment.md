# 08 — Current deployment

The running unit (reachable over Tailscale as `fingbox`) is configured as a
Wi-Fi access point whose client traffic is passed through a transparent
mitmproxy and out an Ethernet uplink. Everything here is live UCI/overlay
configuration on the eMMC install; no re-flash is involved, and it survives
reboots.

## Roles

| Part | Setting |
|------|---------|
| Uplink | `eth0` = WAN, DHCP client |
| Access point | Wi-Fi `Fingbox`, WPA2 (key set during setup), channel 6, country DE |
| AP subnet | `192.168.9.0/24`, DHCP server on the Fingbox (IPv4 only — RA/DHCPv6 off so nothing bypasses the proxy over IPv6) |
| Proxy | `mitmdump --mode transparent` on `:8080`, started by `/etc/init.d/mitmproxy` (enabled) |
| Redirect | nftables `/etc/nftables.d/30-mitmproxy.nft`: AP TCP 80/443 → `:8080`; UDP 443 (QUIC) rejected so HTTPS falls back to interceptable TCP |
| Data | `/dev/mmcblk1p3` ext4 mounted at `/srv` via fstab (block-mount); holds `mitmproxy/` (CA, config) |
| Remote access | Tailscale (`tailscale` firewall zone, input ACCEPT) — unaffected by the uplink switch |

The CA clients must trust for clean HTTPS is at `/srv/mitmproxy/mitmproxy-ca-cert.pem`,
or via `http://mitm.it` while connected to the AP.

## Managing it

```sh
ssh -i ~/.ssh/id_ed25519_fingbox root@<tailscale-ip-or-100.x>
/etc/init.d/mitmproxy {start,stop,restart,status}
logread -f                      # live proxy flows (procd stdout)
iw dev phy0-ap0 station dump     # connected clients
```

To **record** flows, add `-w /srv/mitmproxy/flows.mitm` to the command in
`/etc/init.d/mitmproxy` and restart the service.

## Reverting to a plain router / client

The pre-AP configs are kept on the device at `/srv/config-backup/*.pre-ap`
(network, wireless, firewall, dhcp). Restore them and reload:

```sh
for f in network wireless firewall dhcp; do cp /srv/config-backup/$f.pre-ap /etc/config/$f; done
/etc/init.d/mitmproxy stop; /etc/init.d/mitmproxy disable
rm -f /etc/nftables.d/30-mitmproxy.nft /etc/sysctl.d/30-mitmproxy.conf
reload_config; /etc/init.d/firewall restart; wifi reload
```

The setup script that produced this state is kept on the box at
`/srv/fingbox-ap-setup.sh` (includes a 5-minute auto-revert used during the
remote cutover).

## mitmproxy packages

mitmproxy and its dependencies are built from a **separate** OpenWrt package
feed kept locally at `~/git/mitmproxy-openwrt` (18 packages, incl. the Rust
`mitmproxy_rs`). Generic ARMv7 wheels of `mitmproxy_rs` for non-OpenWrt systems
are published at <https://github.com/taufderl/mitmproxy-armv7>. See
[`NEXT-STEPS.md`](NEXT-STEPS.md) for what remains there.

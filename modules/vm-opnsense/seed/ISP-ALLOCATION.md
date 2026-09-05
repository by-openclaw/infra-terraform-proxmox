# ISP address allocation — Telenet /29 + /48 (the two OPNsense seeds)

> Source of truth for WHO holds WHICH public address on the Telenet segment (VLAN 999,
> `vmbrWAN2`). Read before touching any `wan2` seed block or `fabric/net-isp-telenet*.json`.
> Telenet order 164-1694862 (PDF in `assets/`): IPv4 `213.214.47.216/29`, router `.217`;
> IPv6 `2a02:1802:21::/48`, on-link `/64` = `2a02:1802:21::/64`, router `::1`,
> the rest of the `/48` is routed by Telenet to `::2`.

| Address | IPv6 | Holder | Note |
|---|---|---|---|
| 213.214.47.217 | 2a02:1802:21::1 | Telenet router | gateway for everyone |
| 213.214.47.218 | 2a02:1802:21::4 | **pfSense01** (other island, `pfSense01.by-systems.arpa`) | still in production, WAN2 static |
| 213.214.47.219 | — | pfSense01 **NAT 1:1** → 10.100.0.24 | "odoo instances" VIP |
| 213.214.47.220 | 2a02:1802:21::6 | **vm-opns-test-01** (VM 199, TEST) | `fabric/net-isp-telenet-test.json` — **borrowed from the HA-Phase2 pool; no HA at this stage** |
| 213.214.47.221 | — | **free** | last free host; HA-Phase2 (pair + CARP VIP) must be re-planned |
| 213.214.47.222 | 2a02:1802:21::5 | **vm-opns-01** (VM 100, PROD) | `fabric/net-isp-telenet.json` |
| — | 2a02:1802:21::2 | nobody | routed `/48` target — parked |

## Rules
1. **One seed = one identity file.** `seeds/vm-opns-01.json` → `net-isp-telenet.json`;
   `seeds/vm-opns-test-01.json` → `net-isp-telenet-test.json`. `recreate-and-seed.py`
   refuses to start the test FW on `vmbrWAN2` with prod's file or prod's addresses.
2. **Proximus PPPoE = one account = one session.** The test FW's `net2` is created
   `link_down=1`; `opt12` exists only so catalog rules bound to it can be tested.
3. Both secret files' `_meta.ip_allocation_policy` mirror this table — update all three
   together (this file, both `_meta`), then Vault via `playbooks/secrets-to-vault.yml`.

## Why this exists (incident 2026-08-30 → 2026-09-06)
The test FW was recreated with net2/net3 on the ISP bridges and a seed that read prod's
Telenet file. It answered ARP/ND for `.222` / `::5`; the prod FW logged
`arp: … is using my IP address 213.214.47.222 on vtnet3!` ×763, `WAN_TELENET_GW` flapped
12–20 % loss and `WAN_TELENET_GWv6` sat Offline at 92 % loss for a week. Proximus (PPPoE)
was untouched. Stopping VM 199 restored all gateways to 0 % loss within 70 s.

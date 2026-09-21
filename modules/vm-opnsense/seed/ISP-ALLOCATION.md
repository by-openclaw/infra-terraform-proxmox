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
| 213.214.47.220 | 2a02:1802:21::6 | **vm-opns-test-01** (VM 199, TEST) | `fabric/net-isp-telenet-test.json` — borrowed from the HA-Phase2 pool (no HA at this stage). **Telenet NIC UP since 2026-09-06 22:40** — distinct identity proven safe on the shared segment (hot link-up + full boot, prod `.222` untouched); Proximus NIC stays down (single PPPoE account) |
| 213.214.47.221 | 2a02:1802:21::7 (spare) | **free** | spare host (was a pfSense VIP; removed 2026-09-06) |
| 213.214.47.222 | 2a02:1802:21::5 | **vm-opns-01** (VM 100, PROD) | `fabric/net-isp-telenet.json` |
| — | 2a02:1802:21::2 | nobody | routed `/48` target — parked |

## Verified occupancy (2026-09-06, live ARP/NDP on prod OPNsense vtnet3)
After the user removed the stale pfSense01 VIPs .220/.221/.222, a flushed-then-fresh probe confirms:
`.217` Telenet gw · `.218` pfSense01 WAN · `.219` pfSense01 (Odoo 1:1) · **`.220` FREE → test FW** · **`.221` FREE (spare)** · `.222` prod OPNsense.
IPv6: `::1` gw · `::5` prod · **`::6` FREE → test FW**; `::2` and `::4` unanswered. pfSense blocks WAN ICMP, so occupancy was proven at the **ARP/NDP layer** (a MAC reply), not by ping.

## Rules
1. **One seed = one identity file.** `seeds/vm-opns-01.json` → `net-isp-telenet.json`;
   `seeds/vm-opns-test-01.json` → `net-isp-telenet-test.json`. `recreate-and-seed.py`
   refuses to start the test FW on `vmbrWAN2` with prod's file or prod's addresses.
2. **Proximus PPPoE = one account = one session.** The test FW's `net2` is created
   `link_down=1`; `opt12` exists only so catalog rules bound to it can be tested.
3. Both secret files' `_meta.ip_allocation_policy` mirror this table — update all three
   together (this file, both `_meta`), then Vault via `playbooks/secrets-to-vault.yml`.

## FINDING — a second OPNsense must NOT boot live on the prod Telenet segment (even with its own IP)

Proven twice (2026-08-30 with the shared IP, 2026-09-06 with the test FW's own .220):
when the test FW boots on `vmbrWAN2`, its **boot-time gratuitous ARP poisons the Telenet
CPE's ARP cache for prod's `.222`** — the CPE starts sending prod's inbound v4 to the test
FW's MAC. Prod then shows `WAN_TELENET_GW` 100 % loss (v6 unaffected), and it does **NOT
self-heal** when the test FW goes away: the CPE holds the stale entry and does not relearn
from prod's ordinary ARP requests. Recovery = force prod to re-announce:

```
# on prod vm-opns-01 (via qemu-agent or the console)
configctl interface reconfigure opt13     # sends a gratuitous ARP for .222 -> CPE relearns
```

Because testing seed configs and firewall rules does **not** need live Internet, the test
FW's Telenet NIC (`net3`) is created **`link_down=1` by default** (`TELENET_UPLINK=False` in
`recreate-and-seed.py`), and its WAN2 gateways are seeded **non-default + `monitor_disable`**
so no dpinger ever pings the shared CPE. `opt12`/`opt13` still exist in the config so every
rule/alias bound to them is testable offline.

**To test WITH live Internet (deliberate, supervised):** set `TELENET_UPLINK=True`, rebuild,
and be ready to run the `configctl interface reconfigure opt13` above on prod afterwards. A
clean long-term fix would be a dedicated test uplink (a WAN3 NIC behind pfSense01 on the OOB
net) so the test FW never shares the prod Telenet L2 segment at all.

## Why this exists (incident 2026-08-30 → 2026-09-06)
The test FW was recreated with net2/net3 on the ISP bridges and a seed that read prod's
Telenet file. It answered ARP/ND for `.222` / `::5`; the prod FW logged
`arp: … is using my IP address 213.214.47.222 on vtnet3!` ×763, `WAN_TELENET_GW` flapped
12–20 % loss and `WAN_TELENET_GWv6` sat Offline at 92 % loss for a week. Proximus (PPPoE)
was untouched. Stopping VM 199 restored all gateways to 0 % loss within 70 s.

## ISP settings (non-secret) — where the credentials live

Credentials are NEVER in this repo. Vault KV v2 is the store of record (`ansible-platform`
`playbooks/vars/vault_kv_map.yml` maps the fabric names); the files on the controller under
`~/.openclaw/workspace/infra/secrets/fabric/` are the break-glass fallback a rebuild reads when
Vault sits behind the firewall being rebuilt. The provisioning role (`roles/opnsense_provision` →
`by_systems.opnsense.opnsense_seed_config`) reads Vault first, the file second, and renders into
`config.xml`. The PPPoE password is refreshed into the file *from* Vault by the rotation playbook.

### Proximus (WAN1, `opt12`, `pppoe0` over `vtnet2`)
| Setting | Value |
|---|---|
| Physical | Proximus NTU → node `nic0`, **VLAN 10 tagged at the Proxmox host** (`nic0.10` → `vmbrWAN1`, untagged inside the VM) |
| IPv4 | PPPoE, dynamic; **one account = one session** (never dial it from a second FW) |
| IPv6 | DHCPv6 over PPP, **/56 prefix delegation**, IA_PD only, prefix hint 56, request DNS |
| MTU / MSS | 1492 / 1452 |
| Gateways | `WAN_PROXIMUS_PPPOE` (v4, default) + `WAN_PROXIMUS_DHCP6` (v6, default) — monitors `9.9.9.9` / `2001:4860:4860::8888` (Quad9 v6 does NOT route from Proximus) |
| Credentials | Vault `secret/prod/net/isp-proximus-pppoe` (store of record; custom metadata `format=raw`, `rotated_at`, `reason`) — fields `pppoe_username` (`puXXXXXX@PROXIMUS`), `pppoe_password` **raw as issued** (the renderer base64-encodes it, OPNsense `base64_decode`s the element), `service_name`, `host_uniq`, `account_id`, `contract_id`. Break-glass fallback `fabric/net-isp-proximus-pppoe.json` (read only when Vault is unreachable, refreshed *from* Vault by the playbook) |
| Rotation | ISP portal first (the running session keeps its authentication until it re-dials), then `ansible-platform/playbooks/opnsense-pppoe-rotate.yml` (hidden prompt → Vault → firewall over SSH + wheel sudo, `configctl` re-dial, gateway wait). Without wheel sudo on the appliance (seed `sudo_allow_wheel`), the seed applies Vault's value at the re-seed. No file edit, no GUI |
| Notes | blocks outbound :25 (mail egress is policy-routed via Telenet); block private/bogons on |

### Telenet (WAN2, `opt13`, `vtnet3`)
| Setting | Value |
|---|---|
| Physical | Telenet modem/router (managed, HPE `4c:ae:a3:db:bd:65`) → node `nic1`, **VLAN 999 tagged at the Proxmox host** (`nic1.999` → `vmbrWAN2`) |
| Product | Corporate Fibernet 500/50, order `164-1694862`, installed 2021-10-11 |
| IPv4 | static `/29` (table above), gateway `213.214.47.217` |
| IPv6 | static on-link `/64` (table above), gateway `2a02:1802:21::1`; the `/48` is routed to `::2` (unused) |
| Gateways | `WAN_TELENET_GW` (v4) + `WAN_TELENET_GWv6` (v6), **not default**; monitor = the gateway itself |
| ISP DNS (info) | v4 `195.130.131.11`, `195.130.130.139`, `195.130.130.11`; v6 `2a02:1800:100::1`, `2a02:1800:100::2` (not used — platform runs its own resolver chain) |
| SMTP relay (info) | `uit.telenet.be` (not used — mailcow delivers directly via Telenet) |
| Support | Telenet Business customer care 015 364 364 (option 2), customercare@telenetgroup.be |
| Credentials | `fabric/net-isp-telenet.json` (PROD) / `fabric/net-isp-telenet-test.json` (TEST) → Vault `secret/fabric/net/isp/telenet` / `…/telenet-test` — fields `ipv4_address`, `ipv4_prefix`, `ipv4_gateway`, `ipv6_address`, `ipv6_prefix`, `ipv6_gateway`, `account_id`, `contract_id` |
| Rotation | only if the line/contract changes → update files → `secrets-to-vault` → reseed |

## Fabric MGMT VLAN 600 — `10.6.240.0/20` (FAB, `vmbrFAB` = node `nic4.600`, untagged)

> Who holds which static address on the fabric management segment. The fabric VRF is the
> gateway; the OPNsense FWs are members (seed `opt14` = `vtnet4`, static, no gateway/IPv6).
> Verified free at ARP level before allocation (2026-09-06, from the POC node on `vmbrFAB`).

| Address | Holder | Note |
|---|---|---|
| 10.6.240.1 | pfSense01 | Kea DHCP server for the segment (pool 10.6.255.101-199) |
| 10.6.240.2 | **vm-opns-01** (VM 100, PROD) | `opt14`/FAB on `net4 → vmbrFAB` (live since 2026-09; seed-synced 2026-09-06) |
| 10.6.240.3 | **vm-opns-test-01** (VM 199, TEST) | seed `fab.ipaddr`; `net4 → vmbrFAB` added to `recreate-and-seed.py` 2026-09-06 |
| 10.6.240.4 | free | next static (lab FW candidate) |
| 10.6.240.5 | srv-proxmox-poc-01 | node `vmbrFAB` address |
| 10.6.255.254 | Arista fabric VRF | **gateway** for the whole /20 |

## Re-verified after the 2026-09-06 test-FW reseed (18:30, from prod vm-opns-01)
The test FW was destroyed + recreated from the seed with `net3` (Telenet) **`link_down=1`** — its
`vtnet3` carries `213.214.47.220/29` in config but reports `no carrier`, so no boot-time gratuitous
ARP reached the shared segment. Prod view right after: `WAN_TELENET_GW` (.217) and
`WAN_TELENET_GWv6` (::1) **Online, 0 % loss, 0.6 ms**; ARP = `.217` (Telenet router), `.218`
(pfSense01), `.222` (prod, MAC of VM 100 `net3`); NDP = `::1`, `::5` (prod). **`.220` /
`::6` absent, `.221` free.** Rule stands: the test FW's Telenet NIC stays down unless a supervised
uplink test is explicitly requested (then expect to `configctl interface reconfigure opt13` on prod).

## 2026-09-06 22:40 — Telenet uplink ENABLED for the test FW (rule narrowed)
Hot link-up of VM 199 `net3`, then a full guest reboot with Telenet up: prod `WAN_TELENET_GW` /
`GWv6` stayed **Online 0 %** for the whole 135 s poll, prod `.222` ARP entry unchanged; the test FW
egresses from `.220` to 1.1.1.1 at **0 % loss**. The 2026-08-30 poisoning was caused by the
**duplicate** `.222` identity, not by sharing the segment. Rule now: a test FW may sit on
`vmbrWAN2` **only with its own /29 + /64 address** (guarded by `_assert_no_prod_isp_identity`);
never a duplicate; never the Proximus PPPoE account. `recreate-and-seed.py`: `TELENET_UPLINK=True`.

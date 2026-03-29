# VM Test — Spec Review

**Purpose:** Review and approve all parameters before provisioning `vm-netbox-poc-01` (next real VM after bootstrap test).  
**Date:** 2026-03-29  
**Status:** 🔲 Pending approval — do not apply until approved

---

## Action Required

Review each parameter below. If approved → reply approved and I will:
1. Update `environments/poc/main.tf` with the new VM module block
2. Remove the bootstrap test VM (`vm-debian-bootstrap-test-01`, ID 100) from state + Proxmox
3. Run `terraform plan` (dry-run) → post output for review
4. Apply only after plan review confirmed

---

## New VM: `vm-netbox-poc-01`

### 1. Identity

| # | Parameter | Value | Notes |
|---|---|---|---|
| 1 | **Name** | `vm-netbox-poc-01` | Follows convention: `vm-{service}-{env}-{seq:02d}` |
| 2 | **FQDN** | `vm-netbox-poc-01.by-systems.arpa` | Internal DNS only |
| 3 | **Target node** | `srv-proxmox-poc-01` | Only Proxmox node available |
| 4 | **Template** | `debian-12-cloud` | Template 9000 — serial0 removed, validated |

### 2. Compute

| # | Parameter | Value | Notes |
|---|---|---|---|
| 5 | **CPU cores** | `2` | Module default |
| 6 | **Memory** | `4096 MB` (4 GB) | NetBox + PostgreSQL requirement |
| 7 | **CPU type** | `host` | Hardcoded in module |

### 3. Storage

| # | Parameter | Value | Notes |
|---|---|---|---|
| 8 | **Disk size** | `50G` | NetBox data + PostgreSQL |
| 9 | **Storage pool** | `poc-data` | ZFS tank/poc-data — local, confirmed available |
| 10 | **SCSI controller** | `virtio-scsi-single` | Hardcoded in module — iothread enabled |
| 11 | **Disk format** | `qcow2` | Hardcoded in module |
| 12 | **Discard** | `on` | ZFS trim support |

### 4. Network

| # | Parameter | Value | Notes |
|---|---|---|---|
| 13 | **IP address** | `10.6.225.12/20` | ⚠️ Next free IP in 10.6.225.x range — confirm no conflict |
| 14 | **Gateway** | `10.6.224.1` | pfSense OOB gateway |
| 15 | **DNS** | `10.6.224.1` | Same as gateway |
| 16 | **Network bridge** | `vmbrOOB` | OOB bridge — internet via pfSense |
| 17 | **NIC model** | `virtio` | Hardcoded in module |

### 5. Cloud-Init / OS

| # | Parameter | Value | Notes |
|---|---|---|---|
| 18 | **OS user** | `by-systems` | Standard baseline user |
| 19 | **Console password** | `BySyst3ms_` | For Proxmox noVNC only |
| 20 | **SSH key 1** | `yboujraf@personal-2026-03-27` | My Lord Win11 key |
| 21 | **SSH key 2** | `rune@by-systems-rune-vm` | Rune automation key |
| 22 | **Sudo** | `NOPASSWD:ALL` | Standard baseline |
| 23 | **Timezone** | `Europe/Brussels` | Hardcoded in module |
| 24 | **Locale** | `fr_BE.UTF-8` | Hardcoded in module |
| 25 | **Keyboard** | `be` (Belgian) | Hardcoded in module |
| 26 | **QEMU agent** | `enabled` | Hardcoded in module |
| 27 | **On boot** | `true` | Auto-start after node reboot |

### 6. Packages (installed by cloud-init)

| # | Package | Purpose |
|---|---|---|
| 28 | `curl`, `wget`, `git` | Baseline tools |
| 29 | `htop`, `net-tools` | Ops utilities |
| 30 | `unattended-upgrades` | Auto security patches |
| 31 | `qemu-guest-agent` | Proxmox integration |
| 32 | `sudo`, `locales`, `console-setup`, `keyboard-configuration` | OS baseline |

---

## Existing VM to Remove

| VM | ID | IP | Status |
|---|---|---|---|
| `vm-debian-bootstrap-test-01` | 100 | `10.6.225.11` | ✅ Validated — ready to destroy |

On approval: `terraform destroy -target module.bootstrap_test` then remove the block from `main.tf`.

---

## Open Questions

> Answer these before approving:

- **13 — IP `10.6.225.12`**: Confirmed no other device on that IP? (Check pfSense DHCP leases / ARP table)
- **8 — Disk 50G**: Sufficient for NetBox + PostgreSQL data? (NetBox typically < 5GB; generous for PoC)
- **6 — 4GB RAM**: Correct for NetBox? (NetBox recommends 2–4GB; 4GB comfortable for PoC)

---

## Approval

Reply with one of:
- ✅ **Approved** — proceed with plan + apply
- ❌ **Change needed** — specify which parameter # and new value

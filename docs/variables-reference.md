# Terraform Module Variables Reference

> BY-SYSTEMS PoC — infra-terraform-proxmox  
> Last updated: 2026-03-28

This document lists all variables per module, their defaults, and notes on what is/isn't supported for each deployment type.

---

## Module: `vm-linux`

For full Linux VMs cloned from a cloud-init template (e.g. `debian-12-cloud`).

| Variable | Type | Default | Required | Supported | Notes |
|---|---|---|---|---|---|
| `name` | string | — | ✅ | ✅ | Convention: `vm-{service}-{env}-{seq:02d}` |
| `target_node` | string | — | ✅ | ✅ | e.g. `srv-proxmox-poc-01` |
| `clone` | string | — | ✅ | ✅ | Template name e.g. `debian-12-cloud` |
| `cores` | number | `2` | — | ✅ | CPU cores |
| `memory` | number | `2048` | — | ✅ | RAM in MB |
| `disk_size` | string | `"20G"` | — | ✅ | Primary disk size |
| `storage` | string | — | ✅ | ✅ | Proxmox storage pool e.g. `poc-data` |
| `network_bridge` | string | `"vmbrOOB"` | — | ✅ | Network bridge |
| `ip` | string | — | ✅ | ✅ | CIDR notation e.g. `10.6.225.11/20` |
| `gateway` | string | — | ✅ | ✅ | Default gateway |
| `dns` | string | `"10.6.224.1"` | — | ✅ | DNS server |
| `domain` | string | `"by-systems.arpa"` | — | ✅ | FQDN domain suffix |
| `keyboard_layout` | string | `"fr-be"` | — | ✅ | Proxmox console keyboard |
| `ci_user` | string | `"by-systems"` | — | ✅ | Cloud-init user |
| `ci_password` | string | `"BySyst3ms_"` | — | ✅ | Web console password (sensitive) |
| `ssh_keys` | list(string) | `[]` | — | ✅ | SSH public keys injected via cloud-init |

### Not yet supported (planned)
| Variable | Notes |
|---|---|
| `tags` | Proxmox VM tags — useful for filtering, not yet wired |
| `onboot` | Auto-start on node boot — hardcoded `true`, not exposed |
| `vlan_tag` | VLAN tagging on NIC — not yet implemented |
| `extra_disks` | Additional data disks — not yet implemented |
| `cpu_type` | CPU emulation type — hardcoded `host` |
| `description` | VM description in Proxmox UI — not yet wired |

### Not applicable (VM-specific, N/A for LXC)
| Variable | Reason |
|---|---|
| `clone` | LXC uses `ostemplate` instead |
| `keyboard_layout` | Proxmox console concept — not applicable to LXC |

---

## Module: `lxc-standard`

For lightweight LXC containers (no cloud-init, no full OS install).

| Variable | Type | Default | Required | Supported | Notes |
|---|---|---|---|---|---|
| `name` | string | — | ✅ | ✅ | Convention: `lxc-{service}-{env}-{seq:02d}` |
| `target_node` | string | — | ✅ | ✅ | e.g. `srv-proxmox-poc-01` |
| `ostemplate` | string | — | ✅ | ✅ | e.g. `local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst` |
| `cores` | number | `1` | — | ✅ | CPU cores |
| `memory` | number | `512` | — | ✅ | RAM in MB |
| `swap` | number | `0` | — | ✅ | Swap in MB (0 = disabled) |
| `disk` | string | `"8G"` | — | ✅ | Root filesystem size |
| `storage` | string | — | ✅ | ✅ | Proxmox storage pool |
| `network_bridge` | string | `"vmbrMGMT"` | — | ✅ | Network bridge |
| `ip` | string | — | ✅ | ✅ | CIDR notation |
| `gateway` | string | — | ✅ | ✅ | Default gateway |
| `unprivileged` | bool | `true` | — | ✅ | Unprivileged container (recommended) |
| `onboot` | bool | `true` | — | ✅ | Auto-start on node boot |
| `ssh_keys` | list(string) | `[]` | — | ✅ | SSH keys injected into root |

### Not yet supported (planned)
| Variable | Notes |
|---|---|
| `ci_user` | LXC root is always `root` — user creation needs post-init script |
| `ci_password` | Password not set — need post-init or `passwd` in provisioner |
| `dns` | Not wired yet — uses Proxmox node default |
| `domain` | Not wired yet |
| `tags` | Proxmox tags — not yet wired |
| `vlan_tag` | VLAN tagging — not yet implemented |
| `extra_mounts` | Bind mounts (e.g. NFS, host path) — not yet implemented |
| `privileged_features` | NFS/FUSE/nesting — not yet implemented |

### Not applicable (LXC-specific, N/A for VM)
| Variable | Reason |
|---|---|
| `ostemplate` | VMs use `clone` (template name) instead |
| `swap` | VMs don't use LXC swap concept |
| `unprivileged` | VM concept doesn't apply |

---

## Synology DSM — Not a Terraform target

Synology NAS (e.g. DS1621+) is **not managed via Terraform/Proxmox**.  
It is managed via:
- **lib-synology-dsm** (Python library, repo: `by-openclaw/lib-synology-dsm`)
- Direct DSM web UI
- Future: Ansible role (planned)

| Feature | Status | Notes |
|---|---|---|
| DSM API access | ⏸ Blocked | rune-api user needs Application→DSM=Allow in Synology UI |
| Storage volumes | ❌ Not via Terraform | DSM-managed |
| NFS/SMB shares | ❌ Not via Terraform | DSM-managed |
| Proxmox storage pool | ✅ Manual | poc-data pool already configured |

---

## Naming Conventions

```
VM:  vm-{service}-{env}-{seq:02d}    e.g. vm-netbox-poc-01
LXC: lxc-{service}-{env}-{seq:02d}  e.g. lxc-redis-poc-01
```

## IP Allocation (PoC)

| Range | Purpose |
|---|---|
| `10.6.224.x` | Infrastructure (Proxmox, switches, NAS, pfSense) |
| `10.6.225.x` | VMs / LXCs (PoC / dev) |
| `10.6.239.101–199` | DHCP pool — avoid for static |
| `10.6.255.254` | pfSense OOB gateway |

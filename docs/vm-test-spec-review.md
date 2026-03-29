# VM Test — Spec Review

**Purpose:** Review and approve all parameters before provisioning next VMs after bootstrap test validation.  
**Date:** 2026-03-29  
**Status:** 🔲 Pending approval — do not apply until approved

---

## Action Required

Review each parameter below. On approval I will:
1. Update `environments/poc/main.tf` with both new VM module blocks
2. Destroy the bootstrap test VM (`vm-debian-bootstrap-test-01`, IP `.11`) → frees `.11`
3. Run `terraform plan` → post output for review
4. Apply only after plan confirmed

---

## SSH Key Update (prerequisite — do first)

Current keys use personal email as comment. New standard: `by-systems@<host-role>` — no personal email.

**Generate new keys before provisioning:**

```powershell
# Win11 reference station (PowerShell / MobaXterm)
ssh-keygen -t ed25519 -C "by-systems@ws-win11-ref" -f "$env:USERPROFILE\.ssh\id_ed25519_by-systems"
```

```bash
# Rune VM
ssh-keygen -t ed25519 -C "by-systems@rune-vm" -f ~/.ssh/id_ed25519_by-systems
```

Once generated, paste the new public keys here for confirmation before embedding in Terraform.

> ⚠️ Old keys (`yboujraf@personal-2026-03-27`, `rune@by-systems-rune-vm`) remain valid on existing VMs — do not remove from authorized_keys until new keys are confirmed working.

---

## VM 1: `vm-netbox-poc-01`

### 1. Identity

| # | Parameter | Value | Notes |
|---|---|---|---|
| 1 | **Name** | `vm-netbox-poc-01` | Convention: `vm-{service}-{env}-{seq:02d}` |
| 2 | **FQDN** | `vm-netbox-poc-01.by-systems.arpa` | Internal DNS only |
| 3 | **Target node** | `srv-proxmox-poc-01` | |
| 4 | **Template** | `debian-12-cloud` | Template 9000 — validated |

### 2. Compute

| # | Parameter | Value | Notes |
|---|---|---|---|
| 5 | **CPU cores** | `2` | |
| 6 | **Memory** | `2048 MB` (2 GB) | NetBox app only — no PostgreSQL |

### 3. Storage

| # | Parameter | Value | Notes |
|---|---|---|---|
| 7 | **Disk size** | `20G` | NetBox app + filestore only — no DB |
| 8 | **Storage pool** | `poc-data` | ZFS tank/poc-data |
| 9 | **SCSI controller** | `virtio-scsi-single` | Module default |

### 4. Network

| # | Parameter | Value | Notes |
|---|---|---|---|
| 10 | **IP address** | `10.6.225.11/20` | Freed after destroying bootstrap VM |
| 11 | **Gateway** | `10.6.224.1` | |
| 12 | **DNS** | `10.6.224.1` | |
| 13 | **Bridge** | `vmbrOOB` | |

### 5. Cloud-Init / OS

| # | Parameter | Value | Notes |
|---|---|---|---|
| 14 | **OS user** | `by-systems` | |
| 15 | **Console password** | `BySyst3ms_` | Proxmox noVNC only |
| 16 | **SSH key 1** | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJ8rXlV8+/e20imHW/hTry2DbqQ9bIpwslC4MIINlJW by-systems@ws-win11-ref` | ✅ Confirmed |
| 17 | **SSH key 2** | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuUNkyvMaETbPeBGsBPEfzeYsL1SuVbvPUOMIb/2VU8 by-systems@rune-vm` | ✅ Confirmed |
| 18 | **Timezone** | `Europe/Brussels` | |
| 19 | **Locale** | `fr_BE.UTF-8` | |
| 20 | **Keyboard** | `be` | |
| 21 | **QEMU agent** | `enabled` | |
| 22 | **On boot** | `true` | |

---

## VM 2: `vm-postgres-poc-01`

PostgreSQL separated from NetBox — consistent with long-term architecture. One shared PostgreSQL node serves all PoC workloads (NetBox, later Odoo, etc.).

### 1. Identity

| # | Parameter | Value | Notes |
|---|---|---|---|
| 23 | **Name** | `vm-postgres-poc-01` | |
| 24 | **FQDN** | `vm-postgres-poc-01.by-systems.arpa` | Internal DNS only |
| 25 | **Target node** | `srv-proxmox-poc-01` | |
| 26 | **Template** | `debian-12-cloud` | |

### 2. Compute

| # | Parameter | Value | Notes |
|---|---|---|---|
| 27 | **CPU cores** | `2` | |
| 28 | **Memory** | `4096 MB` (4 GB) | PostgreSQL — shared for all PoC DBs |

### 3. Storage

| # | Parameter | Value | Notes |
|---|---|---|---|
| 29 | **Disk size** | `50G` | PostgreSQL data volume |
| 30 | **Storage pool** | `poc-data` | |

### 4. Network

| # | Parameter | Value | Notes |
|---|---|---|---|
| 31 | **IP address** | `10.6.225.12/20` | Next free after .11 assigned to NetBox |
| 32 | **Gateway** | `10.6.224.1` | |
| 33 | **DNS** | `10.6.224.1` | |
| 34 | **Bridge** | `vmbrOOB` | |

### 5. Cloud-Init / OS

| # | Parameter | Value | Notes |
|---|---|---|---|
| 35 | **OS user** | `by-systems` | |
| 36 | **Console password** | `BySyst3ms_` | |
| 37 | **SSH key 1** | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJ8rXlV8+/e20imHW/hTry2DbqQ9bIpwslC4MIINlJW by-systems@ws-win11-ref` | ✅ Confirmed |
| 38 | **SSH key 2** | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuUNkyvMaETbPeBGsBPEfzeYsL1SuVbvPUOMIb/2VU8 by-systems@rune-vm` | ✅ Confirmed |
| 39 | **Timezone** | `Europe/Brussels` | |
| 40 | **Locale** | `fr_BE.UTF-8` | |
| 41 | **QEMU agent** | `enabled` | |
| 42 | **On boot** | `true` | |

---

## Bootstrap VM to Destroy

| VM | ID | IP | Action |
|---|---|---|---|
| `vm-debian-bootstrap-test-01` | 100 | `10.6.225.11` | `terraform destroy -target module.bootstrap_test` — frees `.11` for NetBox |

---

## IP Allocation Summary

| IP | VM | Role |
|---|---|---|
| `10.6.225.11` | `vm-netbox-poc-01` | NetBox app |
| `10.6.225.12` | `vm-postgres-poc-01` | PostgreSQL shared |
| `10.6.225.13+` | future VMs | Reserved |

---

## Approval

> Prerequisites before apply:
> 1. Generate new SSH keys on Win11 + Rune VM → paste public keys here
> 2. Review all parameters above

Reply:
- ✅ **Approved** (with new public keys) — I proceed with destroy → plan → show output → apply
- ❌ **Change #N** — specify parameter number and new value

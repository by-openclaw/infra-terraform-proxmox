# Audit Response — OPNsense Terraform Module

Date: 2026-04-03
Reviewer: Rune (BY-SYSTEMS platform agent)
Audit source: `main.audit.tf` + `variables.audit.tf` + `opnsense-main-audit-note.md`

---

## What the audit got right

- `agent { enabled = false }` — correct and critical. Merged.
- `memory { floating = 0 }` — correct and critical. Merged.
- `disk { ssd = true }` — correct. Merged.
- `network_device { queues = var.cores }` — correct. Merged.
- `serial_device {}` — correct. Merged.
- `protection = var.protection` — correct. Variable added to `variables.tf`.
- `cpu { flags = ["+aes"] }` — consistent with BY-SYSTEMS ADR (always expose AES-NI).
- `bios = "ovmf"` — accepted for new builds. VM was not yet installed, so destructive rebuild applied.
- `efi_disk {}` block — correct (required with ovmf). Merged.
- Memory minimum `>= 3072 MiB` validation — accepted. poc deployment bumped to 4096 MiB.
- Disk minimum `>= 8 GiB` validation — accepted (poc already at 20 GiB).

---

## What the audit didn't know — context clarifications

### 1. `env` variable validation — REGRESSION CAUGHT

The audit's `variables.audit.tf` silently dropped the `env` validation:

```hcl
# Existing (kept — do not remove):
validation {
  condition     = contains(["prod", "dev", "test", "staging", "acc"], var.env)
  error_message = "env must be one of: prod, dev, test, staging, acc."
}
```

This is mandated by ADR-0010 (env-per-VM model). Env suffix controls hostname
convention (`vm-opnsense-01` for prod, `vm-opnsense-dev-01` for dev/test).
Dropping it silently allows invalid values. Validation retained in final file.

### 2. Existing defaults — intentional, not missing

The audit reset several defaults to empty/none:
- `iso_storage` default removed → restored to `"poc-iso"` (our storage pool name)
- `iso_file` default removed → restored to `"OPNsense-25.1-dvd-amd64.iso"`
- `wan_bridge` default removed → restored to `"vmbrWAN3"` (renamed 2026-04-03, see MEMORY.md)
- `tags` default changed from `["layer0", "opnsense"]` to `[]`→ restored

The audit likely had no visibility into the poc environment bridge naming or
storage pool names. These defaults reflect actual infrastructure decisions.

### 3. QEMU guest agent on OPNsense — nuance missing

The audit correctly says: disable agent initially (`agent { enabled = false }`).

What is not stated: OPNsense **does ship with QEMU guest agent support**, but it
is NOT installed by default. It is available as an OPNsense plugin:

```
System → Firmware → Plugins → os-qemu-guest-agent
```

Or via OPNsense CLI:
```sh
pkg install os-qemu-guest-agent
service qemu-guest-agent enable
service qemu-guest-agent start
```

**Impact:** Without the agent, Proxmox cannot:
- Report VM IP addresses in the UI
- Perform clean guest-aware snapshots (file system quiesce)
- Use agent-based health checks
- Run `qm guest exec` for automation hooks

**BY-SYSTEMS standard (added):**
Post-install Ansible step must install `os-qemu-guest-agent` and then flip
`agent { enabled = true }` in Terraform. Until then, `false` is correct and
safe. This is documented in `ansible-platform/roles/opnsense/` post-install tasks.

### 4. `cores` validation missing in audit

The audit added `cores >= 1` validation. Accepted and merged. Note: OPNsense
with Suricata/IDS needs at minimum 2 cores. The minimum of 1 is technically
correct for Terraform but operationally undersized for IDS workloads. A comment
is added in the variable description.

### 5. `memory` default raised — accepted

Default raised from 2048 to 4096 MiB. Rationale:
- OPNsense base: ~512 MiB
- Suricata with rules loaded: ~1-1.5 GiB
- Connection state tables under load: ~512 MiB
- Buffer: ~1 GiB
4096 MiB is the correct production-safe default.

---

## Final state after merge

Both `main.tf` and `variables.tf` in `modules/vm-opnsense/` now reflect the
merged result. See git history for diff. The poc environment `main.tf` has been
updated to `memory = 4096`.

VM was destroyed and recreated with all changes applied (2026-04-03).

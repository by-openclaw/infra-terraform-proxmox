# ADR-0003: OPNsense VM Configuration Standard

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** @yboujraf

## Context

OPNsense is the platform firewall. It is a FreeBSD-based appliance — not a
Linux cloud-init VM. Its Terraform definition requires several non-default
settings that differ from standard Linux VMs. Decisions must be documented
to prevent regressions on rebuild or module reuse.

## Decisions

### CPU type strategy

**Current (single node):** `type = "host"` with `flags = ["+aes"]`

- `host` exposes all physical CPU features to the guest — best performance.
- `flags = ["+aes"]` is explicit documentation and a guard: if someone
  changes `type` to a model that doesn't include AES-NI, Terraform/Proxmox
  will error at apply time.
- AES-NI is mandatory for crypto workloads (WireGuard, IPsec, TLS). This is
  a BY-SYSTEMS platform standard — never deploy OPNsense without it.

**When a second Proxmox node is added (HA/cluster):**
Switch to `type = "x86-64-v2-AES"`. This is a portable CPU baseline that
guarantees AES-NI by definition and allows live migration between nodes.

- The `-AES` suffix in `x86-64-v2-AES` **replaces** the `flags = ["+aes"]`
  need — but keep the flag anyway for explicitness.
- `type = "host"` blocks live migration: Proxmox refuses to migrate if nodes
  have different CPU generations.
- Performance delta: ~2-5% general compute. Negligible for crypto (AES offload
  handles the heavy lifting regardless of CPU model string).

**This change is NOT destructive.** It is an in-place VM config update. The VM
requires a **restart** to apply (OPNsense = the firewall = planned maintenance
window required). All traffic behind OPNsense will be down during the restart
(~30-60 seconds).

### QEMU guest agent

OPNsense does **not** install `qemu-guest-agent` by default. It is available
as a plugin (`os-qemu-guest-agent`) but must be explicitly installed.

**Terraform:** `agent { enabled = false }` at provision time. This is mandatory.
Without it, Proxmox waits indefinitely for the agent at boot, causing timeouts
and incorrect VM status reporting.

**Post-install standard:** The Ansible `opnsense` role installs and enables
`os-qemu-guest-agent` as the first bootstrap step (see
`ansible-platform/roles/opnsense/tasks/qemu-agent.yml`). This runs via SSH
before API-based tasks. After Ansible confirms the agent is running, Terraform
is updated to `agent { enabled = true }` and re-applied (in-place, no restart).

**Why it matters:**
- Without agent: no IP reporting in Proxmox UI, no filesystem-consistent
  snapshots, no `qm guest exec` automation hooks.
- With agent: full Proxmox integration, clean backup/snapshot support.

### Memory ballooning

**Always disabled** (`memory { floating = 0 }`).

Proxmox's memory balloon driver can reclaim RAM dynamically. On a firewall,
this causes connection state table instability and packet drops. Non-negotiable
for OPNsense/pfSense deployments.

### Firmware

**OVMF (UEFI)** for new builds. seabios is functional but not aligned with
current Proxmox/OPNsense best practices.

Switching an existing installed VM from seabios to ovmf is **destructive** —
the VM must be rebuilt. Do not switch in-place.

EFI disk: `type = "4m"`, `pre_enrolled_keys = false` (Secure Boot disabled —
not supported by OPNsense).

### Disk format

**Always `raw`** on ZFS datastores. ZFS does not support qcow2. Using qcow2
on a ZFS pool causes VM creation to fail with an unsupported format error.

## Consequences

### Positive

- Reproducible, consistent OPNsense deployments.
- AES-NI always available for crypto without manual verification.
- Clean Proxmox integration after Ansible bootstrap.
- No state table instability from memory ballooning.

### Negative

- CPU type change (host → x86-64-v2-AES) requires a maintenance window.
- QEMU agent requires a two-phase process: install via Ansible, then re-apply Terraform.
- OVMF switch requires full VM rebuild.

## Compliance

| Framework | Control | Relevance |
|---|---|---|
| ISO 27001 | A.13.1.1 | Network controls — firewall VM config is a documented security control |
| ISO 27001 | A.14.2.1 | Secure development — configuration decisions documented in ADR |
| NIS2 | Art. 21 | Security of network systems — AES-NI mandatory for crypto workloads |

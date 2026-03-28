# CLAUDE.md — infra-terraform-proxmox

> **Scope:** `infra` | **Component:** `terraform-proxmox`
> **GitHub:** `by-openclaw/infra-terraform-proxmox`

Claude Code and AI agent context for this repo. Read this before touching any file.

---

## What This Repo Does

Terraform modules (`vm-linux`, `lxc-standard`) and environment definitions for Proxmox VE VM and LXC provisioning at BY-SYSTEMS. This is the single source of truth for infrastructure-as-code on the Proxmox layer.

---

## Key Files — Always Read First

| File | Why |
|---|---|
| [`README.md`](README.md) | Structure, quick start, naming conventions |
| [`AGENTS.md`](AGENTS.md) | Agent onboarding, commit standards, what NOT to do |
| [`docs/variables-reference.md`](docs/variables-reference.md) | All module inputs, types, defaults |
| [`versions.tf`](versions.tf) | Pinned versions — do not change without instruction |
| [`providers.tf`](providers.tf) | Provider config (bpg/proxmox v0.99.0) |
| [`environments/poc/`](environments/poc/) | Live PoC environment |
| [`modules/vm-linux/`](modules/vm-linux/) | VM module — cloud-init, VirtIO, qemu-guest-agent |
| [`modules/lxc-standard/`](modules/lxc-standard/) | LXC module — unprivileged containers |

---

## Versions

| Tool | Version |
|---|---|
| Terraform | v1.14.8 |
| bpg/proxmox provider | v0.99.0 |

---

## Current Infrastructure State (2026-03-28)

| VM | Proxmox ID | IP | Status |
|---|---|---|---|
| vm-debian-bootstrap-test-01 | 100 | 10.6.225.11 | ✅ VALIDATED |
| vm-netbox-poc-01 | TBD | TBD | ⏸ PLANNED — not yet deployed |

### Proxmox Template Status

- `debian-12-cloud` template: **VM 9000** on `srv-proxmox-poc-01`
  - Disk: `poc-data:vm-9000-disk-0` (ZFS)
  - Cloud-init: `poc-data:vm-9000-cloudinit`
  - ✅ Ready for Terraform clone

### Storage

- `poc-data` (ZFS): correct target for all VM/LXC disks — use this
- `poc-iso` (NFS): iso/vztmpl only — **never use for qcow2 disk import**
- `local`: staging only for disk imports (temporary)

---

## State Backend

Currently: **local backend** (not committed).
Planned migration: GitLab CE when ready — do NOT migrate until instructed.

---

## Known Blockers

| Blocker | Status |
|---|---|
| vm-netbox-poc-01 not yet deployed | Unblocked — template ready, Terraform needs to be run |
| SSH key for Rune VM → PoC node | Add `id_ed25519_rune` pubkey to `/root/.ssh/authorized_keys` on PoC node |

---

## Constraints

- `terraform fmt` before every commit
- Never commit `terraform.tfvars` (secrets — gitignored)
- Never commit `.terraform/` directory
- State backend migration requires explicit approval
- All new resources follow naming convention: `vm-{service}-{env}-{seq:02d}`

---

## Secrets Location

```
~/.openclaw/workspace/infra/secrets/.proxmox-nonprod.env
```

API token: `svc-terraform@pve!ci` — do not rotate without updating this file.

---

## Related

- Platform docs: [`by-openclaw/doc-platform-core`](https://github.com/by-openclaw/doc-platform-core)
- Platform board: [`by-openclaw/platform-setup`](https://github.com/by-openclaw/platform-setup)
- GitHub Issues: [by-openclaw/platform-setup #44](https://github.com/by-openclaw/platform-setup/issues/44)

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

## Diagram Standard (mandatory)

When asked to generate or update a diagram, always follow this pipeline:

1. **Write/update source** → `assets/diagrams/<type>-<subject>-v<N>.puml` (PlantUML)
2. **Render to PNG** → `assets/exports/<type>-<subject>-v<N>.png` via Kroki:
   ```python
   import zlib, base64, urllib.request
   compressed = zlib.compress(puml_content.encode('utf-8'), 9)
   encoded = base64.urlsafe_b64encode(compressed).decode('ascii').rstrip('=')
   url = f"https://kroki.io/plantuml/png/{encoded}"
   urllib.request.urlretrieve(url, 'assets/exports/<name>.png')
   ```
3. **Write ASCII version** → `assets/diagrams/<type>-<subject>-v<N>-ascii.txt`
4. **Commit all three** + post PNG to Discord channel `1486559640945819828`
5. **Reference in docs** always via `assets/exports/` — never link to `assets/diagrams/` directly

**Two diagram modes:**
- `technical` (default): PlantUML dark theme, Kroki render, commit to repo
- `marketing` (when requested): descriptive prompt for Gemini Imagen (requires API key configured)

---

## Related

- Platform docs: [`by-openclaw/doc-platform-core`](https://github.com/by-openclaw/doc-platform-core)
- Platform board: [`by-openclaw/platform-setup`](https://github.com/by-openclaw/platform-setup)
- GitHub Issues: [by-openclaw/platform-setup #44](https://github.com/by-openclaw/platform-setup/issues/44)

# AGENTS.md — infra-terraform-proxmox

Terraform modules (`vm-linux`, `lxc-standard`, `vm-opnsense`, `sdn-poc`) and environment definitions for Proxmox VE SDN, VM, and LXC provisioning at BY-SYSTEMS.

## Always Read First

Before touching anything in this repo:

1. [`README.md`](README.md) — structure, quick start, naming conventions
2. [`CLAUDE.md`](CLAUDE.md) — agent-specific constraints, known state, blockers
3. [`docs/variables-reference.md`](docs/variables-reference.md) — all module input variables
4. [`versions.tf`](versions.tf) — pinned provider and Terraform versions
5. [`environments/poc/`](environments/poc/) — current live environment definition

## Coding & Commit Standards

- **Conventional Commits** — `type(scope): description`
  - `feat(vm-linux): add cloud-init user_data support`
  - `fix(poc): correct IP allocation for vm-netbox`
  - `chore: bump bpg/proxmox to v0.100.0`
- **Terraform style:** `terraform fmt` before every commit
- **Variable names:** snake_case, descriptive, consistent with module interface
- **Resource naming convention:**

  | Resource | Pattern | Example |
  |---|---|---|
  | VM | `vm-{service}-{seq:02d}` for `env=prod`; `vm-{service}-{env}-{seq:02d}` for non-prod | `vm-netbox-01`, `vm-netbox-dev-01` |
  | LXC | `lxc-{service}-{seq:02d}` for `env=prod`; `lxc-{service}-{env}-{seq:02d}` for non-prod | `lxc-pihole-01`, `lxc-pihole-test-01` |
  | Module call | matches resource name | `module "netbox"` |

- **Critical env rule (2026-04-03):** `env` is per VM/LXC, not per Proxmox node. `srv-proxmox-poc-01` is a node name (hardware label), not an environment tier.

- **Branch naming:** `feat/{issue-id}-{description}` or `fix/{issue-id}-{description}`
- **No merge commits** — rebase only

## What NOT To Do

> Also read [`CLAUDE.md`](CLAUDE.md) for architecture constraints, known blockers, and state backend rules.

- ❌ Do NOT change provider or Terraform version pins without explicit instruction
- ❌ Do NOT commit `terraform.tfvars` (contains secrets) — it is gitignored
- ❌ Do NOT commit `.terraform/` lock files unless pinning is intentional
- ❌ Do NOT use `terraform apply` directly in CI without plan review step
- ❌ Do NOT migrate the state backend without explicit sign-off from My Lord
- ❌ Do NOT add resources outside `modules/` or `environments/` without discussion
- ❌ Do NOT use count/for_each patterns that break state key stability without justification

## Network Naming Rule (locked 2026-04-03)

- OPNsense LAN attaches to `vmbrAPPS` as trunk uplink
- Proxmox SDN zone = node/network label (`poc` on this node). Do **not** infer VM environment from SDN zone name.
- **SDN deployed 2026-04-03** — zone `poc`, VNets `mgmt`/`dmz`/`svc` live in Proxmox
- `TerraformRole` now includes `SDN.Allocate + SDN.Audit` — updated 2026-04-03
- Provider resolved to `bpg/proxmox v0.100.0` (lock file updated)
- VNet names are environment-agnostic: `mgmt`, `dmz`, `svc`
- Do **not** introduce `vmbrPOC`, `pocmgmt`, `vnet-poc-svc`, or similar invented bridge names

## ISO Storage Rule (locked 2026-04-03)

- `poc-iso` is the only valid storage for ISO / vztmpl content on this node (storage pool name, not env tier)
- Do **not** place ISOs on `local`, `local-lvm`, or any thin-LVM storage
- `poc-data` / ZFS is for VM and LXC disks
- `poc-iso` / NFS is for ISO and template media only

## GitHub Repo

<https://github.com/by-openclaw/infra-terraform-proxmox>

## Agent: Rune

Maintained by Rune (DevOps familiar) for the BY-SYSTEMS PoC platform.
Owner: @yboujraf

## Doc Maintenance — After Every Successful Build

After each successful CI build (all jobs green), update these files to reflect current state:
- **AGENTS.md** — Update "Project Stats", version, checklist, roadmap progress
- **CLAUDE.md** — Update build commands, file table, current state if anything changed
- **README.md** — Update badges, feature lists, version numbers

Commit separately: `docs: update project docs to v{version}`

This ensures any AI agent (or human) picking up the project always has accurate, current documentation.

---

## Project Stats

> Auto-updated on every release. Last updated: 2026-03-31

| Metric | Value |
|---|---|
| Version | v0.2.1 |
| Tagged releases | 2 |
| Total files | 63 |
| Python source files | 2 |
| Test files | 0 |
| Terraform files | 14 |
| YAML/Ansible files | 2 |
| ADR decisions | 2 |
| CI workflows | 2 |

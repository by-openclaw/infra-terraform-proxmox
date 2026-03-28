# AGENTS.md — infra-terraform-proxmox

Terraform modules (`vm-linux`, `lxc-standard`) and environment definitions for Proxmox VE provisioning at BY-SYSTEMS.

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
  | VM | `vm-{service}-{env}-{seq:02d}` | `vm-netbox-poc-01` |
  | LXC | `lxc-{service}-{env}-{seq:02d}` | `lxc-pihole-poc-01` |
  | Module call | matches resource name | `module "netbox"` |

- **Branch naming:** `feat/{issue-id}-{description}` or `fix/{issue-id}-{description}`
- **No merge commits** — rebase only

## What NOT To Do

- ❌ Do NOT change provider or Terraform version pins without explicit instruction
- ❌ Do NOT commit `terraform.tfvars` (contains secrets) — it is gitignored
- ❌ Do NOT commit `.terraform/` lock files unless pinning is intentional
- ❌ Do NOT use `terraform apply` directly in CI without plan review step
- ❌ Do NOT migrate the state backend without explicit sign-off from My Lord
- ❌ Do NOT add resources outside `modules/` or `environments/` without discussion
- ❌ Do NOT use count/for_each patterns that break state key stability without justification

## GitHub Repo

<https://github.com/by-openclaw/infra-terraform-proxmox>

## Agent: Rune

Maintained by Rune (DevOps familiar) for the BY-SYSTEMS PoC platform.
Owner: @yboujraf

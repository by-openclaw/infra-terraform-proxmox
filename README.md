# infra-terraform-proxmox

Terraform modules and environment definitions for Proxmox VE VM and LXC provisioning at BY-SYSTEMS.

## Structure

```
modules/
  vm-linux/          # Reusable module for Linux VMs (cloud-init, VirtIO, qemu-guest-agent)
  lxc-standard/      # Reusable module for unprivileged LXC containers
environments/
  poc/               # PoC environment (srv-proxmox-poc-01)
providers.tf         # Proxmox provider configuration
versions.tf          # Terraform + provider version pins
```

## Prerequisites

- Terraform >= 1.5.0
- Proxmox VE 9.x node with API token configured
- Cloud-init template (`debian-12-cloud`) created on target Proxmox node
- `qemu-guest-agent` installed in all templates

## Quick Start

```bash
# 1. Navigate to environment
cd environments/poc

# 2. Configure secrets
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars   # fill in API URL and token

# 3. Initialize
terraform init

# 4. Plan
terraform plan

# 5. Apply
terraform apply
```

## Creating a Proxmox API Token

In Proxmox WebUI: **Datacenter → Permissions → API Tokens → Add**

Required permissions for the token user:
- `VM.Allocate`
- `VM.Config.Disk`
- `VM.Config.Memory`
- `VM.Config.Network`
- `VM.Config.Options`
- `VM.PowerMgmt`
- `Datastore.AllocateSpace`
- `Datastore.Audit`
- `SDN.Use`

## Naming Conventions

| Resource | Convention | Example |
|----------|------------|---------|
| VM | `vm-{service}-{env}-{seq:02d}` | `vm-netbox-poc-01` |
| LXC | `lxc-{service}-{env}-{seq:02d}` | `lxc-pihole-poc-01` |
| Module call | matches resource name | `module "netbox"` |

## Status

| VM | Status | IP | Notes |
|----|--------|----|-------|
| vm-netbox-poc-01 | ⏸ Blocked | 10.6.240.10 | Awaiting debian-12-cloud template creation |

## Roadmap

- [ ] Create Debian 12 cloud-init template on poc-iso
- [ ] Deploy vm-netbox-poc-01
- [ ] Add LXC examples (pihole, step-ca)
- [ ] Migrate state backend to MinIO/GitLab when GitLab CE is ready
- [ ] Evaluate migration to `bpg/proxmox` provider

## Related

- GitHub Issues: [by-openclaw/platform-setup #44](https://github.com/by-openclaw/platform-setup/issues/44)
- Platform board: [BY-SYSTEMS Platform](https://github.com/orgs/by-openclaw/projects/1)

## AI Agent Context

This repo includes onboarding files for AI agents (Claude Code, Codex, etc.):

- [`AGENTS.md`](AGENTS.md) — generic agent onboarding: what this repo is, commit standards, what NOT to do
- [`CLAUDE.md`](CLAUDE.md) — Claude Code specific: current state, blockers, key files, constraints

**Agent:** Rune | **Owner:** @yboujraf | **Org:** [by-openclaw](https://github.com/by-openclaw)

## Status (updated 2026-03-28)

| VM | Proxmox ID | IP | Status |
|---|---|---|---|
| vm-debian-bootstrap-test-01 | 100 | 10.6.225.11 | ✅ VALIDATED |
| vm-netbox-poc-01 | TBD | TBD | ⏸ PLANNED |
<!-- webhook test 2026-03-28T16:02:52Z -->

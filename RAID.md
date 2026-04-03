# RAID.md — infra-terraform-proxmox

> Scope: repo-level risks, issues, and dependencies.
> Platform-wide items: doc-platform-core/docs/raid.md
> Rule: if it affects this repo only → here. If it crosses repos → platform RAID.

---

## Risks

| ID | Risk | Impact | Likelihood | Mitigation | Status |
|---|---|---|---|---|---|
| R-001 | Single Proxmox node — no HA during PoC | HIGH | MEDIUM | Accept for PoC. Plan multi-node before prod. | OPEN |
| R-002 | No state locking — concurrent apply could corrupt state | HIGH | LOW | Single operator (Rune). Phase 2: GitLab managed state with locking. | OPEN |
| R-003 | State file contains secrets (IPs, tokens in outputs) | MEDIUM | LOW | State gitignored. Backed up to NAS (private share). | OPEN |

| R-004 | Proxmox API token `svc-terraform@pve!ci` missing env label per ADR-0010 (`svc-{function}-{env}`) | MEDIUM | HIGH | Rename to `svc-terraform-poc@pve!ci` when next maintenance window. Update all references. | OPEN |
| R-005 | CLAUDE.md/AGENTS.md did not reference ADR-0010/ADR-0012 | LOW | HIGH | Fixed in sprint Block 3 | IN PROGRESS |

## Issues

| ID | Issue | Priority | Status | GitHub |
|---|---|---|---|---|
| I-001a | ~~SDN zone + VNets not deployed~~ | HIGH | **CLOSED 2026-04-03** | #78 |
| I-001b | OPNsense VM not yet deployed | HIGH | OPEN | #79 |
| I-002 | Debian 12 cloud-init template needs serial0 removal verified | LOW | RESOLVED | Template 9000 clean |

## Dependencies

| ID | Dependency | Blocks | Status |
|---|---|---|---|
| D-001 | Proxmox API token (`svc-terraform@pve!ci`) | All terraform operations | OK |
| D-002 | debian-12-cloud template (VM 9000) | All VM provisioning | OK |
| D-003 | GitLab CE deployment (Phase 2) | State backend migration | BLOCKED |

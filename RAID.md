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

## Issues

| ID | Issue | Priority | Status | GitHub |
|---|---|---|---|---|
| I-001 | OPNsense VM + vmbrPOC bridge not deployed | HIGH | OPEN | — |
| I-002 | Debian 12 cloud-init template needs serial0 removal verified | LOW | RESOLVED | Template 9000 clean |

## Dependencies

| ID | Dependency | Blocks | Status |
|---|---|---|---|
| D-001 | Proxmox API token (`svc-terraform@pve!ci`) | All terraform operations | OK |
| D-002 | debian-12-cloud template (VM 9000) | All VM provisioning | OK |
| D-003 | GitLab CE deployment (Phase 2) | State backend migration | BLOCKED |

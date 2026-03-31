# Audit: infra-terraform-proxmox — Agent Files & Repo Health

> **Audited:** 2026-03-30
> **Auditor:** Rune (via Claude Opus)
> **Version:** v0.2.0 | **Commits:** 29 | **Files:** 50

---

## What exists

| File | Exists | Status |
|---|---|---|
| CLAUDE.md | Yes | Good — infra snapshot, template status, state backend docs |
| AGENTS.md | Yes | Good — Terraform-specific constraints, naming convention |
| README.md | Yes | Good — module structure, prerequisites, quick start |
| CONTRIBUTING.md | **No** | Missing |
| CHANGELOG.md | Yes | v0.2.0 + unreleased (backup scripts) |
| SECURITY.md | **No** | Missing — IaC repo managing infra should have one |
| RAID.md | **No** | Missing |
| docs/adr/ | Yes | Empty — README only |
| docs/audits/ | **No** | Created now |
| .github/CODEOWNERS | Yes | @yboujraf |
| .github/ISSUE_TEMPLATE/ | **No** | Missing |
| .github/PULL_REQUEST_TEMPLATE.md | **No** | Missing |

---

## What's good

- CLAUDE.md has detailed infra snapshot with IPs, template status, storage layout
- AGENTS.md has Terraform-specific "What NOT to do" (state migration, count/for_each stability)
- State backup documented (NAS sync via scripts/tf.sh)
- Provider version pinned (bpg/proxmox v0.99.0)

---

## What's missing

| # | Item | Priority | Why |
|---|---|---|---|
| M1 | CONTRIBUTING.md | HIGH | No docs on how to run terraform fmt, plan, apply workflow locally |
| M2 | SECURITY.md | HIGH | IaC manages infrastructure — needs disclosure policy for infra vulns |
| M3 | RAID.md (per-repo) | MEDIUM | Repo-scoped risks: single-node Proxmox, no state locking, template not finalized |
| M4 | Repo-level ADRs | MEDIUM | Candidates: bpg/proxmox provider choice, local state + NAS backup, module structure |
| M5 | Issue/PR templates | LOW | No templates |
| M6 | `add-to-project` workflow | MEDIUM | Board automation missing |
| M7 | ADR-0006 reference | LOW | CLAUDE.md doesn't reference platform charter (unlike other repos) |
| M8 | discord-notify.yml | VERIFY | May still exist — audit 14 flagged this. Verify and remove if present. |

---

## CLAUDE.md / AGENTS.md issues

| Item | Problem | Fix |
|---|---|---|
| CLAUDE.md infra snapshot | "2026-03-29" — may be stale if VMs changed | Verify current |
| CLAUDE.md no ADR-0006 reference | Only repo without charter reference | Add reference |
| AGENTS.md stats | 29 commits, 50 files — verify | Update |
| docs/poc-infra-diagram.py | Python script in docs/ — should be in scripts/ or assets/ | Move or note why |
| docs/variables-reference.md line 30 | Contains `BySyst3ms_` password default | Redact: `<REDACTED:password>` |

---

## Secrets check

- **docs/variables-reference.md:30** — password `BySyst3ms_` as Terraform variable default → **REDACT**
- **docs/vm-test-spec-review.md:81,133** — password `BySyst3ms_` → **REDACT**
- IP addresses — acceptable (private repo, needed for Terraform context)

---

*Action: Create CONTRIBUTING.md, SECURITY.md. Redact passwords. Add ADR-0006 reference to CLAUDE.md. Verify discord-notify.yml removal.*

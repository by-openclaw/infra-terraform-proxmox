# ADR-0002: Local State with NAS Backup

**Status:** Accepted
**Date:** 2026-03-30
**Deciders:** @yboujraf

## Context

No remote backend is available during the PoC phase. There is a single operator, so state locking is not critical. However, the state file must survive the loss of the Rune VM where Terraform runs.

## Decision

- **Phase 1:** Local state file with automated NAS backup sync.
- **Phase 2:** Migrate to GitLab managed state when available.

## Consequences

### Positive

- Zero external dependencies during PoC — no backend configuration required.
- `scripts/tf.sh` wraps all terraform commands with automatic state backup after each apply.
- Manual sync available via `backup-state.py` for ad-hoc backups.

### Negative

- No state locking (acceptable for single operator; becomes a risk if a second operator is added).
- State recovery requires manual retrieval from NAS if the Rune VM is lost.
- Phase 2 migration to GitLab managed state will require a `terraform state push`.

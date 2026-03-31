# ADR-0001: Use bpg/proxmox Provider

**Status:** Accepted
**Date:** 2026-03-30
**Deciders:** @yboujraf

## Context

The `telmate/proxmox` provider is abandoned and incompatible with Proxmox VE 9. It lacks support for newer API endpoints and has unresolved critical bugs. The `bpg/proxmox` provider is actively maintained with full Proxmox API v2 support.

## Decision

Use the **bpg/proxmox** provider, pinned at **v0.99.0**. The telmate provider is not used anywhere.

## Consequences

### Positive

- Full compatibility with Proxmox VE 9 and its API v2.
- Active maintenance with regular releases and bug fixes.
- Richer resource coverage (cloud-init, VLAN, storage, firewall).

### Negative

- All modules must use bpg resource types (`proxmox_virtual_environment_*`).
- Provider version must be pinned in `versions.tf` and updated deliberately.
- No migration path from telmate — any legacy state using telmate resources requires manual import.

## Compliance

| Framework | Control | Relevance |
|---|---|---|
| ISO 27001 | A.14.2.1 | Secure development — single provider pinned in versions.tf, deliberate updates only |
| ISO 27001 | A.14.2.5 | Secure system engineering — bpg provider chosen for active maintenance and security patching |

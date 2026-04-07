## Summary

<!-- One sentence: what changed and why. -->

Closes #

## Type

- [ ] feat — new feature
- [ ] fix — bug fix
- [ ] docs — documentation only
- [ ] chore — maintenance, refactor, CI
- [ ] security — security fix or hardening

## Files changed

<!-- List every file touched. One row per file. -->

| File | Type | Change |
|------|------|--------|
| `modules/example/main.tf` | new / update | One-line description |
| `environments/poc/main.tf` | update | One-line description |

## Modules / resources covered

<!-- For each Terraform module or resource this PR touches. -->

| Module / Resource | Action | Tested |
|------------------|--------|--------|
| `modules/vm-linux` | update | `terraform plan` |
| `environments/poc` | apply | `terraform apply` |

## Test results

| Check | Command | Status |
|-------|---------|--------|
| Format | `terraform fmt -check` | clean |
| Validate | `terraform validate` | pass |
| Plan | `terraform plan` | N resources |
| CI | Validate (poc) | pass |

## Safety

<!-- What changes on the live infrastructure? -->

- **No infra change:** plan only / docs only
- **Non-destructive:** add resources, no destroy
- **Destructive (list what):**

## How to review

1. Read `terraform plan` output — verify no unexpected destroys
2. Read module changes — verify variable defaults are safe
3. Check: no hardcoded credentials, IPs come from variables
4. Check: state backup taken before apply

## Checklist

### Quality
- [ ] `terraform fmt` clean
- [ ] `terraform validate` passes
- [ ] `terraform plan` reviewed (no unexpected destroys)
- [ ] State backed up before apply

### Security
- [ ] No secrets in `.tf` files (use variables + env)
- [ ] No real credentials in committed files

### Docs
- [ ] CHANGELOG entry added (if user-facing change)
- [ ] CLAUDE.md updated (if repo state changed)
- [ ] `docs/variables-reference.md` updated (if variables changed)

## Review

- [ ] @yboujraf approved

<!--
Merge rules (ADR-0019):
- Agents open PRs, never merge
- @yboujraf is sole merge authority
- No force-push to main — ever
-->

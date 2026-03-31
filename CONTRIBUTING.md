# Contributing to infra-terraform-proxmox

> Read [README.md](README.md) and [CLAUDE.md](CLAUDE.md) before starting.

---

## Before You Start

- Check existing issues and [RAID.md](RAID.md) for known risks
- Open or link an issue before significant work
- For architecture-impacting changes, create or update an ADR in `docs/adr/`

---

## Setup

```bash
cd environments/poc
cp terraform.tfvars.example terraform.tfvars  # Fill in secrets
terraform init
terraform plan  # Always plan before apply
```

**Never commit `terraform.tfvars`** — it contains secrets and is gitignored.

---

## Branch Naming

```text
{type}/{issue-id}-{short-description}
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`

---

## Commit Standard

Conventional Commits — `type(scope): description`

```text
feat(modules): add lxc-standard module
fix(poc): correct OOB gateway to 10.6.224.1
docs(variables): update reference table
chore(ci): add terraform fmt check
```

| Type | Version bump | When |
|---|---|---|
| `fix:` | patch | Bug fixes |
| `feat:` | minor | New features |
| `feat!:` / `BREAKING CHANGE:` | major | Breaking changes |
| `docs:` `chore:` | none | Non-functional |

---

## Definition of Done — PR Checklist

- [ ] `terraform fmt -check` passes
- [ ] `terraform validate` passes
- [ ] `terraform plan` reviewed — no unexpected changes
- [ ] No secrets in committed files (`.tfvars` gitignored)
- [ ] Module inputs documented in `variables.tf` with `description`
- [ ] `docs/variables-reference.md` updated if inputs changed
- [ ] Naming convention followed: `vm-{service}-{env}-{seq:02d}`
- [ ] CHANGELOG.md entry added
- [ ] CLAUDE.md current state updated if infra changed
- [ ] State backed up to NAS after apply: `python3 scripts/backup-state.py --env poc`

---

## Terraform Workflow

```bash
# 1. Format
terraform fmt -recursive

# 2. Validate
terraform validate

# 3. Plan (always review)
terraform plan -out=plan.tfplan

# 4. Apply (only after plan review)
terraform apply plan.tfplan

# 5. Backup state
python3 scripts/backup-state.py --env poc
```

**Use `scripts/tf.sh` as wrapper** — it auto-backs up state after apply/destroy.

---

## Diagram Standard

- Source: PlantUML `.puml` → `assets/diagrams/`
- Render: PNG via Kroki → `assets/exports/`
- Docs link to `assets/exports/` only

---

## Post-Release Checklist

After each release:
- [ ] AGENTS.md — update Project Stats
- [ ] CLAUDE.md — update infrastructure snapshot if changed
- [ ] README.md — update version, module documentation

Commit: `docs: update project docs to v{version}`

---

## Release Process

- Use conventional commits consistently
- Release Please determines version bumps automatically
- Never manually edit version strings

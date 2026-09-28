# Contributing to infra-terraform-proxmox

> Read [README.md](README.md) and [CLAUDE.md](CLAUDE.md) before starting.

---

## Before You Start

- Check existing issues and [RAID.md](RAID.md) for known risks
- Open or link an issue before significant work
- For architecture-impacting changes, create or update an ADR in `docs/adr/`

---

## Setup

Terraform runs through ansible-platform `playbooks/terraform.yml`: it reads the
Proxmox API token from Vault and hands it to the `terraform` process as `TF_VAR_*`
environment variables. There is no `terraform.tfvars`; do not create one (the
file would also override the environment).

```bash
# from the ansible-platform checkout
ansible-playbook playbooks/terraform.yml                        # plan
ansible-playbook playbooks/terraform.yml -e tf_apply=true       # apply that plan
```

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

**Apply through ansible-platform `playbooks/terraform.yml`** — it backs the state up to the NAS after every apply.

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

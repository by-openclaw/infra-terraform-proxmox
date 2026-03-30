# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1](https://github.com/by-openclaw/infra-terraform-proxmox/compare/v0.2.0...v0.2.1) (2026-03-30)


### Bug Fixes

* correct pull_request trigger in project-board-sync workflow ([a866fb7](https://github.com/by-openclaw/infra-terraform-proxmox/commit/a866fb7852285520f446568bba8e56af8f2668ab))
* terraform fmt provider.tf (double space before comment) ([161fa67](https://github.com/by-openclaw/infra-terraform-proxmox/commit/161fa67b651c13f475c9ef01ba0fc1f359f530fe))

## [Unreleased]

### Added
- `scripts/backup-state.py`: Backs up `terraform.tfstate` to Synology NAS `/by-terraform-state/<env>/`
- `scripts/tf.sh`: Terraform wrapper — auto-runs state backup after every `apply` or `destroy`

### Fixed
- OOB gateway corrected everywhere: `10.6.255.254` → `10.6.224.1` (pfSense) in all docs, READMEs, diagrams

## [0.2.0] — 2026-03-28

### Added
- `modules/vm-linux`: Reusable module for Linux VMs with cloud-init, VirtIO disk/NIC, qemu-guest-agent
- `modules/lxc-standard`: Reusable module for unprivileged LXC containers
- `environments/poc`: PoC environment — `vm-debian-bootstrap-test-01` (ID 100, 10.6.225.11) validated
- `providers.tf`: bpg/proxmox v0.99.0 (replaced telmate — incompatible with PVE 9)
- `versions.tf`: Terraform >= 1.5.0, provider pins
- `docs/variables-reference.md`: Full module input reference
- GitHub Actions CI: `terraform fmt -check` + `terraform validate` on PRs
- `.gitignore`: Excludes `*.tfvars`, `.terraform/`, tfstate files
- `assets/diagrams/`: PlantUML + ASCII architecture diagrams

### Validated
- `vm-debian-bootstrap-test-01` (ID 100, IP 10.6.225.11): SSH (Win11 + Rune VM keys), cloud-init, QEMU agent, locale, timezone all confirmed working
- `debian-12-cloud` template (VM 9000): serial port removed, clean baseline

[Unreleased]: https://github.com/by-openclaw/infra-terraform-proxmox/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/by-openclaw/infra-terraform-proxmox/releases/tag/v0.2.0

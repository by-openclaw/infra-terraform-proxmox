# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

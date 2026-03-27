# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `modules/vm-linux`: Reusable module for Linux VMs with cloud-init, VirtIO disk/NIC, qemu-guest-agent
- `modules/lxc-standard`: Reusable module for unprivileged LXC containers
- `environments/poc`: PoC environment with vm-netbox-poc-01 definition
- `providers.tf`: telmate/proxmox provider configuration
- `versions.tf`: Terraform >= 1.5.0 and provider version pins
- GitHub Actions CI: `terraform fmt -check` and `terraform validate` on PRs
- `.gitignore`: Excludes *.tfvars, .terraform/, tfstate files

### Notes
- vm-netbox-poc-01 deployment blocked pending `debian-12-cloud` template creation
- State backend: local (migrate to remote when GitLab CE deployed)

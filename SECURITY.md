# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| 0.2.x | ✅ Current |
| < 0.2 | ❌ No fixes |

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Report privately via: security@by-systems.be

Include:
- Description of the vulnerability
- Steps to reproduce
- Impact assessment (especially infrastructure state exposure)
- Affected version(s)

We aim to acknowledge reports within 48 hours and provide a fix within 14 days for confirmed issues.

## Scope

This repo manages Proxmox VM/LXC provisioning via Terraform. Security considerations:
- No `terraform.tfvars`: the Proxmox API token lives in Vault and reaches `terraform` only as an environment variable (ansible-platform `playbooks/terraform.yml`)
- State files contain sensitive data — backed up to NAS, not committed
- Proxmox API authentication uses dedicated `svc-terraform@pve!ci` token (least privilege)
- Cloud-init injects SSH keys and user credentials at VM creation time

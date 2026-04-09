# Module: vm-linux

Reusable Terraform module for provisioning Linux VMs on Proxmox VE using cloud-init templates.

## Features

- Clones from a cloud-init enabled template (e.g., `debian-12-cloud`)
- Always uses VirtIO disk and VirtIO NIC for best performance
- Always enables `qemu-guest-agent` (required for noVNC copy/paste and proper shutdown)
- Always attaches a cloud-init drive (IDE2)
- Injects SSH public keys via cloud-init
- Configures static IP via cloud-init `ipconfig0`

## Requirements

- Proxmox template with cloud-init support must exist on the target node
- `qemu-guest-agent` must be installed inside the template image
- Terraform provider: `telmate/proxmox ~> 2.9`

## Usage

```hcl
module "my_vm" {
  source      = "../../modules/vm-linux"
  name        = "vm-myservice-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"
  cores       = 2
  memory      = 4096
  disk_size   = "20G"
  storage     = "poc-data"
  ip          = "10.6.240.x/20"
  gateway     = "10.6.224.1"
  ssh_keys    = ["ssh-ed25519 AAAA... user@host"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | VM name (convention: `vm-{svc}-{env}-{seq}`) | string | — | yes |
| `target_node` | Proxmox node name | string | — | yes |
| `clone` | Template name to clone | string | — | yes |
| `cores` | CPU cores | number | `2` | no |
| `memory` | Memory in MB | number | `2048` | no |
| `disk_size` | Primary disk size | string | `"20G"` | no |
| `storage` | Storage pool name | string | — | yes |
| `network_bridge` | Proxmox bridge name | string | `"vmbrOOB"` | no |
| `ip` | Static IP in CIDR | string | — | yes |
| `gateway` | Default gateway | string | — | yes |
| `ci_user` | Cloud-init user | string | `"sysadmin"` | no |
| `ssh_keys` | SSH public keys list | list(string) | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vm_id` | Proxmox VM ID |
| `vm_name` | VM name |
| `vm_ip` | Assigned IP address |
| `target_node` | Deployed node |

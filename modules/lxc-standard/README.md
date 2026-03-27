# Module: lxc-standard

Reusable Terraform module for provisioning standard unprivileged LXC containers on Proxmox VE.

## Features

- Provisions from a Proxmox LXC template (`.tar.zst`)
- Runs unprivileged by default (security best practice)
- Starts on boot by default
- Configures static IP via Proxmox LXC network settings
- Injects SSH public keys into root account

## Requirements

- LXC template must exist in Proxmox storage (`local:vztmpl/...`)
- Download templates via: Proxmox → node → local → CT Templates → Download
- Terraform provider: `telmate/proxmox ~> 2.9`

## Usage

```hcl
module "my_lxc" {
  source         = "../../modules/lxc-standard"
  name           = "lxc-pihole-poc-01"
  target_node    = "srv-proxmox-poc-01"
  ostemplate     = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
  cores          = 1
  memory         = 512
  disk           = "8G"
  storage        = "poc-data"
  ip             = "10.6.241.10/20"
  gateway        = "10.6.255.254"
  ssh_keys       = ["ssh-ed25519 AAAA... user@host"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | LXC hostname (convention: `lxc-{svc}-{env}-{seq}`) | string | — | yes |
| `target_node` | Proxmox node name | string | — | yes |
| `ostemplate` | LXC template path | string | — | yes |
| `cores` | CPU cores | number | `1` | no |
| `memory` | Memory in MB | number | `512` | no |
| `swap` | Swap in MB | number | `0` | no |
| `disk` | Root filesystem size | string | `"8G"` | no |
| `storage` | Storage pool name | string | — | yes |
| `network_bridge` | Proxmox bridge name | string | `"vmbrMGMT"` | no |
| `ip` | Static IP in CIDR | string | — | yes |
| `gateway` | Default gateway | string | — | yes |
| `unprivileged` | Run as unprivileged container | bool | `true` | no |
| `onboot` | Start on Proxmox node boot | bool | `true` | no |
| `ssh_keys` | SSH public keys list | list(string) | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| `lxc_id` | Proxmox LXC container ID |
| `lxc_name` | LXC hostname |
| `lxc_ip` | Assigned IP address |
| `target_node` | Deployed node |

# lxc-cloudinit

Terraform module — provisions cloud-init-enabled LXC containers on Proxmox via the **bpg/proxmox** provider's `proxmox_virtual_environment_container` resource.

Replaces / coexists with `lxc-standard` (Telmate provider, no cloud-init).
Use this module for any new LXC where cloud-init first-boot configuration is wanted (hostname, users, packages, SSH keys, network).

## Requirements

- bpg/proxmox provider `~> 0.99`
- Proxmox VE 8.x+
- **An LXC template with cloud-init pre-installed** (see below)

## Template sources — multi-distro

Standard Proxmox `pveam` templates (`debian-*-standard`, `ubuntu-*-standard`) do **not** include cloud-init. Use **images.linuxcontainers.org** images, which ship cloud-init for the major distros.

Download declaratively via `proxmox_virtual_environment_download_file` (recommended), or once via `pveam download`.

| Distro | Template URL (linuxcontainers.org) |
|---|---|
| Debian 13 | `https://images.linuxcontainers.org/images/debian/13/amd64/cloud/<date>/rootfs.tar.xz` |
| Ubuntu 24.04 | `https://images.linuxcontainers.org/images/ubuntu/24.04/amd64/cloud/<date>/rootfs.tar.xz` |
| Rocky Linux 9 | `https://images.linuxcontainers.org/images/rockylinux/9/amd64/cloud/<date>/rootfs.tar.xz` |

(The `<date>` slug rotates daily; use the `current` symlink or pin a snapshot.)

Once downloaded to e.g. `poc-iso:vztmpl/debian-13-cloud_amd64.tar.xz`, pass that to `ostemplate_file_id`.

## Hostname, OS slug, domain, FQDN

The hostname **encodes the OS** so an operator can tell at a glance (or via `hostname --fqdn`) what's inside an LXC without inspecting it. Naming pattern:

```
lxc-{role}-{os_slug}-{env}-{seq:02d}
```

| Token | Allowed values | Notes |
|---|---|---|
| `role` | short zone or service label (`mgmt`, `dmz`, `svc`, `vpn`, `iot`, `voip`, `storage`, `media`, `gaming`, `cctv`, …) | Matches `infra/0004 §1` zone names where applicable |
| `os_slug` | `deb13` `deb12` `ubu2404` `ubu2204` `rocky9` `rocky8` `alma9` `alpine320` … | Distro + major version, lowercase, no dots |
| `env` | per `infra/0005`: `dev` `test` `staging` `acc` `prod` `drp` | |
| `seq` | zero-padded sequence (`01`, `02`, …) | |

**FQDN** is the hostname joined with the DNS domain:

| Input | Variable | Sets | Example |
|---|---|---|---|
| Short hostname | `name` | `/etc/hostname` | `lxc-mgmt-deb13-test-01` |
| Domain | `dns_domain` | resolver search + FQDN suffix | `test.by-research.be` |
| **FQDN** (derived) | — | `hostname --fqdn` and `/etc/hosts` line `127.0.1.1 <fqdn> <hostname>` | `lxc-mgmt-deb13-test-01.test.by-research.be` |

cloud-init reads `name` + `dns_domain` from the Terraform `initialization` block and writes both `/etc/hostname` and the `/etc/hosts` self-line on first boot. Per `naming/0001 §9`, every internal host **must** have an FQDN, so `dns_domain` is effectively mandatory; the empty default is only for the rare hostname-only edge case.

The module also exposes an `fqdn` output (`module.lxc_mgmt_deb13.fqdn`) for consumers (DNS-record provisioning, NetBox sync, etc.).

## DNS resolvers

`dns_servers` is a **dual-stack** list — pass both the IPv4 and IPv6 addresses of the resolver (OPNsense Unbound listens on both stacks per interface). cloud-init writes one `nameserver` line per entry in `/etc/resolv.conf`; the kernel resolver picks the working stack at query time.

```hcl
dns_servers = [
  "10.11.1.1",     # FW Unbound — IPv4 on this VLAN
  "fd11:1::1",     # FW Unbound — IPv6 ULA on this VLAN
]
```

IPv4-only or IPv6-only is allowed but **not recommended** for any internal LXC (loses the half-stack on a single-stack outage).

## Usage — multi-distro examples

### Debian 13 on MGMT VLAN

Resulting FQDN: **`lxc-mgmt-deb13-test-01.test.by-research.be`**

```hcl
module "lxc_mgmt_deb13" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-mgmt-deb13-test-01"   # role=mgmt  os_slug=deb13  env=test  seq=01
  vmid        = 1500
  target_node = "srv-proxmox-01"
  env         = "test"
  tags        = ["probe", "vlan2010", "os-debian-13"]

  ostemplate_file_id = "poc-iso:vztmpl/debian-13-cloud_amd64.tar.xz"
  cores   = 1
  memory  = 512
  disk_gb = 4
  storage = "poc-data"

  network_bridge = "vmbrAPPS"
  vlan_tag       = 2010
  ipv4_address   = "10.11.1.100/24"
  ipv4_gateway   = "10.11.1.1"
  ipv6_address   = "fd11:1::100/64"
  ipv6_gateway   = "fd11:1::1"

  dns_domain  = "test.by-research.be"      # FQDN = ${name}.${dns_domain}
  dns_servers = ["10.11.1.1", "fd11:1::1"] # dual-stack — OPNsense Unbound on MGMT

  ci_user  = "rune"
  ssh_keys = [file("~/.ssh/id_ed25519_rune_automation.pub")]
}
```

### Ubuntu 24.04 on DMZ VLAN

Resulting FQDN: **`lxc-dmz-ubu2404-test-01.test.by-research.be`**

```hcl
module "lxc_dmz_ubu2404" {
  source = "../../modules/lxc-cloudinit"

  name               = "lxc-dmz-ubu2404-test-01"
  vmid               = 1501
  target_node        = "srv-proxmox-01"
  env                = "test"
  tags               = ["probe", "vlan2020", "os-ubuntu-24.04"]
  ostemplate_file_id = "poc-iso:vztmpl/ubuntu-24.04-cloud_amd64.tar.xz"

  network_bridge = "vmbrAPPS"
  vlan_tag       = 2020
  ipv4_address   = "10.11.2.100/24"
  ipv4_gateway   = "10.11.2.1"
  ipv6_address   = "fd11:2::100/64"
  ipv6_gateway   = "fd11:2::1"

  dns_domain  = "test.by-research.be"
  dns_servers = ["10.11.2.1", "fd11:2::1"]
  ssh_keys    = [file("~/.ssh/id_ed25519_rune_automation.pub")]
}
```

### Rocky Linux 9 on SVC VLAN

Resulting FQDN: **`lxc-svc-rocky9-test-01.test.by-research.be`**

```hcl
module "lxc_svc_rocky9" {
  source = "../../modules/lxc-cloudinit"

  name               = "lxc-svc-rocky9-test-01"
  vmid               = 1502
  target_node        = "srv-proxmox-01"
  env                = "test"
  tags               = ["probe", "vlan2030", "os-rocky-9"]
  ostemplate_file_id = "poc-iso:vztmpl/rockylinux-9-cloud_amd64.tar.xz"

  network_bridge = "vmbrAPPS"
  vlan_tag       = 2030
  ipv4_address   = "10.11.3.100/24"
  ipv4_gateway   = "10.11.3.1"
  ipv6_address   = "fd11:3::100/64"
  ipv6_gateway   = "fd11:3::1"

  dns_domain  = "test.by-research.be"
  dns_servers = ["10.11.3.1", "fd11:3::1"]
  ssh_keys    = [file("~/.ssh/id_ed25519_rune_automation.pub")]
}
```

The three examples differ in **one** field that matters: `ostemplate_file_id`. Hostname carries the OS slug so `hostname --fqdn` and DNS records reveal what's running.

## Variables — see [variables.tf](variables.tf)

Key variables:
- `name`, `vmid`, `target_node`, `env`
- `ostemplate_file_id` — must reference a cloud-init template
- `cores`, `memory`, `disk_gb`, `storage`
- `network_bridge`, `vlan_tag`, `ipv4_address`, `ipv4_gateway`, `ipv6_address`, `ipv6_gateway`
- `ci_user`, `ssh_keys`, `ci_password` (optional)
- `user_data_file_id`, `vendor_data_file_id` — optional cloud-init snippets

## Outputs

| Output | Description |
|---|---|
| `vmid` | Proxmox VMID |
| `name` | Hostname |
| `ipv4_address` / `ipv6_address` | Configured addresses |
| `tags` | Final tag list |

## Notes

- **`features.nesting = true`** is default — required for systemd 255+ on Debian 13 / Ubuntu 24+ (per `feedback_lxc_systemd255_nesting`).
- **Unprivileged by default** — keep it unless you have an explicit need.
- **`lifecycle.ignore_changes = [network_interface]`** — Proxmox auto-generates MAC addresses; ignored so subsequent applies don't churn.
- **For DHCP**: set `ipv4_address = "dhcp"` (and leave `ipv4_gateway` empty). Same for IPv6 (`ipv6_address = "dhcp"`).
- **For IPv4-only**: leave `ipv6_address` empty.

## ADRs

- `infra/0003-terraform-standard` — module layout
- `infra/0004-network-architecture` §4 — VLAN assignment, dual-stack
- `services/0007-provisioning-orchestrator` — step 3 (create_shell)

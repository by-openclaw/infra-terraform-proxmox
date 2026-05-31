# Copyright (c) 2026 BY-SYSTEMS SRL. MIT License.
# SPDX-License-Identifier: MIT
# Repo: https://github.com/by-openclaw/infra-terraform-proxmox

variable "name" {
  description = "LXC short hostname (e.g. lxc-test-mgmt-01) per naming/0001. Combined with var.dns_domain produces the FQDN written to /etc/hosts."
  type        = string
}

variable "vmid" {
  description = "Proxmox VMID — test LXC range = 1500–1999 per infra/0004 §5"
  type        = number
}

variable "target_node" {
  description = "Proxmox node name (e.g. srv-proxmox-01)"
  type        = string
}

variable "ostemplate_file_id" {
  description = "Proxmox template file_id (e.g. poc-iso:vztmpl/debian-13-cloud_amd64.tar.xz). Both cloud and default variants from images.linuxcontainers.org work."
  type        = string
}

variable "os_type" {
  description = "Proxmox container OS type — drives native distro-aware setup (writes /etc/network/interfaces, /etc/hostname, ~/.ssh/authorized_keys). Must match the template: debian|ubuntu|centos|alpine|fedora|opensuse|archlinux|gentoo|nixos|unmanaged. Use 'centos' for Rocky/Alma/RHEL-derivatives."
  type        = string

  validation {
    condition     = contains(["debian", "ubuntu", "centos", "alpine", "fedora", "opensuse", "archlinux", "gentoo", "nixos", "unmanaged"], var.os_type)
    error_message = "os_type must be one of: debian, ubuntu, centos, alpine, fedora, opensuse, archlinux, gentoo, nixos, unmanaged."
  }
}

variable "cores" {
  description = "CPU cores"
  type        = number
  default     = 1
}

variable "memory" {
  description = "RAM in MB"
  type        = number
  default     = 512
}

variable "disk_gb" {
  description = "Root filesystem size in GB"
  type        = number
  default     = 4
}

variable "storage" {
  description = "Storage pool for the rootfs (e.g. poc-data)"
  type        = string
  default     = "poc-data"
}

variable "network_bridge" {
  description = "Proxmox bridge for the LXC NIC (e.g. vmbrAPPS = SDN trunk)"
  type        = string
  default     = "vmbrAPPS"
}

variable "vlan_tag" {
  description = "802.1Q VLAN tag for the LXC NIC (0 = untagged). Test VLANs 2001–2999 per infra/0004 §4."
  type        = number
  default     = 0
}

variable "ipv4_address" {
  description = "Static IPv4 in CIDR notation (e.g. 10.11.1.100/24). Use 'dhcp' for DHCP."
  type        = string
}

variable "ipv4_gateway" {
  description = "IPv4 default gateway (the OPNsense interface IP on this VLAN). Leave empty if ipv4_address=dhcp."
  type        = string
  default     = ""
}

variable "ipv6_address" {
  description = "Static IPv6 in CIDR notation (e.g. fd11:1::100/64). Use 'dhcp' for DHCPv6. Empty string disables IPv6 on this LXC."
  type        = string
  default     = ""
}

variable "ipv6_gateway" {
  description = "IPv6 default gateway. Leave empty if ipv6_address=dhcp or empty."
  type        = string
  default     = ""
}

variable "ci_user" {
  description = "Cloud-init default user — created at first boot with sudo NOPASSWD"
  type        = string
  default     = "rune"
}

variable "ci_password" {
  description = "Cloud-init password for the default user (optional — SSH key auth preferred). Stored in Proxmox config as hash; for testing only."
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_keys" {
  description = "List of SSH public keys injected into the cloud-init user's authorized_keys"
  type        = list(string)
  default     = []
}

variable "dns_servers" {
  description = "Dual-stack DNS resolver list — pass BOTH IPv4 and IPv6 addresses of OPNsense Unbound on the VLAN. cloud-init writes one nameserver line per entry to /etc/resolv.conf. Single-stack is allowed but not recommended (loses half-stack on outage)."
  type        = list(string)
  default     = []
}

variable "dns_domain" {
  description = "DNS search domain — combined with var.name to form the FQDN (e.g. name=lxc-test-mgmt-01 + dns_domain=test.by-research.be → FQDN lxc-test-mgmt-01.test.by-research.be). Mandatory for any internal host per naming/0001 §9; default empty is only for the rare hostname-only edge case."
  type        = string
  default     = ""
}

variable "env" {
  description = "Environment tier per infra/0005 (dev/test/staging/acc/prod/drp)"
  type        = string

  validation {
    condition     = contains(["dev", "test", "staging", "acc", "prod", "drp"], var.env)
    error_message = "env must be one of: dev, test, staging, acc, prod, drp (per infra/0005)."
  }
}

variable "tags" {
  description = "Additional Proxmox tags (env-{env} is added automatically). Lowercase, no colons."
  type        = list(string)
  default     = []
}

variable "unprivileged" {
  description = "Run as unprivileged LXC (recommended). False enables privileged container."
  type        = bool
  default     = true
}

variable "features" {
  description = "LXC features. nesting=true is required for systemd 255+ on Debian 13 / Ubuntu 24+ per feedback_lxc_systemd255_nesting."
  type = object({
    nesting = bool
    fuse    = bool
    keyctl  = bool
  })
  default = {
    nesting = true # required for systemd 255+
    fuse    = false
    keyctl  = false
  }
}

variable "started" {
  description = "Start the LXC after creation"
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Start LXC automatically when Proxmox node boots"
  type        = bool
  default     = true
}

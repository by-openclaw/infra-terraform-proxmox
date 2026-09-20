variable "name" {
  description = "VM name — must follow convention: vm-{service}-{env}-{seq:02d}"
  type        = string
}

variable "target_node" {
  description = "Proxmox node name to deploy the VM on (e.g., srv-proxmox-poc-01)"
  type        = string
}

variable "clone" {
  description = "Name of the Proxmox template to clone from (e.g., debian-12-cloud)"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores to allocate to the VM"
  type        = number
  default     = 2
}

variable "cpu_type" {
  description = <<-EOT
    QEMU CPU model. Default "host" (raw host-flag passthrough) is kept for
    backwards-compat with existing 1-core VMs. On this old Xeon E5-2640 v0
    (Sandy Bridge), "host" + SMP causes the Debian-12 guest init to segfault
    ("Attempted to kill init") — see vm-mailcow-01. Use a stable named model
    ("x86-64-v2-AES") for multi-core VMs; it is also the migration-safe prod
    default. v3 is unavailable here (no AVX2 on Sandy Bridge).
  EOT
  type        = string
  default     = "host"
}

variable "memory" {
  description = "Memory in MB to allocate to the VM"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Disk size for the primary disk (e.g., '20G')"
  type        = string
  default     = "20G"
}

variable "storage" {
  description = "Proxmox storage pool name for the VM disk (e.g., poc-data)"
  type        = string
}

variable "network_bridge" {
  description = "Proxmox network bridge to attach the VM NIC to (e.g., vmbrOOB)"
  type        = string
  default     = "vmbrOOB"
}

variable "ip" {
  description = "Static IP address in CIDR notation for cloud-init (e.g., 10.6.240.10/20)"
  type        = string
}

variable "gateway" {
  description = "Default gateway IP for cloud-init network config"
  type        = string
}

variable "dns" {
  description = "DNS server IP (usually same as gateway)"
  type        = string
  default     = "10.6.224.1"
}

variable "domain" {
  description = "DNS domain for FQDN (e.g. by-systems.arpa)"
  type        = string
  default     = "by-systems.arpa"
}

variable "keyboard_layout" {
  description = "Keyboard layout for the VM console (e.g., fr-be for Belgian)"
  type        = string
  default     = "fr-be"
}

variable "ci_user" {
  description = "Cloud-init default user (created by cloud-init on first boot) — the platform's OOB/local admin identity (identity/0004); Ansible's identity baseline then adds svc-* and purges any other human account"
  type        = string
  default     = "by-research"
}

variable "ci_password" {
  description = "Password for the cloud-init default user (for Proxmox web console access)"
  type        = string
  sensitive   = true
  default     = "<REDACTED:password>"
}

variable "ssh_keys" {
  description = "List of SSH public keys to inject via cloud-init"
  type        = list(string)
  default     = []
}

variable "env" {
  description = "Environment tier for this VM (prod/dev/test/staging/acc). prod = no env suffix in hostname (ADR-0010). Env is per-VM, not per-node."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "dev", "test", "staging", "acc"], var.env)
    error_message = "env must be one of: prod, dev, test, staging, acc."
  }
}

variable "tags" {
  description = "Additional Proxmox tags. env-{var.env} is always added automatically. No colons in tag values."
  type        = list(string)
  default     = ["linux"]
}

# --- Optional extensions for dual-stack + VLAN tagging (added 2026-05-23) ---
# Defaults preserve existing single-NIC v4-only behaviour.

variable "vlan_id" {
  description = "802.1Q VLAN tag for the NIC (0 = untagged). Used when network_bridge is a trunk like vmbrAPPS."
  type        = number
  default     = 0
}

variable "vmid" {
  description = "Explicit Proxmox VMID (optional). If 0, Proxmox auto-assigns from the cluster next-id."
  type        = number
  default     = 0
}

variable "dns_servers" {
  description = "List of DNS resolvers (cloud-init writes one nameserver line each). Dual-stack — pass both IPv4 and IPv6 entries. Empty list = fall back to var.dns (single)."
  type        = list(string)
  default     = []
}

variable "ipv6_address" {
  description = "Static IPv6 in CIDR notation (e.g. fd11:1::100/64). Empty = IPv6 disabled."
  type        = string
  default     = ""
}

variable "ipv6_gateway" {
  description = "IPv6 default gateway. Required if ipv6_address is set."
  type        = string
  default     = ""
}

variable "use_vendor_data" {
  description = "When true, generate a cloud-init vendor-data snippet (locale/timezone/keyboard/sudo/packages/runcmd) and attach it to the VM. Requires SSH access to the PVE node (bpg/proxmox proxmox_virtual_environment_file uploads via SSH). Set to false when PVE node SSH is unavailable; bare-bones cloud-init (IP + ssh-key + hostname) still applies via the initialization block, and post-create Ansible can pick up the rest."
  type        = bool
  default     = true
}

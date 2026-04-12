variable "name" {
  description = "VM name — must follow convention: vm-opnsense-{seq:02d} (prod) or vm-opnsense-{env}-{seq:02d} (non-prod). See ADR-0010."
  type        = string
}

variable "vm_id" {
  description = "Proxmox VM ID — must be unique on the cluster/node"
  type        = number
}

variable "target_node" {
  description = "Proxmox node name (e.g. srv-proxmox-poc-01)"
  type        = string
}

variable "iso_storage" {
  description = "Storage pool where the OPNsense ISO lives"
  type        = string
  default     = "poc-iso"
}

variable "iso_file" {
  description = "ISO filename on the storage pool"
  type        = string
  default     = "OPNsense-25.1-dvd-amd64.iso"
}

variable "disk_size" {
  description = "Primary disk size in GiB. Minimum 8 GiB for OPNsense base install."
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size >= 8
    error_message = "OPNsense requires at least 8 GiB disk."
  }
}

variable "disk_storage" {
  description = "Proxmox storage pool for the VM disk and EFI disk (e.g. poc-data)"
  type        = string
}

variable "cores" {
  description = "Number of vCPUs. Minimum 1, but 2+ recommended for IDS/Suricata workloads."
  type        = number
  default     = 2

  validation {
    condition     = var.cores >= 1
    error_message = "cores must be at least 1."
  }
}

variable "memory" {
  description = "RAM in MiB. Minimum 3072 MiB. 4096 MiB recommended for Suricata/IDS."
  type        = number
  default     = 4096

  validation {
    condition     = var.memory >= 3072
    error_message = "OPNsense requires at least 3072 MiB RAM. 4096 MiB recommended for IDS workloads."
  }
}

variable "wan_bridge" {
  description = "Proxmox bridge for WAN NIC — vmbrWAN3 (production internet uplink, renamed 2026-04-03)"
  type        = string
  default     = "vmbrWAN3"
}

variable "lan_bridge" {
  description = "Proxmox bridge for LAN NIC — vmbrAPPS (SDN trunk uplink; VMs land on mgmt/dmz/svc VNets behind OPNsense)"
  type        = string
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
  description = "Additional Proxmox tags. env-{var.env} is always appended automatically. No colons in tag values (Proxmox rejects them)."
  type        = list(string)
  default     = ["layer0", "opnsense"]
}

variable "protection" {
  description = "Protect VM against accidental deletion via Proxmox/Terraform. Set true in production."
  type        = bool
  default     = false
}

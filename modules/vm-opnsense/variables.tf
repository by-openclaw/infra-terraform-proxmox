variable "name" {
  description = "VM name — convention: vm-opnsense-{env}-{seq:02d} for non-prod; vm-opnsense-{seq:02d} for prod (ADR-0010: prod omits env)"
  type        = string
}

variable "vm_id" {
  description = "Proxmox VM ID (e.g. 101)"
  type        = number
}

variable "target_node" {
  description = "Proxmox node name (e.g. srv-proxmox-poc-01)"
  type        = string
}

variable "iso_storage" {
  description = "Storage pool where the OPNsense ISO lives. Must be poc-iso (ADR-0015: poc-iso is the only valid ISO storage target in PoC)"
  type        = string
  default     = "poc-iso"
}

variable "iso_file" {
  description = "ISO filename on the storage (e.g. OPNsense-25.1-dvd-amd64.iso)"
  type        = string
  default     = "OPNsense-25.1-dvd-amd64.iso"
}

variable "disk_size" {
  description = "Primary disk size in GB"
  type        = number
  default     = 20
}

variable "disk_storage" {
  description = "Proxmox storage pool for the VM disk (e.g. poc-data)"
  type        = string
}

variable "cores" {
  description = "Number of vCPUs"
  type        = number
  default     = 2
}

variable "memory" {
  description = "RAM in MB"
  type        = number
  default     = 2048
}

variable "wan_bridge" {
  description = "vtnet1 — bootstrap/temp WAN via OOB uplink (default vmbrOOB = bond0 -> 10.6.224.0/20)"
  type        = string
  default     = "vmbrOOB"
}

variable "lan_bridge" {
  description = "vtnet1 — LAN trunk (vmbrAPPS = SDN parent for VLANs 1010-1400)"
  type        = string
}

variable "wan1_bridge" {
  description = "vtnet2 — WAN1 / Proximus PPPoE (e.g. vmbrWAN1). Empty to skip."
  type        = string
  default     = ""
}

variable "wan2_bridge" {
  description = "vtnet3 — WAN2 / Telenet (e.g. vmbrWAN2). Empty to skip."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Proxmox tags"
  type        = list(string)
  default     = ["layer0", "env-poc", "opnsense"] # Proxmox tags: no colons, use hyphens
}

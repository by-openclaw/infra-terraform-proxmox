variable "name" {
  description = "VM name — must follow convention: vm-opnsense-{env}-{seq:02d}"
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
  description = "Storage pool where the OPNsense ISO lives (e.g. local)"
  type        = string
  default     = "local"
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
  description = "Proxmox bridge for WAN NIC (internet access) — use vmbrWAN3 (renamed from vmbrOOB 2026-04-03)"
  type        = string
  default     = "vmbrWAN3"
}

variable "lan_bridge" {
  description = "Proxmox bridge for LAN NIC — use vmbrAPPS as the SDN trunk uplink; VMs land on VNets mgmt/dmz/svc behind OPNsense"
  type        = string
}

variable "tags" {
  description = "Proxmox tags"
  type        = list(string)
  default     = ["layer:0", "env:poc", "tool:opnsense"]
}

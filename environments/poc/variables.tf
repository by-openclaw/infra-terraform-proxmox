variable "proxmox_endpoint" {
  description = "Proxmox API endpoint (e.g. https://10.6.224.105:8006)"
  type        = string
}

variable "proxmox_username" {
  description = "Proxmox user (e.g. root@pam)"
  type        = string
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

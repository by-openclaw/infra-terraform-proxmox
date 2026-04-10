variable "proxmox_endpoint" {
  description = "Proxmox API endpoint (e.g. https://10.6.224.105:8006)"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in format 'user@realm!tokenname=uuid'"
  type        = string
  sensitive   = true
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = true # allow self-signed cert on PoC

  ssh {
    agent    = false
    username = "root"
    password = var.proxmox_password
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token  # format: "user@realm!tokenname=uuid"
  insecure  = true                   # allow self-signed cert on PoC

  # SSH required by bpg/proxmox for some operations (disk upload, etc.)
  ssh {
    agent    = false
    username = "root"
    password = var.proxmox_ssh_password
  }
}

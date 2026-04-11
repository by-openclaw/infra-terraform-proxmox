provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true

  ssh {
    agent    = true
    username = "root"

    node {
      name    = "srv-proxmox-01"
      address = "10.6.224.105"
      port    = 22222
    }
  }
}

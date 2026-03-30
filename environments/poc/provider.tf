provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token # svc-terraform@pve!ci
  insecure  = true

  # SSH used by bpg/proxmox for file uploads (snippets)
  # Uses ssh-agent — load rune key before running terraform
  ssh {
    agent    = true
    username = "root"

    node {
      name    = "srv-proxmox-poc-01"
      address = "10.6.224.105"
      port    = 22222
    }
  }
}

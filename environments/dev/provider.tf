provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token # svc-rune@pve!terraform on br-pmox-03 (Vault dev/proxmox/tokens/svc-rune-terraform)
  insecure  = true

  # SSH used by bpg/proxmox for snippet uploads (cloudbase user-data).
  # Uses ssh-agent — load rune key before running terraform.
  ssh {
    agent    = true
    username = "root"

    node {
      name    = "br-pmox-03"
      address = "10.6.239.177"
      port    = 22222
    }
  }
}

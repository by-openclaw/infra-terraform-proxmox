provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token  # svc-terraform@pve!ci
  insecure  = true

  ssh {
    agent       = false
    username    = "root"
    private_key = file("~/.ssh/id_ed25519_rune")
    password    = var.proxmox_ssh_password  # passphrase for key
  }
}

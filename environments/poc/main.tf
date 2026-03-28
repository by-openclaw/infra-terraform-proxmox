################################################################################
# BY-SYSTEMS — Proxmox PoC Environment
# Node: srv-proxmox-poc-01 (10.6.224.105)
# Provider: bpg/proxmox ~> 0.66 (PVE 9.x compatible)
# State: local backend (migrate to GitLab managed state when GitLab CE deployed)
################################################################################

module "netbox" {
  source = "../../modules/vm-linux"

  name        = "vm-netbox-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 4096
  disk_size = "20G"
  storage   = "poc-data"

  network_bridge = "vmbrMGMT"
  ip             = "10.6.240.10/20"
  gateway        = "10.6.255.254"

  ci_user = "debian"
  ssh_keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGhb4mI3rUIOrwn5vCsUfMk0Si68V9VI0fGFeRHWnH4F yboujraf@by-systems.be"
  ]
}

output "netbox_vm_id" {
  value = module.netbox.vm_id
}

output "netbox_ip" {
  value = module.netbox.ip_address
}

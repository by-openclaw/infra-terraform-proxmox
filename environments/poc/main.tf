################################################################################
# BY-SYSTEMS — Proxmox PoC Environment
# Node: srv-proxmox-poc-01
# State: local (migrate to S3/GitLab when GitLab CE is deployed)
################################################################################

module "netbox" {
  source = "../../modules/vm-linux"

  # VM identity
  name        = "vm-netbox-poc-01"
  target_node = "srv-proxmox-poc-01"

  # Template — NOTE: requires debian-12-cloud template on poc-iso storage
  # Template creation is blocked until Debian 12 cloud image is prepared
  # See: GitHub issue #44
  clone = "debian-12-cloud"

  # Hardware sizing for NetBox
  cores     = 2
  memory    = 4096
  disk_size = "20G"
  storage   = "poc-data"

  # Network — MGMT VLAN
  network_bridge = "vmbrMGMT"
  ip             = "10.6.240.10/20"
  gateway        = "10.6.255.254"

  # SSH access
  ssh_keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGhb4mI3rUIOrwn5vCsUfMk0Si68V9VI0fGFeRHWnH4F yboujraf@by-systems.be"
  ]
}

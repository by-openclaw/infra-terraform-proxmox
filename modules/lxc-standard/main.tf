resource "proxmox_lxc" "this" {
  # LXC identity
  hostname    = var.name
  target_node = var.target_node
  description = "Managed by Terraform — BY-SYSTEMS infra-terraform-proxmox"
  tags        = join(",", concat(var.tags, ["env-${var.env}"]))

  # Template
  ostemplate = var.ostemplate

  # Hardware
  cores  = var.cores
  memory = var.memory
  swap   = var.swap

  # Root filesystem
  rootfs {
    storage = var.storage
    size    = var.disk
  }

  # Network interface
  network {
    name   = "eth0"
    bridge = var.network_bridge
    ip     = var.ip
    gw     = var.gateway
  }

  # Security — unprivileged by default
  unprivileged = var.unprivileged

  # Start at boot — always true
  onboot = var.onboot
  start  = true

  # SSH public key injection
  ssh_public_keys = join("\n", var.ssh_keys)

  lifecycle {
    prevent_destroy = false
    # `startup` (start order + delay) is owned by ansible-platform roles/pve_host (pve_host_boot_order):
    # the cold-start sequence follows the service dependencies of the catalog, not the guest definition.
    ignore_changes  = [network, rootfs, startup]
  }
}

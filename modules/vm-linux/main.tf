resource "proxmox_vm_qemu" "this" {
  # VM identity
  name        = var.name
  desc        = "Managed by Terraform — BY-SYSTEMS infra-terraform-proxmox"
  target_node = var.target_node

  # Clone from template
  clone = var.clone

  # Hardware
  cores   = var.cores
  sockets = 1
  memory  = var.memory
  cpu     = "host"

  # Disk — always VirtIO
  disk {
    slot    = "virtio0"
    size    = var.disk_size
    storage = var.storage
    type    = "virtio"
    discard = "on"
    iothread = 1
  }

  # Cloud-init drive — always attached
  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = var.storage
  }

  # Network — always VirtIO
  network {
    model  = "virtio"
    bridge = var.network_bridge
  }

  # QEMU guest agent — always enabled
  agent = 1

  # Cloud-init configuration
  os_type    = "cloud-init"
  ipconfig0  = "ip=${var.ip},gw=${var.gateway}"
  ciuser     = var.ci_user
  sshkeys    = join("\n", var.ssh_keys)

  # Boot settings
  boot    = "order=virtio0"
  onboot  = true

  # VGA for noVNC console
  vga {
    type   = "std"
    memory = 16
  }

  lifecycle {
    # Prevent accidental destruction of VMs
    prevent_destroy = false
    ignore_changes  = [network, disk]
  }
}

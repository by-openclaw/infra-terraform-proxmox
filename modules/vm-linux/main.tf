# Fetch template VM ID by name
data "proxmox_virtual_environment_vms" "template" {
  node_name = var.target_node
  filter {
    name   = "name"
    values = [var.clone]
  }
}

# Cloud-init vendor-data — grants sudo to by-systems
# Keys and user are set via native Proxmox CI fields (visible in UI)
resource "proxmox_virtual_environment_file" "vendor_data" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node

  source_raw {
    file_name = "${var.name}-vendor-data.yaml"
    data      = <<-EOT
      #cloud-config
      # BY-SYSTEMS VM baseline — grant sudo to admin user
      runcmd:
        - echo '${var.ci_user} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${var.ci_user}
        - chmod 440 /etc/sudoers.d/${var.ci_user}
        - systemctl enable qemu-guest-agent --now || true
    EOT
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.target_node

  # Clone from template
  clone {
    vm_id = data.proxmox_virtual_environment_vms.template.vms[0].vm_id
    full  = true
  }

  # CPU
  cpu {
    cores = var.cores
    type  = "host"
  }

  # Memory
  memory {
    dedicated = var.memory
  }

  # SCSI controller — virtio-scsi-single required for iothread per-disk
  scsi_hardware = "virtio-scsi-single"

  # Boot disk
  disk {
    datastore_id = var.storage
    interface    = "scsi0"
    size         = tonumber(replace(var.disk_size, "G", ""))
    discard      = "on"
    iothread     = true
    file_format  = "qcow2"
  }

  # Network
  network_device {
    model  = "virtio"
    bridge = var.network_bridge
  }

  # VGA — std display, no serial
  vga {
    type = "std"
  }

  # Keyboard layout (noVNC console)
  keyboard_layout = var.keyboard_layout

  # QEMU guest agent
  agent {
    enabled = true
    timeout = "15m"
  }

  # Cloud-init — native Proxmox fields (visible in UI)
  initialization {
    datastore_id       = var.storage
    vendor_data_file_id = proxmox_virtual_environment_file.vendor_data.id

    dns {
      servers = [var.dns]
    }

    ip_config {
      ipv4 {
        address = var.ip
        gateway = var.gateway
      }
    }

    # Native CI user — shows in Proxmox UI, keys visible in Cloud-Init tab
    user_account {
      username = var.ci_user
      keys     = var.ssh_keys
    }
  }

  on_boot = true

  lifecycle {
    ignore_changes = [clone]
  }
}

# Fetch template VM ID by name
data "proxmox_virtual_environment_vms" "template" {
  node_name = var.target_node
  filter {
    name   = "name"
    values = [var.clone]
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

  # Boot disk (resized after clone)
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

  # QEMU guest agent
  agent {
    enabled = true
  }

  # Cloud-init
  initialization {
    datastore_id = var.storage  # store cloud-init drive on same storage as VM disk
    ip_config {
      ipv4 {
        address = var.ip
        gateway = var.gateway
      }
    }
    user_account {
      username = var.ci_user
      keys     = var.ssh_keys
    }
  }

  # Serial console
  serial_device {}

  # VGA
  vga {
    type = "serial0"
  }

  on_boot = true

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [clone]
  }
}

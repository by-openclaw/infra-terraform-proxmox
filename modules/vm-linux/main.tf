# Fetch template VM ID by name
data "proxmox_virtual_environment_vms" "template" {
  node_name = var.target_node
  filter {
    name   = "name"
    values = [var.clone]
  }
}

# Cloud-init user-data file — uploaded to Proxmox snippets storage
# Handles: by-systems user, sudo, SSH keys, disable default ci user login
resource "proxmox_virtual_environment_file" "user_data" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node

  source_raw {
    file_name = "${var.name}-user-data.yaml"
    data      = <<-EOT
      #cloud-config
      # BY-SYSTEMS VM baseline — standard OOB admin user
      users:
        - name: by-systems
          gecos: BY-SYSTEMS Admin
          groups: [sudo]
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
          ssh_authorized_keys:
${join("\n", formatlist("          - %s", var.ssh_keys))}
      # Disable password auth
      ssh_pwauth: false
      # Install essential packages
      packages:
        - qemu-guest-agent
        - sudo
        - curl
      # Start guest agent
      runcmd:
        - systemctl enable qemu-guest-agent
        - systemctl start qemu-guest-agent
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

  # VGA — std, no serial override
  vga {
    type = "std"
  }

  # Keyboard layout
  keyboard_layout = var.keyboard_layout

  # QEMU guest agent
  agent {
    enabled = true
    timeout = "15m"
  }

  # Cloud-init
  initialization {
    datastore_id      = var.storage
    user_data_file_id = proxmox_virtual_environment_file.user_data.id

    dns {
      servers = [var.dns]
    }

    ip_config {
      ipv4 {
        address = var.ip
        gateway = var.gateway
      }
    }
  }

  on_boot = true

  lifecycle {
    ignore_changes = [clone]
  }
}

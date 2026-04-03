# Fetch template VM ID by name
data "proxmox_virtual_environment_vms" "template" {
  node_name = var.target_node
  filter {
    name   = "name"
    values = [var.clone]
  }
}

# Vendor-data snippet — locale, timezone, keyboard, sudo, packages
# User + SSH keys handled by native Proxmox CI (visible in UI)
resource "proxmox_virtual_environment_file" "vendor_data" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node

  source_raw {
    file_name = "${var.name}-vendor-data.yaml"
    data      = <<-EOT
      #cloud-config
      # BY-SYSTEMS VM baseline
      hostname: ${var.name}
      fqdn: ${var.name}.${var.domain}
      manage_etc_hosts: true

      timezone: Europe/Brussels

      chpasswd:
        list: |
          ${var.ci_user}:${var.ci_password}
        expire: false

      write_files:
        - path: /etc/sudoers.d/${var.ci_user}
          content: "${var.ci_user} ALL=(ALL) NOPASSWD:ALL\n"
          permissions: "0440"

      package_update: true
      package_upgrade: true

      packages:
        - curl
        - wget
        - git
        - htop
        - unattended-upgrades
        - qemu-guest-agent
        - net-tools
        - sudo
        - locales
        - console-setup
        - keyboard-configuration

      runcmd:
        - systemctl enable qemu-guest-agent --now
        - echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        - sysctl -p
        - sed -i 's/^# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
        - locale-gen en_US.UTF-8
        - update-locale LANG=en_US.UTF-8
        - printf 'XKBMODEL="pc105"\nXKBLAYOUT="be"\nXKBVARIANT=""\nXKBOPTIONS=""\nBACKSPACE="guess"\n' > /etc/default/keyboard

      final_message: |
        Cloud-init complete on ${var.name}.
        User: ${var.ci_user} | Locale: en_US.UTF-8 | TZ: Europe/Brussels | Keyboard: be
    EOT
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.target_node
  tags      = concat(var.tags, ["env-${var.env}"])

  clone {
    vm_id = data.proxmox_virtual_environment_vms.template.vms[0].vm_id
    full  = true
  }

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  scsi_hardware = "virtio-scsi-single"

  disk {
    datastore_id = var.storage
    interface    = "scsi0"
    size         = tonumber(replace(var.disk_size, "G", ""))
    discard      = "on"
    iothread     = true
    file_format  = "qcow2"
  }

  network_device {
    model  = "virtio"
    bridge = var.network_bridge
  }

  vga {
    type   = "std"
    memory = 16
  }


  keyboard_layout = var.keyboard_layout

  agent {
    enabled = true
    timeout = "5m"
  }

  initialization {
    datastore_id        = var.storage
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

    # Native CI — user + keys visible in Proxmox Cloud-Init tab
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

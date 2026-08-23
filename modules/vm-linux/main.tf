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
#
# NOTE: This resource uses the BPG proxmox_virtual_environment_file resource,
# which uploads snippets via SSH to the PVE node (PVE REST API does not allow
# snippets uploads). When SSH to the PVE node is unavailable, set
# var.use_vendor_data = false to skip this resource — the bare-bones cloud-init
# inside the initialization block (IP, ssh-key, hostname) still applies.
resource "proxmox_virtual_environment_file" "vendor_data" {
  count = var.use_vendor_data ? 1 : 0

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
  vm_id     = var.vmid > 0 ? var.vmid : null
  tags      = concat(var.tags, ["env-${var.env}"])

  clone {
    vm_id = data.proxmox_virtual_environment_vms.template.vms[0].vm_id
    full  = true
  }

  cpu {
    cores = var.cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory
  }

  scsi_hardware = "virtio-scsi-single"

  # Boot from the OS disk. bpg/proxmox >= 0.100 no longer defaults the boot order,
  # so without this a freshly-cloned VM comes up with an EMPTY boot order and hangs
  # at BIOS (no OS → no qemu-agent, no sshd). VMs created on older providers kept
  # the implicit order=scsi0. Pin it explicitly here for every VM.
  boot_order = ["scsi0"]

  disk {
    datastore_id = var.storage
    interface    = "scsi0"
    size         = tonumber(replace(var.disk_size, "G", ""))
    discard      = "on"
    iothread     = true
    file_format  = "raw" # poc-data is ZFS — only raw is supported (qcow2 caused drift vs live; #27)
  }

  network_device {
    model   = "virtio"
    bridge  = var.network_bridge
    vlan_id = var.vlan_id > 0 ? var.vlan_id : null
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
    vendor_data_file_id = var.use_vendor_data ? proxmox_virtual_environment_file.vendor_data[0].id : null

    dns {
      domain  = var.domain
      servers = length(var.dns_servers) > 0 ? var.dns_servers : [var.dns]
    }

    ip_config {
      ipv4 {
        address = var.ip
        gateway = var.gateway
      }
      dynamic "ipv6" {
        for_each = var.ipv6_address != "" ? [1] : []
        content {
          address = var.ipv6_address
          gateway = var.ipv6_gateway
        }
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
    # clone: template ref drifts post-create. agent: provider fills agent.type
    # (virtio) on the live VM → benign in-place churn; ignore it (#27).
    ignore_changes = [clone, agent]
  }
}

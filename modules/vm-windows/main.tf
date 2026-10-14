# Windows Server VM cloned from an ansible-platform windows_template build
# (roles/windows_template: sysprep-generalised, qemu-ga + cloudbase-init inside,
# cloud-init drive ide2 citype=configdrive2, balloon=0, boot order=scsi0).
#
# cloudbase-init consumes the configdrive on first boot: hostname (= var.name),
# static IP/DNS, Administrator SSH keys. Windows sshd authenticates members of
# the Administrators group against ProgramData\ssh\administrators_authorized_keys,
# NOT the profile's authorized_keys — the first-boot #ps1 user-data below fills it.

# Fetch template VM ID by name
data "proxmox_virtual_environment_vms" "template" {
  node_name = var.target_node
  filter {
    name   = "name"
    values = [var.clone]
  }
}

# First-boot PowerShell (cloudbase-init userdata plugin): the Administrator key
# lands where Windows sshd actually looks for it. Uploaded as a snippet over SSH
# (the PVE REST API does not accept snippet uploads), like vm-linux vendor-data.
resource "proxmox_virtual_environment_file" "admin_key_userdata" {
  count = var.use_admin_key_userdata ? 1 : 0

  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node

  source_raw {
    file_name = "${var.name}-user-data.ps1"
    # Also the hostname: Proxmox's configdrive2 meta_data.json carries NO hostname key
    # (verified 2026-10-14: uuid, public_keys, network_config only), so cloudbase's
    # SetHostNamePlugin silently does nothing here. Exit 1003 is cloudbase's "reboot,
    # do not re-run" convention — the rename lands within the first boot.
    data = <<-EOT
      #ps1
      $keys = @'
      ${join("\n", var.ssh_keys)}
      '@
      $p = Join-Path $env:ProgramData 'ssh\administrators_authorized_keys'
      Set-Content -Path $p -Value $keys -Encoding ascii
      icacls.exe $p /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null
      if ($env:COMPUTERNAME -ne '${var.name}') {
        Rename-Computer -NewName '${var.name}' -Force
        exit 1003
      }
    EOT
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.target_node
  vm_id     = var.vmid > 0 ? var.vmid : null
  tags      = concat(var.tags, ["env-${var.env}", "windows"])

  clone {
    vm_id = data.proxmox_virtual_environment_vms.template.vms[0].vm_id
    full  = true
  }

  # The clone inherits q35/OVMF/EFI disk/ostype from the template; declare what the
  # provider would otherwise "default away" on an in-place change.
  machine = "q35"
  bios    = "ovmf"

  operating_system {
    type = "win11" # PVE ostype for Server 2025
  }

  cpu {
    cores = var.cores
    type  = var.cpu_type # cpu=host panics multi-core VMs on this hardware
    numa  = true
    # NO affinity here: PVE accepts the affinity option from root@pam ONLY ("only root
    # can set 'affinity' config", HTTP 500 for any API token). The vCPU pinning that
    # completes the NUMA bind below is owned by ansible-platform roles/pve_host
    # (pve_host_guest_affinity, qm set --affinity as root on the node).
  }

  # Guest NUMA topology bound to one host node: vCPUs 0..N-1 and all RAM on it.
  dynamic "numa" {
    for_each = var.numa_hostnode != "" ? [1] : []
    content {
      device    = "numa0"
      cpus      = "0-${var.cores - 1}"
      memory    = var.memory
      hostnodes = var.numa_hostnode
      policy    = "bind"
    }
  }

  # floating == dedicated keeps the balloon DEVICE — the virtio balloon driver then
  # reports guest memory usage, so the PVE UI shows a real % instead of the flat
  # allocation — while deflation stays impossible (min == max): the reservation and
  # the NUMA bind remain absolute ("no freeze"). (Owner 2026-10-14: "32GB permanently,
  # can't see the % load".)
  memory {
    dedicated = var.memory
    floating  = var.memory
  }

  scsi_hardware = "virtio-scsi-single"
  boot_order    = ["scsi0"]

  disk {
    datastore_id = var.storage
    interface    = "scsi0"
    size         = tonumber(replace(var.disk_size, "G", ""))
    discard      = "on"
    iothread     = true
    file_format  = "raw"
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

  agent {
    enabled = true
    # First boot = sysprep specialize + OOBE + cloudbase-init before qemu-ga answers.
    timeout = var.agent_timeout
  }

  initialization {
    datastore_id = var.storage
    interface    = "ide2"
    type         = "configdrive2" # what cloudbase-init's ConfigDriveService reads

    user_data_file_id = var.use_admin_key_userdata ? proxmox_virtual_environment_file.admin_key_userdata[0].id : null

    dns {
      domain  = var.domain
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = var.ip
        gateway = var.gateway
      }
    }

    # cloudbase-init: SetUserSSHPublicKeys (profile) — administrators_authorized_keys
    # comes from the user-data above. No password here: Ansible sets Administrator's
    # password from Vault once it is in (key auth), never Terraform.
    user_account {
      username = "Administrator"
      keys     = var.ssh_keys
    }
  }

  on_boot = true

  lifecycle {
    # clone: template ref drifts post-create. agent: provider fills agent.type on the
    # live VM. startup is owned by ansible-platform roles/pve_host (pve_host_boot_order).
    ignore_changes = [clone, agent, startup]
  }
}

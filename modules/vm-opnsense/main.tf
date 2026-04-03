# OPNsense VM module
#
# OPNsense is a FreeBSD-based firewall appliance — NOT cloud-init based.
# It installs from ISO. Initial install requires ~5 min console interaction.
#
# Network layout:
#   vtnet0 (WAN) → vmbrWAN3
#   vtnet1 (LAN) → SDN VNet bridge
#
# After first boot and install:
#   - Access OPNsense console via Proxmox noVNC
#   - Complete install wizard (assign interfaces, set LAN IP)
#   - Enable SSH + OPNsense API for Ansible automation
#   - Configure WireGuard for Rune VM access to 10.1.x.x

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  vm_id     = var.vm_id
  node_name = var.target_node

  tags = concat(var.tags, ["env-${var.env}"])

  # OPNsense requires UEFI/BIOS + VirtIO SCSI
  bios          = "seabios"
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"  # required for iothread=true (virtio-scsi-pci ignores iothread)
  tablet_device = false                 # not needed for firewall appliance

  on_boot = true
  started = true

  cpu {
    cores   = var.cores
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = var.memory
  }

  # Boot disk — OPNsense installs here from ISO
  disk {
    datastore_id = var.disk_storage
    interface    = "scsi0"
    size         = var.disk_size
    file_format  = "qcow2"
    iothread     = true
    discard      = "on"
    cache        = "none"
  }

  # ISO attached for installation — detach after first install
  cdrom {
    file_id   = "${var.iso_storage}:iso/${var.iso_file}"
    interface = "ide0"
  }

  boot_order = ["scsi0", "ide0"]

  # WAN NIC
  network_device {
    bridge   = var.wan_bridge
    model    = "virtio"
    firewall = false
  }

  # LAN NIC
  network_device {
    bridge   = var.lan_bridge
    model    = "virtio"
    firewall = false
  }

  vga {
    type   = "std"
    memory = 16
  }

  # No cloud-init — OPNsense uses its own config system
  # Post-install config via OPNsense API + Ansible (ansible-platform)
}

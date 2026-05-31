# OPNsense VM module
#
# OPNsense is a FreeBSD-based firewall appliance — NOT cloud-init based.
# It installs from ISO. Initial install requires ~5 min console interaction.
#
# Network layout:
#   vtnet0 (LAN trunk) → vmbrAPPS (SDN prod) or test SDN bridge
#   vtnet1 (WAN bootstrap) → vmbrOOB (bond0 → 10.6.224.0/20 OOB)
#   vtnet2 (WAN1 future)   → vmbrWAN1 (Proximus PPPoE)
#   vtnet3 (WAN2 future)   → vmbrWAN2 (Telenet)
# For unattended provisioning, see modules/vm-opnsense/seed/ (nano + termproxy flow).
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

  tags = var.tags

  # OPNsense requires UEFI/BIOS + VirtIO SCSI
  bios          = "seabios"
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single" # required for iothread=true on the disk
  tablet_device = false

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
    file_format  = "raw" # poc-data is ZFS — only raw is supported
    iothread     = true
    discard      = "on"
    cache        = "none"
    ssd          = true
  }

  # ISO attached for installation — detach after first install
  cdrom {
    file_id   = "${var.iso_storage}:iso/${var.iso_file}"
    interface = "ide2" # Proxmox default CDROM slot
  }

  boot_order = ["scsi0", "ide2"]

  # vtnet0 — LAN trunk (vmbrAPPS carries all SDN VLANs 1010-1400)
  # OPNsense creates VLAN sub-interfaces (vtnet0.1010, vtnet0.1020, ...) internally.
  network_device {
    bridge   = var.lan_bridge
    model    = "virtio"
    firewall = false
  }

  # vtnet1 — WAN (bootstrap DHCP on OOB; later: Proximus or Telenet)
  network_device {
    bridge   = var.wan_bridge
    model    = "virtio"
    firewall = false
  }

  # vtnet2 — WAN1 / Proximus PPPoE (vmbrWAN1 trunks VLAN 10)
  dynamic "network_device" {
    for_each = var.wan1_bridge != "" ? [1] : []
    content {
      bridge   = var.wan1_bridge
      model    = "virtio"
      firewall = false
    }
  }

  # vtnet3 — WAN2 / Telenet (vmbrWAN2 trunks VLAN 999)
  dynamic "network_device" {
    for_each = var.wan2_bridge != "" ? [1] : []
    content {
      bridge   = var.wan2_bridge
      model    = "virtio"
      firewall = false
    }
  }

  vga {
    type   = "std"
    memory = 16
  }

  # No cloud-init — OPNsense uses its own config system
  # Post-install config via OPNsense API + Ansible (ansible-platform)
}

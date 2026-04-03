# OPNsense VM module
#
# OPNsense is a FreeBSD-based firewall appliance — NOT cloud-init based.
# It installs from ISO. Initial install requires ~5 min console interaction.
#
# Network layout:
#   vtnet0 (WAN) → vmbrWAN3 → gets IP on 10.6.224.0/20 (renamed from vmbrOOB 2026-04-03)
#   vtnet1 (LAN) → SDN VNet bridge → 10.1.0.1/20 (gateway for all PoC VLANs)
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
  bios            = "seabios"
  scsi_hardware   = "virtio-scsi-single"
  tablet_device   = false  # not needed for firewall appliance

  on_boot  = true
  started  = true

  cpu {
    cores  = var.cores
    sockets = 1
    type   = "host"
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

  # WAN NIC — connects to vmbrWAN3 (10.6.224.0/20) — renamed from vmbrOOB 2026-04-03
  # OPNsense WAN gets 10.6.225.1/20 static (set in OPNsense UI post-install)
  network_device {
    bridge   = var.wan_bridge
    model    = "virtio"
    firewall = false
  }

  # LAN NIC — connects to SDN VNet bridge (vmbrPOC removed 2026-04-03)
  # OPNsense LAN = 10.1.0.1/20 — gateway for all PoC VLANs (310/320/330)
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

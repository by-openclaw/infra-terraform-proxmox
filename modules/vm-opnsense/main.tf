# OPNsense VM module
#
# OPNsense is a FreeBSD-based firewall appliance — NOT cloud-init based.
# It installs from ISO. Initial install requires ~5 min console interaction.
#
# Network layout:
#   vtnet0 (WAN) → vmbrWAN3
#   vtnet1 (LAN) → SDN VNet bridge (vmbrAPPS → mgmt/dmz/svc VNets)
#
# After first boot and install:
#   - Access OPNsense console via Proxmox noVNC
#   - Complete install wizard (assign interfaces, set LAN IP)
#   - Install os-qemu-guest-agent plugin (System → Firmware → Plugins)
#   - Enable SSH + OPNsense API for Ansible automation
#   - Configure WireGuard for Rune VM access to 10.1.x.x
#   - Detach ISO from Proxmox after successful install
#
# QEMU guest agent note:
#   agent.enabled = false at provision time — OPNsense does NOT install
#   qemu-guest-agent by default. Plugin must be installed post-install:
#     System → Firmware → Plugins → os-qemu-guest-agent
#   After install, flip agent { enabled = true } in Terraform and re-apply.
#   Without the agent: no IP reporting in Proxmox UI, no clean snapshots,
#   no qm guest exec support.

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  vm_id     = var.vm_id
  node_name = var.target_node

  tags = concat(var.tags, ["env-${var.env}"])

  # OVMF (UEFI) — valid modern choice with q35.
  # NOTE: switching an existing installed VM from seabios to ovmf is destructive.
  # Recreate the VM if firmware type must change.
  bios          = "ovmf"
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single" # required for iothread=true
  tablet_device = false                # not needed for firewall appliance

  on_boot    = true
  started    = true
  protection = var.protection

  # QEMU guest agent disabled at install time.
  # OPNsense does not ship with qemu-guest-agent enabled by default.
  # Install os-qemu-guest-agent plugin post-install, then set enabled = true.
  agent {
    enabled = false
  }

  cpu {
    cores      = var.cores
    sockets    = 1
    type       = "host"
    hotplugged = 0
    # AES-NI: with type="host" this is already exposed if the host supports it.
    # Kept explicit per BY-SYSTEMS ADR — always guarantee AES for crypto workloads.
    # For HA/cluster: switch to type="x86-64-v2-AES" (migratable, AES guaranteed).
    flags = ["+aes"]
  }

  memory {
    dedicated = var.memory
    # Ballooning disabled — critical for firewall stability.
    # Proxmox reclaiming RAM dynamically causes state table instability and
    # connection drops on OPNsense/pfSense.
    floating = 0
  }

  # Boot disk — OPNsense installs here from ISO
  disk {
    datastore_id = var.disk_storage
    interface    = "scsi0"
    size         = var.disk_size
    file_format  = "raw"  # ZFS requires raw (qcow2 not supported on ZFS pools)
    iothread     = true
    discard      = "on"
    cache        = "none"
    ssd          = true   # SSD emulation hint — enables TRIM/discard path in guest
  }

  # EFI disk — required with bios = "ovmf"
  # Stores UEFI persistent variables. Secure Boot disabled (not supported by OPNsense).
  efi_disk {
    datastore_id      = var.disk_storage
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = false
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
    queues   = var.cores  # multiqueue VirtIO — one queue per core, improves throughput
  }

  # LAN NIC
  network_device {
    bridge   = var.lan_bridge
    model    = "virtio"
    firewall = false
    queues   = var.cores
  }

  vga {
    type   = "std"
    memory = 16
  }

  # Serial console — useful for out-of-band debug if noVNC is unavailable
  # Access via: qm terminal <vmid> --iface serial0
  serial_device {}

  # No cloud-init — OPNsense uses its own config system
  # Post-install config via OPNsense API + Ansible (ansible-platform)
}

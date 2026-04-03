# OPNsense VM module
#
# FreeBSD-based firewall appliance. NOT cloud-init based. Installs from ISO.
# No in-band hook is available during provisioning — all post-install config
# is handled by Ansible (ansible-platform/roles/opnsense) after first boot.
#
# Network layout:
#   vtnet0 (WAN) → vmbrWAN3
#   vtnet1 (LAN) → vmbrAPPS (SDN trunk → mgmt/dmz/svc VNets)
#
# Provisioning sequence (mandatory):
#   1. terraform apply  — creates VM, attaches ISO, starts VM
#   2. console install  — Proxmox noVNC → complete OPNsense installer
#   3. bootstrap        — set LAN IP, enable SSH + API
#   4. ansible-platform — roles/opnsense bootstrap playbook:
#                         installs os-qemu-guest-agent, configures interfaces,
#                         firewall rules, DNS, WireGuard
#   5. terraform apply  — flip agent { enabled = true } after Ansible confirms
#                         qemu-guest-agent is running
#   6. detach ISO       — update cdrom block or remove from Proxmox UI
#
# QEMU guest agent (see ADR-0003):
#   agent { enabled = false } at provision time — os-qemu-guest-agent is NOT
#   installed by default in OPNsense. Ansible installs it in step 4.
#   Without agent: no IP in Proxmox UI, no consistent snapshots, no qm exec.
#
# CPU type (see ADR-0003):
#   type = "host" — single node only. Switch to "x86-64-v2-AES" when cluster
#   is added. That change requires a maintenance window (FW reboot = downtime).
#
# RAM / Disk minimums enforced in variables.tf:
#   memory >= 3072 MiB   (4096 MiB default — covers base + Suricata + state)
#   disk_size >= 8 GiB   (20 GiB default)

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

  # QEMU agent disabled — os-qemu-guest-agent is not installed by default.
  # Ansible bootstrap installs it (step 4 of provisioning sequence above).
  # After Ansible confirms agent is running: set enabled = true, re-apply.
  agent {
    enabled = false
  }

  cpu {
    cores      = var.cores
    sockets    = 1
    type       = "host"        # single node; → "x86-64-v2-AES" when cluster (ADR-0003)
    hotplugged = 0
    flags      = ["+aes"]     # AES-NI: mandatory for WireGuard/IPsec/TLS (ADR-0003)
                               # with type=host this is already exposed; flag is an
                               # explicit guard — Proxmox errors if host lacks AES-NI
  }

  memory {
    dedicated = var.memory  # min 3072 MiB enforced in variables.tf
    floating  = 0           # ballooning disabled — Proxmox reclaiming RAM causes
                            # state table instability and connection drops (ADR-0003)
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

  # Out-of-band console — useful if noVNC is unavailable
  # Access: qm terminal <vmid> --iface serial0
  serial_device {}

  # No cloud-init — OPNsense uses its own config system
  # Post-install config via OPNsense API + Ansible (ansible-platform)
}

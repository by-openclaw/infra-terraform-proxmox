################################################################################
# BY-SYSTEMS — Test Environment
# Node: srv-proxmox-poc-01
# Purpose: lib-opnsense integration testing
#
# SDN zone: test (VLANs 1310/1320/1330/1340 on vmbrAPPS)
# IP supernet: 10.11.0.0/20 (v4) + fd11::/32 (v6 ULA)
#   MGMT  1310  10.11.1.0/24  fd11:1::/64  gw 10.11.1.1
#   DMZ   1320  10.11.2.0/24  fd11:2::/64  gw 10.11.2.1
#   SVC   1330  10.11.3.0/24  fd11:3::/64  gw 10.11.3.1
#   VPN   1340  10.11.4.0/24  fd11:4::/64  gw 10.11.4.1
#
# Network bridges:
#   vmbrAPPS — VLAN trunk (OPNsense LAN + all LXC NICs)
#   vmbrWAN3 — WAN uplink (temporary internet via pfSense OOB 10.6.224.0/20)
#
# VMID scheme:
#   test VM:  1100-1499
#   test LXC: 1500-1999
#
# Deploy order: SDN → OPNsense (console bootstrap) → lib-opnsense config → LXCs
################################################################################

locals {
  # One key per user. Passphrase mandatory. Loaded via ssh-agent.
  # TODO: define in user identity ADR (svc-rune + by-systems profiles)
  standard_ssh_keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHbkOZYUkqJ9pdmDWDm87MBI1Rf4x7fZV3IMuitG+qlu svc-rune@by-systems.be",
  ]
}

################################################################################
# SDN Zone: test
# VLAN offset +1000 from poc (310→1310, 320→1320, 330→1330, 340→1340)
################################################################################

resource "proxmox_sdn_zone_vlan" "test" {
  id     = "test"
  bridge = "vmbrAPPS"
  mtu    = 1500
  nodes  = ["srv-proxmox-poc-01"]
}

resource "proxmox_sdn_vnet" "tmgmt" {
  id    = "tmgmt"
  zone  = proxmox_sdn_zone_vlan.test.id
  alias = "Test Management"
  tag   = 1310

  depends_on = [proxmox_sdn_zone_vlan.test]
}

resource "proxmox_sdn_vnet" "tdmz" {
  id    = "tdmz"
  zone  = proxmox_sdn_zone_vlan.test.id
  alias = "Test DMZ"
  tag   = 1320

  depends_on = [proxmox_sdn_zone_vlan.test]
}

resource "proxmox_sdn_vnet" "tsvc" {
  id    = "tsvc"
  zone  = proxmox_sdn_zone_vlan.test.id
  alias = "Test Services"
  tag   = 1330

  depends_on = [proxmox_sdn_zone_vlan.test]
}

resource "proxmox_sdn_vnet" "tvpn" {
  id    = "tvpn"
  zone  = proxmox_sdn_zone_vlan.test.id
  alias = "Test VPN Clients"
  tag   = 1340

  depends_on = [proxmox_sdn_zone_vlan.test]
}

resource "proxmox_sdn_subnet" "tmgmt" {
  vnet    = proxmox_sdn_vnet.tmgmt.id
  cidr    = "10.11.1.0/24"
  gateway = "10.11.1.1"

  depends_on = [proxmox_sdn_vnet.tmgmt]
}

resource "proxmox_sdn_subnet" "tdmz" {
  vnet    = proxmox_sdn_vnet.tdmz.id
  cidr    = "10.11.2.0/24"
  gateway = "10.11.2.1"

  depends_on = [proxmox_sdn_vnet.tdmz]
}

resource "proxmox_sdn_subnet" "tsvc" {
  vnet    = proxmox_sdn_vnet.tsvc.id
  cidr    = "10.11.3.0/24"
  gateway = "10.11.3.1"

  depends_on = [proxmox_sdn_vnet.tsvc]
}

resource "proxmox_sdn_subnet" "tvpn" {
  vnet    = proxmox_sdn_vnet.tvpn.id
  cidr    = "10.11.4.0/24"
  gateway = "10.11.4.1"

  depends_on = [proxmox_sdn_vnet.tvpn]
}

resource "proxmox_sdn_applier" "test" {
  depends_on = [
    proxmox_sdn_zone_vlan.test,
    proxmox_sdn_vnet.tmgmt,
    proxmox_sdn_vnet.tdmz,
    proxmox_sdn_vnet.tsvc,
    proxmox_sdn_vnet.tvpn,
    proxmox_sdn_subnet.tmgmt,
    proxmox_sdn_subnet.tdmz,
    proxmox_sdn_subnet.tsvc,
    proxmox_sdn_subnet.tvpn,
  ]
}

################################################################################
# OPNsense test VM (EXISTING — vm-fw-poc-01, VMID 101)
# DO NOT MODIFY — kept running until vm-fw-test-01 (1100) is validated.
# LAN (vtnet0→vmbrAPPS inverted during console install) / WAN (vtnet1→vmbrWAN3)
################################################################################

module "opnsense" {
  source = "../../modules/vm-opnsense"

  name        = "vm-opnsense-test-01"
  vm_id       = 101
  env         = "test"
  target_node = "srv-proxmox-poc-01"

  cores        = 2
  memory       = 4096
  disk_size    = 20
  disk_storage = "poc-data"

  iso_storage = "poc-iso"
  iso_file    = "OPNsense-26.1.2-dvd-amd64.iso"

  wan_bridge = "vmbrWAN3"
  lan_bridge = "vmbrAPPS"

  depends_on = [proxmox_sdn_applier.test]
}

################################################################################
# OPNsense test VM (NEW — vm-fw-test-01, VMID 1100)
#
# NIC order: LAN first (vtnet0), then 3x WAN
#   vtnet0 (LAN)  → vmbrAPPS (trunk: VLANs 1310-1340)
#   vtnet1 (WAN1) → vmbrWAN1 (future Proximus — not connected yet)
#   vtnet2 (WAN2) → vmbrWAN2 (future Telenet — not connected yet)
#   vtnet3 (WAN3) → vmbrWAN3 (current internet via pfSense OOB)
#
# OPNsense defaults vtnet0=LAN. Console install will assign interfaces.
# If OPNsense assigns wrong, reassign during console bootstrap.
#
# Bootstrap (manual, console):
#   1. Complete ISO installer
#   2. Assign interfaces: vtnet0=LAN, vtnet1=WAN1, vtnet2=WAN2, vtnet3=WAN3
#   3. pfctl -d
#   4. Create svc-rune (admins, shell=/bin/sh, authorizedkeys, API key)
#   5. Enable SSH
#   6. Verify: API + SSH from Rune VM
################################################################################

resource "proxmox_virtual_environment_vm" "fw_test_01" {
  name      = "vm-fw-test-01"
  vm_id     = 1100
  node_name = "srv-proxmox-poc-01"

  tags = ["layer0", "opnsense", "env-test"]

  bios          = "ovmf"
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  tablet_device = false

  on_boot    = true
  started    = true
  protection = false

  agent {
    enabled = false
  }

  cpu {
    cores      = 2
    sockets    = 1
    type       = "host"
    hotplugged = 0
    flags      = ["+aes"]
  }

  memory {
    dedicated = 4096
    floating  = 0
  }

  # Boot disk
  disk {
    datastore_id = "poc-data"
    interface    = "scsi0"
    size         = 20
    file_format  = "raw"
    iothread     = true
    discard      = "on"
    cache        = "none"
    ssd          = true
  }

  # EFI disk (UEFI)
  efi_disk {
    datastore_id      = "poc-data"
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = false
  }

  # ISO for installation
  cdrom {
    file_id   = "poc-iso:iso/OPNsense-26.1.2-dvd-amd64.iso"
    interface = "ide0"
  }

  boot_order = ["scsi0", "ide0"]

  # vtnet0 — LAN (VLAN trunk, first NIC = OPNsense default LAN)
  network_device {
    bridge   = "vmbrAPPS"
    model    = "virtio"
    firewall = false
    queues   = 2
  }

  # vtnet1 — WAN1 (future Proximus)
  network_device {
    bridge   = "vmbrWAN1"
    model    = "virtio"
    firewall = false
    queues   = 2
  }

  # vtnet2 — WAN2 (future Telenet)
  network_device {
    bridge   = "vmbrWAN2"
    model    = "virtio"
    firewall = false
    queues   = 2
  }

  # vtnet3 — WAN3 (current internet via pfSense OOB)
  network_device {
    bridge   = "vmbrWAN3"
    model    = "virtio"
    firewall = false
    queues   = 2
  }

  vga {
    type   = "std"
    memory = 16
  }

  serial_device {}

  depends_on = [proxmox_sdn_applier.test]
}

################################################################################
# Test LXCs — created after OPNsense is configured with VLANs + DHCP + FW
# Uncomment when ready. All on vmbrAPPS VLANs (1 NIC each, behind OPNsense).
################################################################################

# module "webdmz" {
#   source = "../../modules/lxc-standard"
#
#   name        = "lxc-webdmz-test-01"
#   vm_id       = 1500
#   target_node = "srv-proxmox-poc-01"
#   ostemplate  = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
#
#   cores   = 1
#   memory  = 256
#   disk    = "4G"
#   storage = "poc-data"
#
#   network_bridge = "tdmz"
#   ip             = "10.11.2.10/24"
#   gateway        = "10.11.2.1"
#
#   ssh_keys = local.standard_ssh_keys
# }

# module "websrv" {
#   source = "../../modules/lxc-standard"
#
#   name        = "lxc-websrv-test-01"
#   vm_id       = 1501
#   target_node = "srv-proxmox-poc-01"
#   ostemplate  = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
#
#   cores   = 1
#   memory  = 256
#   disk    = "4G"
#   storage = "poc-data"
#
#   network_bridge = "tsvc"
#   ip             = "10.11.3.10/24"
#   gateway        = "10.11.3.1"
#
#   ssh_keys = local.standard_ssh_keys
# }

# module "dhcpclient" {
#   source = "../../modules/lxc-standard"
#
#   name        = "lxc-dhcpclient-test-01"
#   vm_id       = 1502
#   target_node = "srv-proxmox-poc-01"
#   ostemplate  = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
#
#   cores   = 1
#   memory  = 256
#   disk    = "4G"
#   storage = "poc-data"
#
#   network_bridge = "tdmz"
#   ip             = "dhcp"
#   gateway        = ""
#
#   ssh_keys = local.standard_ssh_keys
#
#   # DEPENDS ON: OPNsense Kea DHCP configured on VLAN 1320
# }

################################################################################
# Outputs
################################################################################

output "opnsense_vm_id" {
  value = module.opnsense.vm_id
}

output "fw_test_01_vm_id" {
  value = proxmox_virtual_environment_vm.fw_test_01.vm_id
}

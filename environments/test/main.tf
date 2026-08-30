################################################################################
# BY-SYSTEMS — Test Environment (ADR-0032)
# Node: srv-proxmox-01
# Purpose: lib-opnsense integration testing + full network simulation
#
# SDN zone: test (9 segments, VLANs 2010-2400 on vmbrAPPS)
# VLAN range: 2001-2999 (test), offset +1000 from prod (1001-1999)
# Reserved: 1-999 (ISP, Arista, fabric)
#
# Segments (all dual-stack IPv4 + IPv6 ULA):
#   MGMT    2010  10.11.1.0/24   fd11:1::/64    gw 10.11.1.1
#   DMZ     2020  10.11.2.0/24   fd11:2::/64    gw 10.11.2.1
#   SVC     2030  10.11.3.0/24   fd11:3::/64    gw 10.11.3.1
#   VPN     2040  10.11.4.0/24   fd11:4::/64    gw 10.11.4.1
#   IoT     2100  10.11.10.0/24  fd11:10::/64   gw 10.11.10.1
#   VoIP    2110  10.11.11.0/24  fd11:11::/64   gw 10.11.11.1
#   Storage 2200  10.11.20.0/24  fd11:20::/64   gw 10.11.20.1
#   Media   2300  10.11.30.0/24  fd11:30::/64   gw 10.11.30.1
#   CCTV    2400  10.11.40.0/24  fd11:40::/64   gw 10.11.40.1
#
# Network bridges:
#   vmbrAPPS — VLAN trunk (OPNsense LAN + all VM/LXC NICs)
#   vmbrWAN1 — WAN1 Proximus PPPoE (future)
#   vmbrWAN2 — WAN2 Telenet (future)
#   vmbrWAN3 — WAN3 temporary internet via pfSense OOB (10.6.224.0/20)
#
# VMID scheme:
#   test VM:  1100-1499
#   test LXC: 1500-1999
#
# Deploy order: SDN → OPNsense (console bootstrap) → lib-opnsense config → LXCs
################################################################################

locals {
  # SSH keys injected into every LXC's root authorized_keys via cloud-init.
  # First key = svc-rune (passphrase-protected — ADR-0033 — used by humans via agent).
  # Second key = opnsense — the SAME key that authenticates by-rune@vm-opns-test-01,
  # so SSH from Rune can use vm-opns-test-01 as a ProxyJump host into the LXCs
  # (no Rune→LXC route needed until ansible-platform#10 is resolved).
  standard_ssh_keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHbkOZYUkqJ9pdmDWDm87MBI1Rf4x7fZV3IMuitG+qlu svc-rune@by-systems.be",
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF8wby/zI+Mx0CEtG6rvpAz9ijK9xu+GtuMR8ssAH23t rune@opnsense-test",
  ]
}

################################################################################
# SDN Zone: test
# 9 segments, VLAN offset +1000 from prod (ADR-0032)
################################################################################

resource "proxmox_sdn_zone_vlan" "test" {
  id     = "test"
  bridge = "vmbrAPPS"
  mtu    = 1500
  nodes  = ["srv-proxmox-01"]
}

# --- Core segments ---

resource "proxmox_sdn_vnet" "tmgmt" {
  id         = "tmgmt"
  zone       = proxmox_sdn_zone_vlan.test.id
  alias      = "Test Management"
  tag        = 2010
  depends_on = [proxmox_sdn_zone_vlan.test]
}

resource "proxmox_sdn_vnet" "tdmz" {
  id         = "tdmz"
  zone       = proxmox_sdn_zone_vlan.test.id
  alias      = "Test DMZ"
  tag        = 2020
  depends_on = [proxmox_sdn_zone_vlan.test]
}

resource "proxmox_sdn_vnet" "tsvc" {
  id         = "tsvc"
  zone       = proxmox_sdn_zone_vlan.test.id
  alias      = "Test Services"
  tag        = 2030
  depends_on = [proxmox_sdn_zone_vlan.test]
}

resource "proxmox_sdn_vnet" "tvpn" {
  id         = "tvpn"
  zone       = proxmox_sdn_zone_vlan.test.id
  alias      = "Test VPN Clients"
  tag        = 2040
  depends_on = [proxmox_sdn_zone_vlan.test]
}

# --- Extended segments ---

resource "proxmox_sdn_vnet" "tiot" {
  id         = "tiot"
  zone       = proxmox_sdn_zone_vlan.test.id
  alias      = "Test IoT"
  tag        = 2100
  depends_on = [proxmox_sdn_zone_vlan.test]
}

resource "proxmox_sdn_vnet" "tvoip" {
  id         = "tvoip"
  zone       = proxmox_sdn_zone_vlan.test.id
  alias      = "Test VoIP"
  tag        = 2110
  depends_on = [proxmox_sdn_zone_vlan.test]
}

resource "proxmox_sdn_vnet" "tstor" {
  id         = "tstor"
  zone       = proxmox_sdn_zone_vlan.test.id
  alias      = "Test Storage"
  tag        = 2200
  depends_on = [proxmox_sdn_zone_vlan.test]
}

resource "proxmox_sdn_vnet" "tmedia" {
  id         = "tmedia"
  zone       = proxmox_sdn_zone_vlan.test.id
  alias      = "Test Media"
  tag        = 2300
  depends_on = [proxmox_sdn_zone_vlan.test]
}

resource "proxmox_sdn_vnet" "tcctv" {
  id         = "tcctv"
  zone       = proxmox_sdn_zone_vlan.test.id
  alias      = "Test CCTV"
  tag        = 2400
  depends_on = [proxmox_sdn_zone_vlan.test]
}

# --- Subnets (all dual-stack, IPv6 configured on OPNsense) ---

resource "proxmox_sdn_subnet" "tmgmt" {
  vnet       = proxmox_sdn_vnet.tmgmt.id
  cidr       = "10.11.1.0/24"
  gateway    = "10.11.1.1"
  depends_on = [proxmox_sdn_vnet.tmgmt]
}

resource "proxmox_sdn_subnet" "tdmz" {
  vnet       = proxmox_sdn_vnet.tdmz.id
  cidr       = "10.11.2.0/24"
  gateway    = "10.11.2.1"
  depends_on = [proxmox_sdn_vnet.tdmz]
}

resource "proxmox_sdn_subnet" "tsvc" {
  vnet       = proxmox_sdn_vnet.tsvc.id
  cidr       = "10.11.3.0/24"
  gateway    = "10.11.3.1"
  depends_on = [proxmox_sdn_vnet.tsvc]
}

resource "proxmox_sdn_subnet" "tvpn" {
  vnet       = proxmox_sdn_vnet.tvpn.id
  cidr       = "10.11.4.0/24"
  gateway    = "10.11.4.1"
  depends_on = [proxmox_sdn_vnet.tvpn]
}

resource "proxmox_sdn_subnet" "tiot" {
  vnet       = proxmox_sdn_vnet.tiot.id
  cidr       = "10.11.10.0/24"
  gateway    = "10.11.10.1"
  depends_on = [proxmox_sdn_vnet.tiot]
}

resource "proxmox_sdn_subnet" "tvoip" {
  vnet       = proxmox_sdn_vnet.tvoip.id
  cidr       = "10.11.11.0/24"
  gateway    = "10.11.11.1"
  depends_on = [proxmox_sdn_vnet.tvoip]
}

resource "proxmox_sdn_subnet" "tstor" {
  vnet       = proxmox_sdn_vnet.tstor.id
  cidr       = "10.11.20.0/24"
  gateway    = "10.11.20.1"
  depends_on = [proxmox_sdn_vnet.tstor]
}

resource "proxmox_sdn_subnet" "tmedia" {
  vnet       = proxmox_sdn_vnet.tmedia.id
  cidr       = "10.11.30.0/24"
  gateway    = "10.11.30.1"
  depends_on = [proxmox_sdn_vnet.tmedia]
}

resource "proxmox_sdn_subnet" "tcctv" {
  vnet       = proxmox_sdn_vnet.tcctv.id
  cidr       = "10.11.40.0/24"
  gateway    = "10.11.40.1"
  depends_on = [proxmox_sdn_vnet.tcctv]
}

resource "proxmox_sdn_applier" "test" {
  depends_on = [
    proxmox_sdn_zone_vlan.test,
    proxmox_sdn_vnet.tmgmt,
    proxmox_sdn_vnet.tdmz,
    proxmox_sdn_vnet.tsvc,
    proxmox_sdn_vnet.tvpn,
    proxmox_sdn_vnet.tiot,
    proxmox_sdn_vnet.tvoip,
    proxmox_sdn_vnet.tstor,
    proxmox_sdn_vnet.tmedia,
    proxmox_sdn_vnet.tcctv,
    proxmox_sdn_subnet.tmgmt,
    proxmox_sdn_subnet.tdmz,
    proxmox_sdn_subnet.tsvc,
    proxmox_sdn_subnet.tvpn,
    proxmox_sdn_subnet.tiot,
    proxmox_sdn_subnet.tvoip,
    proxmox_sdn_subnet.tstor,
    proxmox_sdn_subnet.tmedia,
    proxmox_sdn_subnet.tcctv,
  ]
}

################################################################################
# OPNsense FW VM — target name vm-opns-01 (VMID 1100). Hostname carries NO env
# (naming/0001 §10); the live resource is still vm-opns-test-01 pending the
# naming-realign rename. Env = NetBox field + DNS zone.
#
# NIC order: LAN first (vtnet0), then 3x WAN
#   vtnet0 (LAN)  → vmbrAPPS (trunk: VLANs 2010-2400)
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

# resource "proxmox_virtual_environment_vm" "fw_test_01" {
#   name      = "vm-fw-test-01"
#   vm_id     = 1100
#   node_name = "srv-proxmox-01"
#
#   tags = ["layer0", "opnsense", "env-test"]
#
#   bios          = "ovmf"
#   machine       = "q35"
#   scsi_hardware = "virtio-scsi-single"
#   tablet_device = false
#
#   on_boot    = true
#   started    = true
#   protection = false
#
#   agent {
#     enabled = false
#   }
#
#   cpu {
#     cores      = 2
#     sockets    = 1
#     type       = "host"
#     hotplugged = 0
#     flags      = ["+aes"]
#   }
#
#   memory {
#     dedicated = 4096
#     floating  = 0
#   }
#
#   # Boot disk
#   disk {
#     datastore_id = "poc-data"
#     interface    = "scsi0"
#     size         = 20
#     file_format  = "raw"
#     iothread     = true
#     discard      = "on"
#     cache        = "none"
#     ssd          = true
#   }
#
#   # EFI disk (UEFI)
#   efi_disk {
#     datastore_id      = "poc-data"
#     file_format       = "raw"
#     type              = "4m"
#     pre_enrolled_keys = false
#   }
#
#   # ISO for installation
#   cdrom {
#     file_id   = "poc-iso:iso/OPNsense-26.1.2-dvd-amd64.iso"
#     interface = "ide0"
#   }
#
#   boot_order = ["scsi0", "ide0"]
#
#   # vtnet0 — LAN (VLAN trunk, first NIC = OPNsense default LAN)
#   network_device {
#     bridge   = "vmbrAPPS"
#     model    = "virtio"
#     firewall = false
#     queues   = 2
#   }
#
#   # vtnet1 — WAN1 (future Proximus)
#   network_device {
#     bridge   = "vmbrWAN1"
#     model    = "virtio"
#     firewall = false
#     queues   = 2
#   }
#
#   # vtnet2 — WAN2 (future Telenet)
#   network_device {
#     bridge   = "vmbrWAN2"
#     model    = "virtio"
#     firewall = false
#     queues   = 2
#   }
#
#   # vtnet3 — WAN3 (current internet via pfSense OOB)
#   network_device {
#     bridge   = "vmbrWAN3"
#     model    = "virtio"
#     firewall = false
#     queues   = 2
#   }
#
#   vga {
#     type   = "std"
#     memory = 16
#   }
#
#   serial_device {}
#
#   depends_on = [proxmox_sdn_applier.test]
# }

################################################################################
# Test LXCs — created after OPNsense is configured with VLANs + DHCP + FW
# Uncomment when ready. All on vmbrAPPS VLANs (1 NIC each, behind OPNsense).
################################################################################

# module "webdmz" {
#   source = "../../modules/lxc-standard"
#
#   name        = "lxc-webdmz-test-01"
#   vm_id       = 1500
#   target_node = "srv-proxmox-01"
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
#   target_node = "srv-proxmox-01"
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
#   target_node = "srv-proxmox-01"
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

# output "fw_test_01_vm_id" {
#   value = proxmox_virtual_environment_vm.fw_test_01.vm_id
# }

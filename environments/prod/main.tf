################################################################################
# BY-SYSTEMS — Proxmox PROD Environment
# Node: srv-proxmox-poc-01
# Provider: bpg/proxmox ~> 0.66
# State: local backend → GitLab managed state when GitLab CE deployed
#
# IP supernet: 10.1.0.0/20 (OPNsense manages, 4 VLANs: 300/310/320/330)
#   MGMT  310  10.1.1.0/24  gw 10.1.1.1
#   DMZ   320  10.1.2.0/24  gw 10.1.2.1
#   SVC   330  10.1.3.0/24  gw 10.1.3.1
#
# Network bridges on node (renamed 2026-05-22):
#   vmbrWAN1  — WAN1 Proximus PPPoE (OPNsense WAN primary, future)
#   vmbrWAN2  — WAN2 Telenet (OPNsense WAN secondary, future)
#   vmbrOOB   — OOB uplink: bond0 -> 10.6.224.0/20 (current bootstrap internet)
#   vmbrAPPS  — VLAN trunk bridge (OPNsense LAN + all VM NICs)
#   vmbrFAB   — fabric supervision (disabled, not yet wired)
#
# Deploy order: OPNsense → SDN VNets → all other VMs
################################################################################

locals {
  standard_ssh_keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJ8rXlV8+/e20imHW/hTry2DbqQ9bIpwslC4MIINlJW by-systems@ws-win11-ref",
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuUNkyvMaETbPeBGsBPEfzeYsL1SuVbvPUOMIb/2VU8 by-systems@rune-vm",
    # Rune automation key (no passphrase) — lets ansible/CI reach managed VMs non-interactively.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAPtVxi41CKLEZuYr1PhIdPTJJEQ+bqbhnBuZgAVcT1U rune@by-systems-automation-nopass",
  ]
}

################################################################################
# Layer -1 — Proxmox SDN — prod zone per doc-platform-core ADR
#   - infra/0004-network-architecture §3 (prod VLANs 1010-1400, 9 segments)
#   - infra/0005-environment-tiers (prod+drp share the prod zone)
#   - naming/0001-infra §7 (zone name = env tier group, VNet names env-agnostic)
################################################################################

module "sdn" {
  source = "../../modules/sdn"

  node_name = "srv-proxmox-poc-01"
  zone_id   = "prod"
  bridge    = "vmbrAPPS"
  mtu       = 1500

  vnets = {
    mgmt    = { tag = 1010, alias = "Prod Management", subnet = "10.1.1.0/24", gateway = "10.1.1.1" }
    dmz     = { tag = 1020, alias = "Prod DMZ", subnet = "10.1.2.0/24", gateway = "10.1.2.1" }
    svc     = { tag = 1030, alias = "Prod Services", subnet = "10.1.3.0/24", gateway = "10.1.3.1" }
    vpn     = { tag = 1040, alias = "Prod VPN", subnet = "10.1.4.0/24", gateway = "10.1.4.1" }
    iot     = { tag = 1100, alias = "Prod IoT", subnet = "10.1.10.0/24", gateway = "10.1.10.1" }
    voip    = { tag = 1110, alias = "Prod VoIP", subnet = "10.1.11.0/24", gateway = "10.1.11.1" }
    storage = { tag = 1200, alias = "Prod Storage", subnet = "10.1.20.0/24", gateway = "10.1.20.1" }
    media   = { tag = 1300, alias = "Prod Media", subnet = "10.1.30.0/24", gateway = "10.1.30.1" }
    cctv    = { tag = 1400, alias = "Prod CCTV", subnet = "10.1.40.0/24", gateway = "10.1.40.1" }
  }
}

output "sdn_zone_id" {
  value = module.sdn.zone_id
}

output "sdn_vnet_ids" {
  value = module.sdn.vnet_ids
}

################################################################################
# Layer 2 — OPNsense FW (the only router on the platform)
#   - naming/0001-infra §5: short code "opns", VMID 100 (prod range 100-499)
#   - infra/0004-network-architecture §6: OPNsense is THE platform router
#   - services/0001-opnsense: provisioning contract (ISO install + console wizard)
#
# WAN: DHCP on vmbrWAN3 = OOB bridge (10.6.224.0/20) — bootstrap mode
#      ISP WANs (vmbrWAN1/2 = Proximus/Telenet) wired post-install
# LAN: vmbrAPPS trunk — carries VLANs 1010-1400 (prod SDN zone)
################################################################################

module "opnsense" {
  source = "../../modules/vm-opnsense"

  name        = "vm-opns-01"
  vm_id       = 100
  target_node = "srv-proxmox-poc-01"

  cores        = 2
  memory       = 3072
  disk_size    = 20
  disk_storage = "poc-data"

  iso_storage = "poc-iso"
  iso_file    = "OPNsense-26.1.6-dvd-amd64.iso"

  wan_bridge  = "vmbrOOB"  # vtnet1 — bootstrap DHCP on OOB (bond0 -> 10.6.224.0/20) (temp)
  lan_bridge  = "vmbrAPPS" # vtnet0 — SDN trunk (prod zone, VLANs 1010-1400)
  wan1_bridge = "vmbrWAN1" # vtnet2 — Proximus PPPoE (pre-staged, no carrier yet)
  wan2_bridge = "vmbrWAN2" # vtnet3 — Telenet (pre-staged, no carrier yet)

  tags = ["layer2", "opnsense", "env-prod"]
}

output "opnsense_vm_id" {
  value = module.opnsense.vm_id
}

################################################################################
# Service VMs/LXCs (NetBox, Postgres/Patroni, Redis, Authentik, Vault, …) are
# NOT defined inline here. They are built as the shared cluster per the services
# ADRs — see db-cluster.tf (services/0004-database-strategy + services/0003-netbox
# -cmdb). The earlier one-VM-per-service draft (Pi-hole-era) was superseded by the
# AdGuard DNS chain + Patroni/Redis cluster model and removed.
################################################################################

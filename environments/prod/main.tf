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
#
# NOT terraform-managed (issue #27, 2026-06-06). The prod FW vm-opns-01 (vmid
# 100) is provisioned by the SEED pipeline (modules/vm-opnsense/seed: the
# hardware profile is seeds/vm-opns-01.json "vm"; drift gate =
# `recreate-and-seed.py vm-opns-01 --check`, never writes; recreate needs
# --confirm-prod-recreate in a window): a 2-disk virtio layout (virtio0 root 20G +
# virtio1 1M config-import drive) that the `vm-opnsense` terraform module cannot
# model (the importer drive is sub-GB; bpg disk size is integer GB). The live
# VM was removed from terraform state — managing it here produced a phantom
# disk (local-lvm/8G/null-interface) whose drift would, on apply, try to revert
# the running firewall to installer config. The FW is owned by seed (hardware)
# + ansible/lib MVC (config, fully reproducible — see ansible drift gate).
# The `modules/vm-opnsense/` module stays as the seed/reseed reference.
#
# on_boot: enforced as a hypervisor provisioning flag (onboot=1) at seed time.
################################################################################

################################################################################
# Service VMs/LXCs (NetBox, Postgres/Patroni, Redis, Authentik, Vault, …) are
# NOT defined inline here. They are built as the shared cluster per the services
# ADRs — see db-cluster.tf (services/0004-database-strategy + services/0003-netbox
# -cmdb). The earlier one-VM-per-service draft (Pi-hole-era) was superseded by the
# AdGuard DNS chain + Patroni/Redis cluster model and removed.
################################################################################

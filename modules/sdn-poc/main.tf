################################################################################
# BY-SYSTEMS — SDN PoC Module
#
# Creates a VLAN-type SDN zone and the 3 standard VNets (mgmt/dmz/svc) with
# subnets. Uses vmbrAPPS as the VLAN-aware uplink bridge.
#
# Zone type: VLAN — uses existing Linux bridge with VLAN tagging.
# No VXLAN, no EVPN — single node, no inter-node tunnelling required.
#
# Naming standard (ADR-0010 / ADR-0015):
#   Zone = environment name (poc / dev / prod)
#   VNet = environment-agnostic (mgmt / dmz / svc)
#   Environment context lives in VM hostname, FQDN, cert — not in SDN primitives.
#
# Deploy order:
#   1. zone → vnets → subnets (depends_on chain enforced)
#   2. applier triggers Proxmox SDN reload (makes config live)
#   3. OPNsense VM LAN NIC attaches to vmbrAPPS; Proxmox SDN handles VLAN tagging
#
# Refs: platform-setup #78, ADR-0015
################################################################################

# Step 1 — SDN applier: acts as a gate. Applied after all resources.
# Required by bpg/proxmox to push pending SDN config to Proxmox.
resource "proxmox_sdn_applier" "poc" {
  depends_on = [
    proxmox_sdn_zone_vlan.poc,
    proxmox_sdn_vnet.vnets,
    proxmox_sdn_subnet.subnets,
  ]
}

# Step 2 — Zone: VLAN type, attached to vmbrAPPS
resource "proxmox_sdn_zone_vlan" "poc" {
  id     = var.zone_id
  bridge = var.bridge
  mtu    = var.mtu
  nodes  = [var.node_name]
}

# Step 3 — VNets: one per segment (mgmt/dmz/svc)
resource "proxmox_sdn_vnet" "vnets" {
  for_each = var.vnets

  id    = each.key
  zone  = proxmox_sdn_zone_vlan.poc.id
  alias = each.value.alias
  tag   = each.value.tag

  depends_on = [proxmox_sdn_zone_vlan.poc]
}

# Step 4 — Subnets: one per VNet, gateway = OPNsense VLAN sub-interface IP
resource "proxmox_sdn_subnet" "subnets" {
  for_each = var.vnets

  vnet    = proxmox_sdn_vnet.vnets[each.key].id
  cidr    = each.value.subnet
  gateway = each.value.gateway

  depends_on = [proxmox_sdn_vnet.vnets]
}

################################################################################
# BY-SYSTEMS — Cluster services: shared common (template + locals)
# Node: srv-proxmox-poc-01 | env=prod
#
# Per-service isolation (decision 2026-06-06): every cluster service lives in its
# OWN file — svc-traefik.tf, svc-postgresql.tf, svc-redis.tf, … — so editing one
# never touches another. This file holds ONLY the bits genuinely shared by all:
# the Debian-13 LXC template download and a few common locals.
#
# Addressing convention (decision 2026-06-06): per /24,
#   .1            = gateway (OPNsense)
#   .50-.99       = DHCP dynamic pool (Kea)
#   .100-.199     = DEDICATED mandatory/infra services (static)  <-- cluster + AdGuard(.101)
#   .200-.254     = reserved
# Dual-stack, never inside the DHCP pool. IPv6 = SLAAC for clients; services
# static at ::1xx (mirrors the v4 octet).
################################################################################

locals {
  svc_node   = "srv-proxmox-poc-01"
  svc_bridge = "vmbrAPPS"
  svc_domain = "by-research.be" # prod zone — clean, no env sub-domain (naming/0001 §7)
  # standard_ssh_keys is defined in main.tf (rune automation key + ref ws).
}

# Proxmox-standard Debian 13 LXC template (ships openssh-server, enabled) →
# reachable for Ansible over SSH via the rune key, no PVE exec needed.
# Same resource address as the deferred db-cluster used → terraform adopts the
# already-downloaded vztmpl in state (no destroy/recreate churn).
resource "proxmox_virtual_environment_download_file" "tmpl_debian_13" {
  content_type        = "vztmpl"
  datastore_id        = "poc-iso"
  node_name           = local.svc_node
  url                 = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
  file_name           = "debian-13-standard_13.1-2_amd64.tar.zst"
  overwrite           = false
  overwrite_unmanaged = true
}

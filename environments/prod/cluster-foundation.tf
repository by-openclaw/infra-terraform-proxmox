################################################################################
# BY-SYSTEMS — Platform cluster foundation (minimal, single-node)
# Node: srv-proxmox-poc-01 | env=prod
#
# Pivot 2026-06-06: FW frozen at minimal-secure; build the platform cluster
# foundation-first. The full-HA design (Patroni 3 + etcd 3 + Redis 2 + Sentinel
# + pgpool + NetBox) is PRESERVED in `db-cluster.tf.ha-deferred` and will be
# evolved into later — single-node now to move fast (daily backups cover
# resilience for the build-out phase). See services/0004-database-strategy.
#
# Foundation LXCs (this file):
#   lxc-traefik-01  vmid 500  DMZ 1020  10.1.2.10 / fd01:2::10  — HTTPS ingress
#   lxc-pgsql-01    vmid 510  SVC 1030  10.1.3.10 / fd01:3::10  — PostgreSQL
#   lxc-redis-01    vmid 517  SVC 1030  10.1.3.17 / fd01:3::17  — Redis cache
#
# Placement (infra/0004-network-architecture §3): Traefik in the DMZ edge zone
# (reverse-proxy fronting internal services; public exposure via #9 Contabo
# tunnel later). Postgres/Redis in the SVC services zone. Prod LXC VMID range
# 500-999 (infra/0004 §6). Hostnames carry NO env (naming/0001 §7/§10); prod
# DNS zone is clean → FQDN `{host}.by-research.be`.
#
# Host octets (.10/.17) and hostnames reuse the deferred-HA layout so a future
# HA promotion is a clean superset, not a renumber.
#
# Template = debian-13-standard (ships openssh-server) → reachable for Ansible
# over SSH via the rune key (feedback_credentials_rune_ssh_and_secret_folder),
# no PVE exec needed.
#
# Apply prerequisite: prod SDN zone + VLANs 1020/1030 live on Proxmox and routed
# by the FW before these LXCs are reachable.
#
# NOTE — NetBox self-registration (services/0003 §1): once NetBox is up, register
# every LXC here (host, IPv4/IPv6, VLAN/prefix) in NetBox.
################################################################################

locals {
  cf_node   = "srv-proxmox-poc-01"
  cf_bridge = "vmbrAPPS"
  cf_domain = "by-research.be" # prod zone — clean, no env sub-domain (naming/0001 §7)

  # Per-node placement. dns_servers = OPNsense gateway on the node's VLAN
  # (the only resolver on the platform, infra/0004 §6 → AdGuard chain).
  cluster_foundation = {
    "lxc-traefik-01" = {
      vmid  = 500, vlan = 1020
      ip4   = "10.1.2.10", ip6 = "fd01:2::10", gw4 = "10.1.2.1", gw6 = "fd01:2::1"
      cores = 1, mem = 1024, disk = 8
      tags  = ["role-ingress", "traefik", "zone-dmz"]
    }
    "lxc-pgsql-01" = {
      vmid  = 510, vlan = 1030
      ip4   = "10.1.3.10", ip6 = "fd01:3::10", gw4 = "10.1.3.1", gw6 = "fd01:3::1"
      cores = 2, mem = 2048, disk = 30
      tags  = ["role-db", "postgres", "zone-svc"]
    }
    "lxc-redis-01" = {
      vmid  = 517, vlan = 1030
      ip4   = "10.1.3.17", ip6 = "fd01:3::17", gw4 = "10.1.3.1", gw6 = "fd01:3::1"
      cores = 1, mem = 1024, disk = 8
      tags  = ["role-cache", "redis", "zone-svc"]
    }
  }
}

# Proxmox-standard Debian 13 LXC template (ships openssh-server, enabled).
# Same resource address as the deferred db-cluster.tf used → terraform adopts the
# already-downloaded vztmpl in state (no destroy/recreate churn).
resource "proxmox_virtual_environment_download_file" "tmpl_debian_13" {
  content_type        = "vztmpl"
  datastore_id        = "poc-iso"
  node_name           = local.cf_node
  url                 = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
  file_name           = "debian-13-standard_13.1-2_amd64.tar.zst"
  overwrite           = false
  overwrite_unmanaged = true
}

module "cluster_foundation" {
  source   = "../../modules/lxc-cloudinit"
  for_each = local.cluster_foundation

  name        = each.key
  vmid        = each.value.vmid
  target_node = local.cf_node
  env         = "prod"
  os_type     = "debian"
  tags        = concat(["service", "vlan${each.value.vlan}"], each.value.tags)

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = each.value.cores
  memory             = each.value.mem
  disk_gb            = each.value.disk
  storage            = "poc-data"

  network_bridge = local.cf_bridge
  vlan_tag       = each.value.vlan
  ipv4_address   = "${each.value.ip4}/24"
  ipv4_gateway   = each.value.gw4
  ipv6_address   = "${each.value.ip6}/64"
  ipv6_gateway   = each.value.gw6

  dns_domain  = local.cf_domain
  dns_servers = [each.value.gw4, each.value.gw6] # OPNsense resolver on this VLAN
  ssh_keys    = local.standard_ssh_keys          # prod locals (main.tf): rune key + ref ws
  # features defaults to nesting=true (systemd 255+ on Debian 13).
}

output "cluster_foundation" {
  description = "Minimal cluster foundation LXCs — register each in NetBox once up (services/0003 §1)"
  value = {
    for k, m in module.cluster_foundation : k => {
      vmid = local.cluster_foundation[k].vmid
      ipv4 = local.cluster_foundation[k].ip4
      ipv6 = local.cluster_foundation[k].ip6
      vlan = local.cluster_foundation[k].vlan
      fqdn = "${k}.by-research.be"
    }
  }
}

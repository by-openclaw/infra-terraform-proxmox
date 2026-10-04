################################################################################
# BY-SYSTEMS — HA data layer: the guests that turn the single PostgreSQL and the
# single Redis into clusters (services/0004-database-strategy).
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Node 1 of each cluster is the existing guest (svc-postgresql.tf lxc-pgsql-01 .110,
# svc-redis.tf lxc-redis-01 .117): promotion is a pure ADD, never a rebuild.
#
# Deferred decisions of services/0004, resolved at deployment (2026-10-04):
#   - DCS: etcd, three members COLOCATED on the three PostgreSQL nodes (no extra guests);
#   - frontend: ONE endpoint guest (lxc-pgpool-01) that follows the Patroni leader and the
#     Redis primary (TCP routing, no connection pooling: several consumers need session
#     semantics);
#   - Sentinel: three, colocated — on the two Redis nodes and on the endpoint guest;
#   - Redis replicas: one (two Redis nodes).
# The earlier sketch (db-cluster.tf.ha-deferred) planned dedicated etcd and Sentinel guests
# and VMIDs 511/512, taken since; it stays in the tree as history.
#
# All software-level HA on ONE hypervisor (services/0004 §Cluster placement): it survives a
# process or guest failure and allows rolling upgrades — not the loss of the host.
################################################################################

locals {
  ha_data_lxc = {
    "lxc-pgsql-02"  = { vmid = 513, host = 111, cores = 2, mem = 4096, disk = 30, tags = ["role-db", "postgres", "patroni"] }
    "lxc-pgsql-03"  = { vmid = 514, host = 112, cores = 2, mem = 4096, disk = 30, tags = ["role-db", "postgres", "patroni"] }
    "lxc-pgpool-01" = { vmid = 515, host = 113, cores = 1, mem = 1024, disk = 8, tags = ["role-db", "role-cache", "endpoint", "sentinel"] }
    "lxc-redis-02"  = { vmid = 518, host = 118, cores = 1, mem = 1024, disk = 8, tags = ["role-cache", "redis", "sentinel"] }
  }
}

module "ha_data" {
  source   = "../../modules/lxc-cloudinit"
  for_each = local.ha_data_lxc

  name        = each.key
  vmid        = each.value.vmid
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = concat(["service", "vlan1030", "zone-svc"], each.value.tags)

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = each.value.cores
  memory             = each.value.mem
  disk_gb            = each.value.disk
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.${each.value.host}/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::${each.value.host}/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "ha_data" {
  description = "HA data layer LXCs — register in NetBox once up (services/0003 §1)"
  value = {
    for k, m in module.ha_data : k => {
      vmid = local.ha_data_lxc[k].vmid
      ipv4 = "10.1.3.${local.ha_data_lxc[k].host}"
      ipv6 = "fd01:3::${local.ha_data_lxc[k].host}"
      vlan = 1030
    }
  }
}

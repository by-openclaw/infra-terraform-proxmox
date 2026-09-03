################################################################################
# BY-SYSTEMS — PostgreSQL HA replica — Patroni streaming standby (SVC zone)
# Node: srv-proxmox-poc-01 | env=prod | SVC VLAN 1030, 10.1.3.0/24
#
# Hot-standby replica of lxc-pgsql-01 (streaming replication → Patroni-managed
# HA). Additive: does NOT touch the live primary. Single-host app-HA (no 2nd
# host yet) — protects container/process failure + maintenance, not host failure. Configured by ansible-platform roles/verdaccio
# (via service_scaffold). Register in NetBox once up.
################################################################################
module "svc_pgsql_replica" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-pgsql-02"
  vmid        = 511
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-database", "postgresql", "replica", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 2
  memory             = 2048
  disk_gb            = 30
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.111/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::111/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = ["10.1.3.1", "fd01:3::1"]
  ssh_keys    = local.standard_ssh_keys
}

output "svc_pgsql_replica" {
  description = "Verdaccio LXC — register in NetBox once up (services/0004 DB-HA)"
  value = {
    name = "lxc-pgsql-02"
    vmid = 505
    ipv4 = "10.1.3.111"
    ipv6 = "fd01:3::111"
    vlan = 1030
    fqdn = "lxc-pgsql-02.by-research.be"
  }
}

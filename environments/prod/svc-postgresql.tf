################################################################################
# BY-SYSTEMS — PostgreSQL (shared platform database)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Single PostgreSQL LXC now (minimal). The full-HA Patroni design is preserved
# in db-cluster.tf.ha-deferred. This node IS the future Patroni node-1
# (hostname lxc-pgsql-01, vmid 510, .110) → HA promotion is a pure ADD of
# node-2/3 + etcd, NEVER a rebuild of this node (requirement: HA-later must not
# lose existing data). The ansible role MUST keep PGDATA on a persistent path +
# back up before any HA conversion.
#
# Static .110 in the dedicated mandatory-svc range .100-.199 (above DHCP pool),
# dual-stack. Consumers: Authentik, NetBox (separate databases).
################################################################################

module "svc_postgresql" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-pgsql-01"
  vmid        = 510
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-db", "postgres"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 2
  memory             = 2048
  disk_gb            = 30
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.110/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::110/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_postgresql" {
  description = "PostgreSQL LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-pgsql-01"
    vmid = 510
    ipv4 = "10.1.3.110"
    ipv6 = "fd01:3::110"
    vlan = 1030
    fqdn = "lxc-pgsql-01.by-research.be"
  }
}

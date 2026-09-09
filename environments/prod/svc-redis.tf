################################################################################
# BY-SYSTEMS — Redis (shared platform cache / broker)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Single Redis LXC now (minimal). The full-HA Redis+Sentinel design is preserved
# in db-cluster.tf.ha-deferred. This node IS the future Redis primary
# (hostname lxc-redis-01, vmid 517, .117) → HA promotion is a pure ADD of
# replica + Sentinel, NEVER a rebuild of this node. The ansible role MUST keep
# the data dir persistent + back up before any HA conversion.
#
# Static .117 in the dedicated mandatory-svc range .100-.199 (above DHCP pool),
# dual-stack. Consumers: Authentik, NetBox.
################################################################################

module "svc_redis" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-redis-01"
  vmid        = 517
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-cache", "redis"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 1
  memory             = 1024
  disk_gb            = 8
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.117/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::117/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_redis" {
  description = "Redis LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-redis-01"
    vmid = 517
    ipv4 = "10.1.3.117"
    ipv6 = "fd01:3::117"
    vlan = 1030
    fqdn = "lxc-redis-01.by-research.be"
  }
}

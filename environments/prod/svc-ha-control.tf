################################################################################
# BY-SYSTEMS — HA control plane and package caches: the guests that make the secret
# store and the identity provider redundant, and the guest of the package caches.
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Node 1 of each service is the existing guest (svc-vault.tf lxc-vault-01 .150,
# svc-authentik.tf lxc-authentik-01 .130): redundancy is a pure ADD, never a rebuild.
#   - Vault: integrated raft storage, three voters (lxc-vault-01, -02, -03);
#   - Authentik: a second server + worker on the shared PostgreSQL, behind the edge;
#   - package caches: PyPI (devpi) and Debian (apt-cacher-ng) on one guest — caches only,
#     rebuilt from upstream (backup class E).
#
# All software-level HA on ONE hypervisor (services/0004 §Cluster placement): it survives a
# process or guest failure and allows rolling upgrades — not the loss of the host.
################################################################################

locals {
  ha_control_lxc = {
    "lxc-vault-02"     = { vmid = 507, host = 151, cores = 1, mem = 1024, disk = 8, tags = ["role-secrets", "vault", "docker"] }
    "lxc-vault-03"     = { vmid = 516, host = 152, cores = 1, mem = 1024, disk = 8, tags = ["role-secrets", "vault", "docker"] }
    "lxc-authentik-02" = { vmid = 531, host = 131, cores = 2, mem = 2048, disk = 10, tags = ["role-sso", "authentik", "docker"] }
    "lxc-pkgcache-01"  = { vmid = 519, host = 198, cores = 2, mem = 1024, disk = 40, tags = ["role-registry", "pkgcache", "docker"] }
  }
}

module "ha_control" {
  source   = "../../modules/lxc-cloudinit"
  for_each = local.ha_control_lxc

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

output "ha_control" {
  description = "HA control plane and package cache LXCs — register in NetBox once up (services/0003 §1)"
  value = {
    for k, m in module.ha_control : k => {
      vmid = local.ha_control_lxc[k].vmid
      ipv4 = "10.1.3.${local.ha_control_lxc[k].host}"
      ipv6 = "fd01:3::${local.ha_control_lxc[k].host}"
      vlan = 1030
    }
  }
}

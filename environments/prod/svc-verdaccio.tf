################################################################################
# BY-SYSTEMS — Verdaccio: npm registry + upstream proxy (SVC zone)
# Node: srv-proxmox-poc-01 | env=prod | SVC VLAN 1030, 10.1.3.0/24
#
# Single owned npm endpoint: hosts @by-systems scope + proxies/caches npmjs.
# Storage = SeaweedFS S3 (verdaccio-aws-s3-storage). UI behind Authentik
# forwardAuth; npm CLI/CI use tokens. Configured by ansible-platform roles/verdaccio
# (via service_scaffold). Register in NetBox once up.
################################################################################
module "svc_verdaccio" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-verdaccio-01"
  vmid        = 505
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-registry", "verdaccio", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 1
  memory             = 1024
  disk_gb            = 8
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.191/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::191/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_verdaccio" {
  description = "Verdaccio LXC — register in NetBox once up (services/0011 registry)"
  value = {
    name = "lxc-verdaccio-01"
    vmid = 505
    ipv4 = "10.1.3.191"
    ipv6 = "fd01:3::191"
    vlan = 1030
    fqdn = "lxc-verdaccio-01.by-research.be"
  }
}

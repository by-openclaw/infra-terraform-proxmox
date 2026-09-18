################################################################################
# BY-SYSTEMS — Nextcloud (files / drawio) — Contabo S3 primary storage
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Nested LXC running Nextcloud (web + cron) as Docker containers (ansible:
# roles/docker + roles/nextcloud). Fronted by Traefik (wildcard TLS). Uses the
# shared PostgreSQL (postgres_db: nextcloud) + Redis, and Contabo S3 as PRIMARY
# object storage (bucket nextcloud-data) — so user data lives in S3, not on the
# LXC disk → modest 20G disk (app code + temp only). nesting=true (module
# default) runs Docker in an unprivileged LXC. Static .170 in the dedicated
# mandatory-svc range .100-.199, dual-stack. Mirrors svc-netbox.tf.
################################################################################

module "svc_nextcloud" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-nextcloud-01"
  vmid        = 503
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-files", "nextcloud", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 4
  memory             = 8192
  disk_gb            = 20
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.170/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::170/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_nextcloud" {
  description = "Nextcloud LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-nextcloud-01"
    vmid = 503
    ipv4 = "10.1.3.170"
    ipv6 = "fd01:3::170"
    vlan = 1030
    fqdn = "lxc-nextcloud-01.by-research.be"
  }
}

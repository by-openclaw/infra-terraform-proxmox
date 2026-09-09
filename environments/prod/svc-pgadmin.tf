################################################################################
# BY-SYSTEMS — pgAdmin 4 (PostgreSQL admin UI)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Nested LXC running pgAdmin 4 as a Docker container (ansible: roles/docker +
# roles/pgadmin). Internal-only DB admin tool, fronted by Traefik (wildcard TLS
# + ipAllowList) — NO public Cloudflare record, NO second proxy. Connects to
# Postgres (lxc-pgsql-01) over TLS (sslmode=verify-full).
#
# features.nesting (module default) is enough to run Docker in an unprivileged
# LXC here. keyctl can only be toggled by root@pam (our API token can't), and is
# not required for pgAdmin's workload. Static .140 in the dedicated mandatory-svc
# range .100-.199, dual-stack. 10G disk to hold Docker images. Mirrors svc-redis.tf.
################################################################################

module "svc_pgadmin" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-pgadmin-01"
  vmid        = 540
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-dbadmin", "pgadmin", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 1
  memory             = 1024
  disk_gb            = 10
  storage            = "poc-data"

  # nesting=true (module default) — required for Docker in an unprivileged LXC.

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.140/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::140/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_pgadmin" {
  description = "pgAdmin LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-pgadmin-01"
    vmid = 540
    ipv4 = "10.1.3.140"
    ipv6 = "fd01:3::140"
    vlan = 1030
    fqdn = "lxc-pgadmin-01.by-research.be"
  }
}

################################################################################
# BY-SYSTEMS — DbGate Community (web SQL/NoSQL client)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Nested LXC running DbGate Community (GPL-3.0, the free edition only — owner
# 2026-11-05: no paid plan in the platform) as Docker containers (ansible: roles/docker
# + roles/dbgate): the administrators' view of every platform database, and one view
# per Cerebrum instance (its own database + the Federation database). Internal-only,
# fronted by Traefik (wildcard TLS + ipAllowList), Authentik OIDC sign-in. Docker's
# data root on its own volume (ansible roles/docker_data, docker_hosts). Static .141 in
# the mandatory-svc range .100-.199, dual-stack. Mirrors svc-pgadmin.tf.
################################################################################

module "svc_dbgate" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-dbgate-01"
  vmid        = 541
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-dbadmin", "dbgate", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 2
  memory             = 2048 # three DbGate instances (Node.js)
  disk_gb            = 10
  storage            = "poc-data"

  # nesting=true (module default) — required for Docker in an unprivileged LXC.

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.141/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::141/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_dbgate" {
  description = "DbGate LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-dbgate-01"
    vmid = 541
    ipv4 = "10.1.3.141"
    ipv6 = "fd01:3::141"
    vlan = 1030
    fqdn = "lxc-dbgate-01.by-research.be"
  }
}

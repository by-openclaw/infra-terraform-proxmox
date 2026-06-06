################################################################################
# BY-SYSTEMS — Authentik (SSO / Identity Provider)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Nested LXC running Authentik (server + worker) as Docker containers (ansible:
# roles/docker + roles/authentik). Fronted by Traefik (wildcard TLS). Uses the
# shared PostgreSQL (postgres_db: authentik) + Redis. nesting=true (module
# default) runs Docker in an unprivileged LXC. Static .130 in the dedicated
# mandatory-svc range .100-.199, dual-stack. Mirrors svc-pgadmin.tf.
################################################################################

module "svc_authentik" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-authentik-01"
  vmid        = 530
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-sso", "authentik", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 2
  memory             = 2048
  disk_gb            = 10
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.130/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::130/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = ["10.1.3.1", "fd01:3::1"] # OPNsense resolver on SVC VLAN
  ssh_keys    = local.standard_ssh_keys
}

output "svc_authentik" {
  description = "Authentik LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-authentik-01"
    vmid = 530
    ipv4 = "10.1.3.130"
    ipv6 = "fd01:3::130"
    vlan = 1030
    fqdn = "lxc-authentik-01.by-research.be"
  }
}

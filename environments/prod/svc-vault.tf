################################################################################
# BY-SYSTEMS — HashiCorp Vault (secrets backend)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Nested LXC running Vault as a Docker container (ansible: roles/docker +
# roles/vault). Placed in SVC alongside the other shared backends (Postgres,
# Redis) — its consumers live in SVC, so app→Vault is intra-zone (no cross-zone
# rules), consistent with the data tier. Integrated raft storage, TLS via the
# shared wildcard cert, fronted by Traefik (wildcard TLS, internal-only).
# Static .150 in the dedicated mandatory-svc range .100-.199, dual-stack.
# Mirrors svc-authentik.tf.
################################################################################

module "svc_vault" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-vault-01"
  vmid        = 501
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-secrets", "vault", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 1
  memory             = 1024
  disk_gb            = 8
  storage            = "poc-data"

  # nesting=true (module default) — required for Docker in an unprivileged LXC.

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.150/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::150/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = ["10.1.3.1", "fd01:3::1"] # OPNsense resolver on SVC VLAN
  ssh_keys    = local.standard_ssh_keys
}

output "svc_vault" {
  description = "Vault LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-vault-01"
    vmid = 501
    ipv4 = "10.1.3.150"
    ipv6 = "fd01:3::150"
    vlan = 1030
    fqdn = "lxc-vault-01.by-research.be"
  }
}

################################################################################
# BY-SYSTEMS — Vaultwarden (Bitwarden-compatible password manager)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Nested LXC running Vaultwarden as a Docker container (ansible: roles/docker +
# roles/vaultwarden). Fronted by Traefik (wildcard TLS). Uses the shared
# PostgreSQL (postgres_db: vaultwarden). nesting=true (module default) runs
# Docker in an unprivileged LXC. Static .160 in the dedicated mandatory-svc
# range .100-.199, dual-stack. Mirrors svc-authentik.tf.
#
# NOTE: distinct from Vault (svc-vault.tf, vault.by-research.be) — Vault is the
# infra secrets backend; Vaultwarden is the end-user password manager.
################################################################################

module "svc_vaultwarden" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-vaultwarden-01"
  vmid        = 502
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-passwords", "vaultwarden", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 1
  memory             = 1024
  disk_gb            = 8
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.160/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::160/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = ["10.1.3.1", "fd01:3::1"] # OPNsense resolver on SVC VLAN
  ssh_keys    = local.standard_ssh_keys
}

output "svc_vaultwarden" {
  description = "Vaultwarden LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-vaultwarden-01"
    vmid = 502
    ipv4 = "10.1.3.160"
    ipv6 = "fd01:3::160"
    vlan = 1030
    fqdn = "lxc-vaultwarden-01.by-research.be"
  }
}

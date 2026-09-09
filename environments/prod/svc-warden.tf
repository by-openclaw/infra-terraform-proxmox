################################################################################
# BY-SYSTEMS — Warden (boot-time platform orchestrator)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Tiny hardened LXC that runs the cold-start reconciliation on boot (ansible:
# roles/warden): waits for Vault, UNSEALS it (shares held locally, 0600 — moved
# OFF the controller), then verifies the platform and notifies. No Traefik
# route, no VPN exposure, no inbound except SSH (identity-baseline model).
# NO docker (plain LXC, no nesting needed) — ansible-core runs natively.
# Static .250 in the SVC range, dual-stack. Mirrors svc-pgadmin.tf (smaller).
################################################################################

module "svc_warden" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-warden-01"
  vmid        = 595
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-orchestrator", "warden"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 1
  memory             = 512
  disk_gb            = 6
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.250/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::250/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_warden" {
  description = "Warden LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-warden-01"
    vmid = 595
    ipv4 = "10.1.3.250"
    ipv6 = "fd01:3::250"
    vlan = 1030
    fqdn = "lxc-warden-01.by-research.be"
  }
}

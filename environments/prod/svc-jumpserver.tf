################################################################################
# BY-SYSTEMS — JumpServer CE (bastion / PAM) — reach LXC/VM/workstation
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Open-source PAM (GPL-3.0): browser SSH/RDP/K8s to assets, Authentik OIDC SSO +
# MFA, credential vaulting, session recording, account-mapped least-privilege
# (admin-group→root account, users→limited). Docker-in-LXC. Consumes the shared
# cluster services (separation of concerns):
#   - Postgres → lxc-pgsql-01 (roles/postgres_db: jumpserver DB)
#   - Redis    → lxc-redis-01
#   - SSO      → Authentik (OIDC)
#   - Edge     → Traefik (VPN-only)  ·  Protect → CrowdSec agent
# Session recordings live on the root disk (sized larger); DB/Redis are external.
################################################################################

module "svc_jumpserver" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-jumpserver-01"
  vmid        = 571
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-bastion", "jumpserver", "pam", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 4
  memory             = 8192 # JumpServer core + koko + lion (RDP) + celery + nginx (external DB/Redis)
  disk_gb            = 60   # session recordings accumulate here
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.221/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::221/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = ["10.1.3.1", "fd01:3::1"] # OPNsense resolver on SVC VLAN
  ssh_keys    = local.standard_ssh_keys
}

output "svc_jumpserver" {
  description = "JumpServer CE bastion LXC (browser SSH/RDP to infra, Authentik SSO)"
  value = {
    name = "lxc-jumpserver-01"
    vmid = 571
    ipv4 = "10.1.3.221"
    ipv6 = "fd01:3::221"
    vlan = 1030
  }
}

################################################################################
# BY-SYSTEMS — CISO Assistant: the compliance registry (SVC zone)
# Node: srv-proxmox-poc-01 | env=prod | SVC VLAN 1030, 10.1.3.0/24
#
# ADR security/0002 names ciso-assistant-community as the authoritative compliance
# registry: framework catalogs (ISO 27001:2022, NIS2, GDPR), applied controls, and
# evidence linking back to the ADRs. It was decided but never deployed — this is the
# guest. Configured by ansible-platform roles/ciso_assistant: two containers
# (backend + frontend) and a task worker, the shared PostgreSQL cluster, evidence on
# SeaweedFS S3, Traefik + Authentik OIDC. Register in NetBox once up.
################################################################################
module "svc_grc" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-grc-01"
  vmid        = 545
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-compliance", "ciso-assistant", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 2
  memory             = 4096 # Django + SvelteKit + a Huey worker; framework imports are memory-hungry
  disk_gb            = 16   # evidence files live in S3, not on the guest
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.145/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::145/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_grc" {
  description = "CISO Assistant LXC — register in NetBox once up (security/0002 compliance registry)"
  value = {
    name = "lxc-grc-01"
    vmid = 545
    ipv4 = "10.1.3.145"
    ipv6 = "fd01:3::145"
    vlan = 1030
    fqdn = "lxc-grc-01.by-research.be"
  }
}

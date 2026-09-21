################################################################################
# BY-SYSTEMS — Traefik (HTTPS ingress / reverse proxy)
# Node: srv-proxmox-poc-01 | env=prod | DMZ zone (vlan1020, 10.1.2.0/24)
#
# Single Traefik LXC in the DMZ edge zone — the one reverse proxy fronting all
# internal cluster web UIs. Certs via ACME DNS-01 (Cloudflare) for the wildcard
# *.by-research.be (configured in the ansible role, not here). Public exposure
# later via the Contabo tunnel (#9); for now internal-only.
#
# VMID 500 (prod LXC range 500-999, infra/0004 §6). Static .110 in the dedicated
# mandatory-svc range .100-.199 (above the DHCP pool .50-.99), dual-stack.
################################################################################

module "svc_traefik" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-traefik-01"
  vmid        = 500
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1020", "zone-dmz", "role-ingress", "traefik"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 2 # every HTTPS request of the platform terminates here; 1 vCPU was the choke point (2026-09-21)
  memory             = 2048
  disk_gb            = 8
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1020
  ipv4_address   = "10.1.2.110/24"
  ipv4_gateway   = "10.1.2.1"
  ipv6_address   = "fd01:2::110/64"
  ipv6_gateway   = "fd01:2::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_direct # DMZ — firewall keeps it out of SVC, so AdGuard is unreachable from here
  ssh_keys    = local.standard_ssh_keys
}

output "svc_traefik" {
  description = "Traefik ingress LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-traefik-01"
    vmid = 500
    ipv4 = "10.1.2.110"
    ipv6 = "fd01:2::110"
    vlan = 1020
    fqdn = "lxc-traefik-01.by-research.be"
  }
}

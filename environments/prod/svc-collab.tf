################################################################################
# BY-SYSTEMS — Collaboration backend for Nextcloud (SVC zone): ONLYOFFICE Docs,
# Talk High-Performance Backend (signaling + Janus + TURN), Talk recording,
# Whiteboard server. Node: srv-proxmox-poc-01 | env=prod | SVC VLAN 1030.
#
# Docker-in-LXC (platform norm — like jitsi/harbor). One compose stack managed by
# ansible-platform roles/onlyoffice + roles/nextcloud_collab (#396 phase 2).
# Sized for Chrome-based recording + document conversion: 8 vCPU / 16 GiB / 40 GiB.
################################################################################

module "svc_collab" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-collab-01"
  vmid        = 509
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-collab", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 8
  memory             = 16384
  disk_gb            = 40
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.194/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::194/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_collab" {
  description = "Collab backend LXC — ONLYOFFICE + Talk HPB/coturn/recording + whiteboard (office.<domain>, talk backend via Traefik; coturn DNAT from WAN)"
  value = {
    name = "lxc-collab-01"
    vmid = 509
    ipv4 = "10.1.3.194"
    fqdn = "lxc-collab-01.by-research.be"
  }
}

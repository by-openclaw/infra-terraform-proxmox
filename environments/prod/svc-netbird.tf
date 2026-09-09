################################################################################
# BY-SYSTEMS — NetBird CE (self-hosted Zero-Trust VPN) — replaces Defguard (#45)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Nested LXC running the NetBird *server* stack as Docker containers (ansible:
# roles/docker + roles/netbird): management + signal + dashboard + relay +
# coturn (STUN/TURN). Authentik is the OIDC IdP (external SSO is free on the
# community edition — no netbird.io account). Fronted by Traefik (wildcard TLS,
# h2c for the gRPC backends). Uses the shared PostgreSQL as the management store.
#
# Server-side only → NO /dev/net/tun needed (that is the client/agent side), so
# this is a standard nested-Docker LXC like the other SVC services (unlike the
# old defguard VM, which needed tun for its userspace gateway). 20G disk holds
# the Docker images. Static .181 in the dedicated mandatory-svc range .100-.199,
# dual-stack. Mirrors svc-nextcloud.tf.
################################################################################

module "svc_netbird" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-netbird-01"
  vmid        = 504
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-vpn", "netbird", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 2
  memory             = 4096
  disk_gb            = 20
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.181/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::181/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_netbird" {
  description = "NetBird CE LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-netbird-01"
    vmid = 504
    ipv4 = "10.1.3.181"
    ipv6 = "fd01:3::181"
    vlan = 1030
    fqdn = "lxc-netbird-01.by-research.be"
  }
}

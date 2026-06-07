################################################################################
# BY-SYSTEMS — Defguard (WireGuard VPN + Authentik OIDC SSO + tunnel MFA)
# Node: srv-proxmox-poc-01 | env=prod | DMZ zone (vlan1020, 10.1.2.0/24)
#
# Nested LXC running Defguard (core + gateway + enrollment proxy) as Docker
# containers (ansible: roles/docker + roles/defguard). Web/enrollment UI fronted
# by Traefik (wildcard TLS, internal-only) at defguard.by-research.be. Uses the
# shared PostgreSQL (postgres_db: defguard) — Defguard core needs NO Redis.
# Login is via Authentik as the external OIDC provider; tunnel MFA enforced by
# the Defguard desktop client.
#
# WireGuard data plane: WAN udp/51820 (alias port_wg) port-forwarded to this LXC
# gateway. Because the WG endpoint is internet-exposed (exactly like Traefik's
# web port), Defguard lives in the DMZ edge zone and is published via the same
# paired dual-stack (v4+v6) firewall pattern as Traefik — clone, swapping the
# web port for the WireGuard port. CRITICAL: this is an UNPRIVILEGED + nesting
# LXC, so the gateway runs WireGuard in USERSPACE (wireguard-go / boringtun) — it
# must NOT depend on the PVE host kernel wireguard module (same class of failure
# as keyctl). See roles/defguard for the userspace env/flags actually set.
#
# nesting=true (module default) runs Docker in an unprivileged LXC. Static .120
# in the dedicated mandatory-svc range .100-.199, dual-stack. Mirrors
# svc-traefik.tf (DMZ tier). Sizing 2c/2048MB/20GB: data lives in shared PG, so
# the LXC only carries app code + the WG userspace data plane + enrollment state.
################################################################################

module "svc_defguard" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-defguard-01"
  vmid        = 550
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1020", "zone-dmz", "role-vpn", "defguard", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 2
  memory             = 2048
  disk_gb            = 20
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1020
  ipv4_address   = "10.1.2.120/24"
  ipv4_gateway   = "10.1.2.1"
  ipv6_address   = "fd01:2::120/64"
  ipv6_gateway   = "fd01:2::1"

  dns_domain  = local.svc_domain
  dns_servers = ["10.1.2.1", "fd01:2::1"] # OPNsense resolver on DMZ VLAN
  ssh_keys    = local.standard_ssh_keys
}

output "svc_defguard" {
  description = "Defguard LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-defguard-01"
    vmid = 550
    ipv4 = "10.1.2.120"
    ipv6 = "fd01:2::120"
    vlan = 1020
    fqdn = "lxc-defguard-01.by-research.be"
  }
}

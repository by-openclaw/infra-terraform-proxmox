################################################################################
# BY-SYSTEMS — CrowdSec (central LAPI / detection engine)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Dedicated CrowdSec central engine + Local API (LAPI). This is the platform's
# security brain (Decision A, services/0006): every other host — LXC, VM and
# Windows — runs a CrowdSec AGENT that ships parsed security events here, and a
# bouncer (OPNsense firewall bouncer at minimum) enforces the decisions. Runs the
# NATIVE crowdsec daemon (apt, not Docker) — ansible role `crowdsec`.
#
# Static .190 in the dedicated mandatory-svc range .100-.199 (above the DHCP
# pool), dual-stack. Mirrors svc-redis.tf (native-daemon LXC). The LAPI listens on
# the SVC IP so remote agents/bouncers can reach it (FW rules: agents -> :8080).
################################################################################

module "svc_crowdsec" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-crowdsec-01"
  vmid        = 535
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-ids", "crowdsec", "lapi"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 2
  memory             = 2048
  disk_gb            = 20
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.190/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::190/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_crowdsec" {
  description = "CrowdSec central LAPI/engine LXC — register in NetBox once up (services/0006 §1)"
  value = {
    name = "lxc-crowdsec-01"
    vmid = 535
    ipv4 = "10.1.3.190"
    ipv6 = "fd01:3::190"
    vlan = 1030
    fqdn = "lxc-crowdsec-01.by-research.be"
  }
}

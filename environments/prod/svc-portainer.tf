################################################################################
# BY-SYSTEMS — Portainer CE — the container console (SVC zone): one web UI for
# every Docker host (agent per host) and the k3s cluster (in-cluster agent).
# Node: srv-proxmox-poc-01 | env=prod | SVC VLAN 1030.
#
# Docker-in-LXC (platform norm — like jitsi/harbor). Its own guest on purpose (USER 2026-09-19:
# "must be separate of k3s"): managed by ansible-platform roles/portainer.
# A console holds no platform data: 2 vCPU / 2 GiB / 10 GiB.
################################################################################

module "svc_portainer" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-portainer-01"
  vmid        = 511
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-portainer", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 2
  memory             = 2048
  disk_gb            = 10
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.196/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::196/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_portainer" {
  description = "Portainer LXC — container console for the Docker hosts and the k3s cluster (portainer.<domain>, internal + SSO)"
  value = {
    name = "lxc-portainer-01"
    vmid = 511
    ipv4 = "10.1.3.196"
    fqdn = "lxc-portainer-01.by-research.be"
  }
}

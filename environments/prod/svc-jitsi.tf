################################################################################
# BY-SYSTEMS — Jitsi Meet: self-hosted video conferencing (SVC zone)
# Node: srv-proxmox-poc-01 | env=prod | SVC VLAN 1030, 10.1.3.0/24
#
# Docker-in-LXC (platform norm — like verdaccio/harbor), NOT a VM: LXCs share the
# host kernel and avoid the old-Xeon cold-clone VM boot flake. Official
# jitsi/docker-jitsi-meet stack configured by ansible-platform roles/jitsi (via
# service_scaffold). Web/HTTPS behind Traefik; JVB media UDP 10000 DNAT from WAN.
################################################################################
module "svc_jitsi" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-jitsi-01"
  vmid        = 508
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-jitsi", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 4
  memory             = 4096
  disk_gb            = 20
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.193/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::193/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = ["10.1.3.1", "fd01:3::1"]
  ssh_keys    = local.standard_ssh_keys
}

output "svc_jitsi" {
  description = "Jitsi Meet LXC — web via Traefik (meet.by-research.be); JVB UDP 10000 DNAT from WAN"
  value = {
    name = "lxc-jitsi-01"
    vmid = 508
    ipv4 = "10.1.3.193"
    fqdn = "lxc-jitsi-01.by-research.be"
  }
}

################################################################################
# BY-SYSTEMS — step-ca: internal certificate authority (ACME + step API) (SVC zone)
# Node: srv-proxmox-poc-01 | env=prod | SVC VLAN 1030, 10.1.3.0/24
#
# Internal CA (smallstep). Root/intermediate custodied in Vault; ACME + JWK
# provisioners for internal certs and future 802.1X device certs. Configured by ansible-platform roles/verdaccio
# (via service_scaffold). Register in NetBox once up.
################################################################################
module "svc_stepca" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-stepca-01"
  vmid        = 506
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-pki", "step-ca", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 1
  memory             = 1024
  disk_gb            = 8
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.192/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::192/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = ["10.1.3.1", "fd01:3::1"]
  ssh_keys    = local.standard_ssh_keys
}

output "svc_stepca" {
  description = "Verdaccio LXC — register in NetBox once up (security/0001 PKI)"
  value = {
    name = "lxc-stepca-01"
    vmid = 505
    ipv4 = "10.1.3.192"
    ipv6 = "fd01:3::192"
    vlan = 1030
    fqdn = "lxc-stepca-01.by-research.be"
  }
}

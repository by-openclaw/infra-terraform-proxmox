################################################################################
# BY-SYSTEMS — Jitsi Meet: self-hosted video conferencing (SVC zone)
# Node: srv-proxmox-poc-01 | env=prod | SVC VLAN 1030, 10.1.3.0/24
#
# Official multi-container stack (jitsi/docker-jitsi-meet: web, prosody, jicofo,
# jvb) configured by ansible-platform roles/jitsi (via service_scaffold). Web/HTTPS
# behind Traefik; JVB media = UDP 10000 DNAT'd from WAN so external participants
# connect. VM (not LXC): JVB media performance + UDP. Register in NetBox once up.
################################################################################
module "vm_jitsi_01" {
  source = "../../modules/vm-linux"

  name        = "vm-jitsi-01"
  vmid        = 507
  target_node = local.svc_node
  env         = "prod"
  tags        = ["service", "vlan1030", "zone-svc", "role-jitsi", "docker"]

  clone     = "debian-12-cloud"
  cores     = 4
  cpu_type  = "x86-64-v2-AES" # host-passthrough panics this Xeon E5-2640 v0 multi-core; v2-AES is safe
  memory    = 6144
  disk_size = "25G"
  storage   = "poc-data"

  network_bridge = local.svc_bridge
  vlan_id        = 1030
  ip             = "10.1.3.193/24"
  gateway        = "10.1.3.1"
  ipv6_address   = "fd01:3::193/64"
  ipv6_gateway   = "fd01:3::1"

  domain          = local.svc_domain
  dns_servers     = ["10.1.3.1", "fd01:3::1"]
  ssh_keys        = local.standard_ssh_keys
  use_vendor_data = false
}

output "vm_jitsi_01" {
  description = "Jitsi Meet VM — web via Traefik (meet.by-research.be); JVB UDP 10000 DNAT from WAN"
  value = {
    name = module.vm_jitsi_01.vm_name
    id   = module.vm_jitsi_01.vm_id
    ipv4 = "10.1.3.193"
    fqdn = "vm-jitsi-01.by-research.be"
  }
}

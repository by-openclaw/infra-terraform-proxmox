# ==============================================================================
# vm-k3s-01 — single-node k3s: the application platform (apps published from
# GitLab CI; platform Traefik → k3s ingress). SVC zone (vlan1030, 10.1.3.0/24).
# Node: srv-proxmox-poc-01 | env=prod | PROD service VM (debian-12-cloud).
# A VM, not an LXC: containerd + cgroups + kernel modules need a real kernel.
# ==============================================================================
module "vm_k3s_01" {
  source = "../../modules/vm-linux"

  name        = "vm-k3s-01"
  vmid        = 104
  target_node = "srv-proxmox-poc-01"
  env         = "prod"
  tags        = ["service", "vlan1030", "zone-svc", "role-k3s"]

  clone     = "debian-12-cloud" # template VMID 9000
  cores     = 4
  memory    = 8192
  disk_size = "60G"
  storage   = "poc-data"

  network_bridge = "vmbrAPPS"
  vlan_id        = 1030
  ip             = "10.1.3.195/24"
  gateway        = "10.1.3.1"
  ipv6_address   = "fd01:3::195/64"
  ipv6_gateway   = "fd01:3::1"

  dns_servers     = local.dns_filtered
  ssh_keys        = local.standard_ssh_keys
  use_vendor_data = false
}

output "vm_k3s_01" {
  description = "PROD k3s VM — application platform behind the platform Traefik"
  value = {
    name = module.vm_k3s_01.vm_name
    id   = module.vm_k3s_01.vm_id
  }
}

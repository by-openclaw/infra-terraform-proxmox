# Windows Server 2025 Standard (GUI) — cloned from tpl-ws2025-std-gui (vmid 9100,
# built by ansible-platform roles/windows_template). Owner's sizing 2026-10-13:
# 2 app hosts + 1 SQL Express host, 6 vCPU / 32 GiB each, ballooning off, each VM
# pinned to its own host NUMA node (node 3 + leftovers stay free for Linux guests).
#
#   vm-winapp-01 → host NUMA node 0 (cores 0-5)
#   vm-winapp-02 → host NUMA node 1 (cores 6-11)
#   vm-winsql-01 → host NUMA node 2 (cores 12-17)

module "vm_winapp_01" {
  source = "../../modules/vm-windows"

  name        = "vm-winapp-01"
  target_node = local.node
  clone       = "tpl-ws2025-std-gui"
  vmid        = 201
  env         = local.env
  tags        = ["app"]

  cores         = 6
  cpu_affinity  = "0-5"
  numa_hostnode = "0"
  memory        = 32768

  storage        = local.storage
  disk_size      = "120G"
  network_bridge = local.bridge

  ip          = "10.6.239.201/20"
  gateway     = local.gateway
  dns_servers = local.dns
  domain      = local.svc_domain
  ssh_keys    = local.standard_ssh_keys
}

module "vm_winapp_02" {
  source = "../../modules/vm-windows"

  name        = "vm-winapp-02"
  target_node = local.node
  clone       = "tpl-ws2025-std-gui"
  vmid        = 202
  env         = local.env
  tags        = ["app"]

  cores         = 6
  cpu_affinity  = "6-11"
  numa_hostnode = "1"
  memory        = 32768

  storage        = local.storage
  disk_size      = "120G"
  network_bridge = local.bridge

  ip          = "10.6.239.202/20"
  gateway     = local.gateway
  dns_servers = local.dns
  domain      = local.svc_domain
  ssh_keys    = local.standard_ssh_keys
}

module "vm_winsql_01" {
  source = "../../modules/vm-windows"

  name        = "vm-winsql-01"
  target_node = local.node
  clone       = "tpl-ws2025-std-gui"
  vmid        = 203
  env         = local.env
  tags        = ["sql"]

  cores         = 6
  cpu_affinity  = "12-17"
  numa_hostnode = "2"
  memory        = 32768

  storage        = local.storage
  disk_size      = "150G" # SQL Express data under C: for now; its 10 GB/db cap keeps this honest
  network_bridge = local.bridge

  ip          = "10.6.239.203/20"
  gateway     = local.gateway
  dns_servers = local.dns
  domain      = local.svc_domain
  ssh_keys    = local.standard_ssh_keys
}

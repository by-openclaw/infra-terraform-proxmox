################################################################################
# BY-SYSTEMS — PROD AdGuard Home (DNS filter front-end of the chain)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Promotes AdGuard from test (vm-adguard-test-01 / 1101) to prod. Same module
# (vm-linux) and shape as the test VM, retargeted to the prod SVC segment.
#
# DNS chain (prod):
#   clients → vm-adguard-01:53 → vm-opns-01 Unbound → dnscrypt-proxy → upstream
#
# VMID 101 (prod VM range 100-499, infra/0004 §5; FW=100, this is the first
# prod service VM). Host octet .101 mirrors the test AdGuard for muscle memory.
#
# NOTE: apply AFTER the prod SDN VNet `svc` (vlan1030) exists and the FW DNS
# chain (Unbound→dnscrypt) is live, so AdGuard has a working upstream resolver.
# Decommission vm-adguard-test-01 (1101) together with test FW 199.
################################################################################

module "vm_adguard_01" {
  source = "../../modules/vm-linux"

  name        = "vm-adguard-01"
  vmid        = 101
  target_node = "srv-proxmox-poc-01"
  env         = "prod"
  tags        = ["service", "vlan1030", "zone-svc", "role-adguard"]

  clone = "debian-12-cloud" # template VMID 9000 (per repo CLAUDE.md)
  cores = 1
  # 2 GiB: AdGuard moves into a container (ansible-platform) — the Docker engine plus the
  # cadvisor + portainer agents every Docker host runs need ~200 MB; at 1 GiB the VM had
  # 270 MB available and no swap (measured 2026-10-01).
  memory             = 2048
  disk_size          = "20G"
  data_disk_size_gib = 8 # Docker data root (roles/docker_data): 1.7 GB measured 2026-10-31
  storage            = "poc-data"

  network_bridge = "vmbrAPPS"
  vlan_id        = 1030
  ip             = "10.1.3.101/24"
  gateway        = "10.1.3.1"
  ipv6_address   = "fd01:3::101/64"
  ipv6_gateway   = "fd01:3::1"

  domain      = "by-research.be"
  dns_servers = local.dns_direct # AdGuard itself — must not resolve through itself
  ssh_keys    = local.standard_ssh_keys

  # PVE node SSH for snippets upload is unavailable (Known Blocker: SSH key for
  # Rune VM → node). Bare-bones cloud-init (IP + ssh-key + hostname) applies via
  # the initialization block; AdGuardHome installed by post-create bootstrap.
  use_vendor_data = false
}

output "vm_adguard_01" {
  description = "PROD AdGuard Home VM — admin UI on :3000, DNS on :53"
  value = {
    name = module.vm_adguard_01.vm_name
    id   = module.vm_adguard_01.vm_id
  }
}

################################################################################
# Second resolver instance (ADR infra/0011 — two AdGuard Home instances behind one
# VRRP address, accepted by the owner 2026-10-27). Same shape as vm-adguard-01, rendered
# by the same ansible-platform roles from the same inventory. VMID 105 (101–104 taken),
# host octet .105 mirrors the VMID like .101 does. Both instances sit on
# srv-proxmox-poc-01 until br-pmox-03 is back (ADR §3); the virtual address the guests use
# (10.1.3.100 / fd01:3::100) is owned by keepalived on whichever instance is alive and is
# declared in ansible-platform (platform_resolver_vip4/6), not here.
################################################################################
module "vm_adguard_02" {
  source             = "../../modules/vm-linux"
  name               = "vm-adguard-02"
  vmid               = 105
  target_node        = "srv-proxmox-poc-01"
  env                = "prod"
  tags               = ["service", "vlan1030", "zone-svc", "role-adguard"]
  clone              = "debian-12-cloud"
  cores              = 1
  memory             = 2048
  disk_size          = "20G"
  data_disk_size_gib = 8 # Docker data root (roles/docker_data): 1.7 GB measured 2026-10-31
  storage            = "poc-data"
  network_bridge     = "vmbrAPPS"
  vlan_id            = 1030
  ip                 = "10.1.3.105/24"
  gateway            = "10.1.3.1"
  ipv6_address       = "fd01:3::105/64"
  ipv6_gateway       = "fd01:3::1"
  domain             = "by-research.be"
  dns_servers        = local.dns_direct # a resolver must not resolve through itself
  ssh_keys           = local.standard_ssh_keys
  use_vendor_data    = false
}
output "vm_adguard_02" {
  description = "PROD AdGuard Home VM #2 — second instance of the resolver tier (ADR infra/0011)"
  value = {
    name = module.vm_adguard_02.vm_name
    id   = module.vm_adguard_02.vm_id
  }
}

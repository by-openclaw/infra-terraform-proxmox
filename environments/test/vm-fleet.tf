################################################################################
# BY-SYSTEMS — Test VM Fleet (QEMU/KVM)
#
# Started with the AdGuard Home service VM (Phase 2 of the DNS chain).
# Use VMs over LXCs for services that need bootstrap install: QEMU VMs ship
# with qemu-guest-agent in the cloud-init image, giving us programmatic shell
# via `qm guest exec` from PVE API — LXCs have no equivalent.
#
# Module: vm-linux (cloud-init via Proxmox cloud-init disk, dual-stack, vlan).
# Template: debian-12-cloud (VMID 9000) — pre-existing per CLAUDE.md.
# VMID range: 1100-1499 (test VM range per infra/0004 §5; 1100 = fw_test_01).
################################################################################

# AdGuard Home — DNS filter front-end of the chain
# clients → vm-adguard:53 → vm-opns-test-01 Unbound (53530 post-cutover) → dnscrypt → upstream
module "vm_adguard_test_01" {
  source = "../../modules/vm-linux"

  name        = "vm-adguard-test-01"
  vmid        = 1101
  target_node = local.test_node
  env         = "test"
  tags        = ["service", "vlan2030", "zone-svc", "role-adguard"]

  clone     = "debian-12-cloud"  # template VMID 9000 (per repo CLAUDE.md)
  cores     = 1
  memory    = 1024
  disk_size = "5G"
  storage   = "poc-data"

  network_bridge = local.test_bridge
  vlan_id        = 2030
  ip             = "10.11.3.101/24"
  gateway        = "10.11.3.1"
  ipv6_address   = "fd11:3::101/64"
  ipv6_gateway   = "fd11:3::1"

  domain      = local.test_domain
  dns_servers = local.dns_svc
  ssh_keys    = local.standard_ssh_keys

  # PVE node SSH for snippets upload is unavailable (see CLAUDE.md Known Blocker
  # "SSH key for Rune VM → node"). Bare-bones cloud-init (IP + ssh-key + hostname)
  # still applies via the initialization block; locale/sudo/packages handled by
  # post-create /opt/AdGuardHome bootstrap.
  use_vendor_data = false
}

output "vm_adguard" {
  description = "AdGuard Home VM details — admin UI on :3000, DNS on :53"
  value = {
    name = module.vm_adguard_test_01.vm_name
    id   = module.vm_adguard_test_01.vm_id
    ipv4 = module.vm_adguard_test_01.ip_address
    vlan = 2030
  }
}

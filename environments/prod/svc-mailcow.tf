################################################################################
# BY-SYSTEMS — PROD mailcow mail server (dedicated VM)
# Node: srv-proxmox-poc-01 | env=prod | DMZ zone (vlan1020, 10.1.2.0/24)
#
# mailcow is officially UNSUPPORTED in LXC (dockerized stack needs a full kernel)
# → dedicated VM. Placed in the DMZ (like Traefik) because it accepts inbound
# SMTP from the internet. Mail uses the Telenet STATIC WAN only (stable MX/PTR);
# the secured port-forwards + the `host_mail_relay` alias live in the OPNsense
# catalog (ansible-platform), NOT here.
#
# VMID 102 (prod VM range; 100=FW not TF-managed, 101=AdGuard, LXCs=500+).
# Root 60G holds OS + Docker + the mailcow images/DBs; `vmail` is a SEPARATE
# Synology NAS-NFS mount (mounted + tuned by Ansible), so mailboxes are elastic
# and snapshotted off the VM disk.
#
# This provisions the VM only — Docker + the mailcow stack + Authentik OIDC +
# 5 GB default quota are installed/configured by the ansible-platform mailcow
# role. use_vendor_data=false (node-SSH snippet upload is blocked) → bare
# cloud-init (IP + ssh-key + hostname); Ansible bootstraps the rest.
################################################################################

module "vm_mailcow_01" {
  source = "../../modules/vm-linux"

  name        = "vm-mailcow-01"
  vmid        = 102
  target_node = "srv-proxmox-poc-01"
  env         = "prod"
  tags        = ["service", "vlan1020", "zone-dmz", "role-mailcow"]

  clone     = "debian-12-cloud" # template VMID 9000
  cores     = 4
  cpu_type  = "x86-64-v2-AES" # NOT "host": host-passthrough on this Sandy Bridge Xeon E5-2640 v0 panics the multi-core Debian-12 guest ("Attempted to kill init"). v2-AES is fully supported here (SSE4.2/POPCNT/AES-NI) and migration-safe; v3 is N/A (no AVX2).
  memory    = 8192            # mailcow needs >=6 GB; 8 GB for rspamd/clamav headroom
  disk_size = "60G"
  storage   = "poc-data"

  network_bridge = "vmbrAPPS"
  vlan_id        = 1020
  ip             = "10.1.2.120/24"
  gateway        = "10.1.2.1"
  ipv6_address   = "fd01:2::120/64"
  ipv6_gateway   = "fd01:2::1"

  domain      = "by-research.be"
  dns_servers = ["10.1.2.1", "fd01:2::1"] # FW DMZ gateway (Unbound chain)
  ssh_keys    = local.standard_ssh_keys

  use_vendor_data = false
}

output "vm_mailcow_01" {
  description = "PROD mailcow VM — web UI via Traefik; mail bound to the Telenet WAN"
  value = {
    name = module.vm_mailcow_01.vm_name
    id   = module.vm_mailcow_01.vm_id
  }
}

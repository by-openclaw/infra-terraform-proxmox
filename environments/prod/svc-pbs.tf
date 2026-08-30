################################################################################
# BY-SYSTEMS — Proxmox Backup Server v4 (dedup/incremental/verify → S3)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# SECOND, INDEPENDENT backup copy alongside the existing vzdump -> NFS (Synology,
# PVE storage `poc-backup`). That NFS job STAYS ENABLED — PBS does not replace it.
# PVE also backs up to this PBS, whose datastore is the SeaweedFS S3 bucket
# (PBS 4 S3 backend), so every guest lands on BOTH Synology (NFS) and SeaweedFS
# (S3) — surviving a Synology failure. NFS remains the reliable primary, so the
# PBS-4 S3 datastore being a tech-preview is acceptable here (redundant copy).
#
# PBS 4 requires Debian 13 -> clones the debian-13-cloud template (VMID 9001,
# qemu-guest-agent baked in, mirrors 9000). VMID 103 (prod VM range:
# 100=FW, 101=AdGuard, 102=mailcow, 103=PBS; LXCs are 500+).
#
# Minimal footprint by design: the bulk backup DATA lives in S3, so this root
# disk only holds the OS + PBS + the S3 datastore local cache/metadata.
#
# Provisions the VM ONLY. The PBS install (proxmox-backup-server), the SeaweedFS
# S3 datastore, the Authentik OIDC realm, the Traefik edge, CrowdSec, the PVE
# storage wiring + the PBS backup job are all done by the ansible-platform `pbs`
# role. use_vendor_data=false (API-token provider, no node-SSH for snippets) —
# bare cloud-init (IP + ssh-key + hostname); Ansible bootstraps the rest.
################################################################################

module "vm_pbs_01" {
  source = "../../modules/vm-linux"

  name        = "vm-pbs-01"
  vmid        = 103
  target_node = local.svc_node
  env         = "prod"
  tags        = ["service", "vlan1030", "zone-svc", "role-backup", "pbs"]

  clone     = "debian-13-cloud" # template VMID 9001 (PBS 4 = Debian 13)
  cores     = 2
  cpu_type  = "x86-64-v2-AES" # NOT "host": host-passthrough panics multi-core Debian on this Sandy Bridge Xeon E5-2640 v0 (see vm-mailcow-01). v2-AES is supported + migration-safe; v3 N/A (no AVX2).
  memory    = 4096            # PBS baseline; bump if verify/GC needs headroom
  disk_size = "40G"           # OS + PBS + S3 datastore local cache/metadata — bulk backup data is in S3
  storage   = "poc-data"

  network_bridge = local.svc_bridge # vmbrAPPS
  vlan_id        = 1030
  ip             = "10.1.3.222/24" # .200=seaweedfs .210=gitlab .220=diagrams .221=jumpserver -> .222=pbs
  gateway        = "10.1.3.1"
  ipv6_address   = "fd01:3::222/64"
  ipv6_gateway   = "fd01:3::1"

  domain      = local.svc_domain          # by-research.be
  dns_servers = ["10.1.3.1", "fd01:3::1"] # OPNsense resolver on the SVC VLAN
  ssh_keys    = local.standard_ssh_keys

  use_vendor_data = false
}

output "vm_pbs_01" {
  description = "Proxmox Backup Server v4 VM — UI :8007 via Traefik; datastore = SeaweedFS S3; 2nd copy alongside NFS"
  value = {
    name = module.vm_pbs_01.vm_name
    id   = module.vm_pbs_01.vm_id
    ipv4 = "10.1.3.222"
    ipv6 = "fd01:3::222"
    vlan = 1030
  }
}

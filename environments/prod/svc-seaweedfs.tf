################################################################################
# BY-SYSTEMS — SeaweedFS (local S3 object storage — fabric fast tier)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Replaces MinIO (community MinIO server+mc archived/EOL 2026 — no security
# patches). SeaweedFS is Apache-2.0, actively maintained, S3-compatible: local S3
# for GitLab (CI artifacts, LFS, container registry), backup staging, and any app
# needing in-house object storage. Complements the Synology NAS (backup) and
# Contabo S3 (offsite). Native binary + systemd (no nested Docker). S3 API behind
# Traefik; access via S3 access keys (no SSO — backend infra, like Postgres/Redis).
#
# STORAGE MODEL (deliberate): this LXC has ONLY a small disposable root here.
# The S3 DATA lives on a standalone ZFS dataset `tank/data/seaweedfs` created and
# bind-mounted at /data by ANSIBLE (roles/seaweedfs + the pve_zfs_dataset play).
# So `terraform destroy` of this LXC leaves the data intact — Proxmox only deletes
# its own subvol-<vmid> volumes, never bind-mount targets. Reinstall = re-attach.
################################################################################

module "svc_seaweedfs" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-seaweedfs-01"
  vmid        = 550
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-storage", "seaweedfs", "s3"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 2
  # 4096: the 2048 limit OOM-killed weed TWICE during the nightly PBS->S3 backup
  # burst (Aug 30 + Sep 1 01:35, systemd oom-kill; 10 LXC backups 502'd until the
  # auto-restart). Raised live via pct set 2026-09-01; codified here.
  memory  = 4096
  disk_gb = 12 # OS + weed binary ONLY — S3 data is the Ansible ZFS bind-mount at /data
  storage = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.200/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::200/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_seaweedfs" {
  description = "SeaweedFS LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-seaweedfs-01"
    vmid = 550
    ipv4 = "10.1.3.200"
    ipv6 = "fd01:3::200"
    vlan = 1030
  }
}

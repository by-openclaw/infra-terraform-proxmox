################################################################################
# BY-SYSTEMS — GitLab CE (self-hosted SCM + CI/CD + registry — fabric)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# GitLab Community Edition via the official Omnibus package (runit-managed, NO
# nested Docker). Bundled Postgres / Redis / object-storage are DISABLED — GitLab
# consumes the CLUSTER services (separation of concerns):
#   - Postgres  → lxc-pgsql-01     10.1.3.110   (roles/postgres_db: gitlabhq_production)
#   - Redis     → lxc-redis-01     10.1.3.117
#   - S3        → lxc-seaweedfs-01 10.1.3.200   (roles/seaweedfs_bucket: gitlab-* buckets)
#   - SSO       → Authentik (OIDC, login free; group→role via Ansible reconcile)
#   - Email     → mailcow (SMTP submission)
#   - Edge      → Traefik (gitlab / registry / *.pages, LE wildcard, VPN-only)
#   - Protect   → CrowdSec agent
#
# STORAGE MODEL (deliberate, same as SeaweedFS): this LXC has ONLY a small
# disposable root here. The GIT REPOSITORIES (Gitaly, stateful, NOT S3-able) live
# on a standalone ZFS dataset `tank/data/gitlab` created + bind-mounted at
# /var/opt/gitlab/git-data by ANSIBLE (roles/pve_zfs_mount + the gitlab.yml play).
# So `terraform destroy` of this LXC leaves the repos intact — Proxmox only deletes
# its own subvol-<vmid> volumes, never bind-mount targets. Reinstall = re-attach.
# S3-backed assets (artifacts, LFS, uploads, packages, registry, pages) live in
# SeaweedFS; DB in Postgres — both external, so root stays disposable.
#
# RUNNERS are separate (CI = untrusted → VM isolation): svc-gitlab-runner.tf
# (phase 2). This file is the GitLab SERVER only.
################################################################################

module "svc_gitlab" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-gitlab-01"
  vmid        = 560
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-scm", "gitlab", "ci"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  # Omnibus (Puma + Sidekiq + Gitaly + registry + workhorse + nginx) with external
  # PG/Redis/S3 → 4 cores / 8 GB is the small-team baseline (GitLab docs: 8 GB up
  # to ~500 users; 4 GB swaps). Scale here, not in the role.
  cores   = 4
  memory  = 8192
  disk_gb = 20 # Omnibus package + /var/log + config ONLY — git repos are the ZFS bind-mount, assets are S3
  storage = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.210/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::210/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = ["10.1.3.1", "fd01:3::1"] # OPNsense resolver on SVC VLAN
  ssh_keys    = local.standard_ssh_keys
}

output "svc_gitlab" {
  description = "GitLab CE LXC — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-gitlab-01"
    vmid = 560
    ipv4 = "10.1.3.210"
    ipv6 = "fd01:3::210"
    vlan = 1030
  }
}

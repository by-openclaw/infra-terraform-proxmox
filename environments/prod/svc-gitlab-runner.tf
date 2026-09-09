################################################################################
# BY-SYSTEMS — GitLab CI Runner (Linux, Docker executor + Kaniko) — fabric
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# CI runs UNTRUSTED code → VM-level isolation (a VM, NOT an LXC), per the platform
# decision. Docker executor: each job runs in a clean container; images are built
# with Kaniko (rootless, no privileged daemon) and pushed to the GitLab registry.
# Registers to lxc-gitlab-01 with an authentication token (GitLab 17+ model).
#
# One VM per profile: this is the LINUX lane. The WINDOWS lane reuses the existing
# Win11 VM (vmid 654). A privileged docker-in-docker lane is added only if a job
# ever needs a live Docker daemon (compose/Testcontainers) — none does today.
################################################################################

module "vm_gitlab_runner_01" {
  source = "../../modules/vm-linux"

  name        = "vm-gitlab-runner-01"
  vmid        = 561
  target_node = "srv-proxmox-poc-01"
  env         = "prod"
  tags        = ["service", "vlan1030", "zone-svc", "role-ci-runner", "gitlab-runner"]

  clone     = "debian-12-cloud" # template VMID 9000 (same as mailcow)
  cores     = 4
  cpu_type  = "x86-64-v2-AES" # host-passthrough panics multi-core Debian on this Sandy Bridge Xeon (see mailcow)
  memory    = 8192            # CI builds + Docker layer cache
  disk_size = "40G"           # Docker images + build cache; jobs are ephemeral
  storage   = "poc-data"

  network_bridge = "vmbrAPPS"
  vlan_id        = 1030
  ip             = "10.1.3.211/24"
  gateway        = "10.1.3.1"
  ipv6_address   = "fd01:3::211/64"
  ipv6_gateway   = "fd01:3::1"

  domain      = "by-research.be"
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys

  # No vendor_data snippet: like every other VM here, this uses native cloud-init
  # (user/keys/network via the API). Guest hardening — panic=10 auto-reboot,
  # persistent journald — is done by the gitlab_runner Ansible role (Terraform
  # provisions, Ansible configures). Enabling vendor_data would require the bpg
  # provider to SSH the node for snippet upload (see providers ssh node-name note).
  use_vendor_data = false
}

output "vm_gitlab_runner_01" {
  description = "GitLab CI runner VM (Linux + Docker + Kaniko) — register to lxc-gitlab-01"
  value = {
    name = module.vm_gitlab_runner_01.vm_name
    id   = module.vm_gitlab_runner_01.vm_id
    ipv4 = "10.1.3.211"
  }
}

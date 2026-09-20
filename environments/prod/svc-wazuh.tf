################################################################################
# BY-SYSTEMS — Wazuh — security monitoring (SVC zone): manager, indexer and dashboard on one guest,
# an agent on every guest (FIM, log analysis, vulnerability detection; NIS2 Art. 21).
# Node: srv-proxmox-poc-01 | env=prod | SVC VLAN 1030.
#
# Docker-in-LXC (platform norm). The indexer (OpenSearch) needs vm.max_map_count >= 262144:
# the node sets 1048576 and containers inherit it. Managed by ansible-platform roles/wazuh.
# Indexer + manager: 4 vCPU / 8 GiB / 40 GiB (indexer data on the guest disk, PBS class A).
################################################################################

module "svc_wazuh" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-wazuh-01"
  vmid        = 512
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-wazuh", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 4
  memory             = 8192
  disk_gb            = 40
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.197/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::197/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = local.dns_filtered # AdGuard first (filtered + logged), firewall as fallback
  ssh_keys    = local.standard_ssh_keys
}

output "svc_wazuh" {
  description = "Wazuh LXC — security monitoring: manager + indexer + dashboard (wazuh.<domain>, internal + SSO); agents on every guest"
  value = {
    name = "lxc-wazuh-01"
    vmid = 512
    ipv4 = "10.1.3.197"
    fqdn = "lxc-wazuh-01.by-research.be"
  }
}

################################################################################
# BY-SYSTEMS — Shared platform DB/cache cluster + NetBox (LXC fleet)
#
# Implements:
#   - services/0004-database-strategy: Patroni PostgreSQL (3) + etcd DCS (3) +
#     Redis (2) + Sentinel (3, colocated on redis + 1 standalone) + pooler.
#   - services/0003-netbox-cmdb: NetBox (vm-/lxc-nbox-01) consuming the SHARED
#     cluster (database `netbox`), role=cmdb.
#
# Prefer-LXC (feedback_prefer_lxc_over_vm): all nodes are LXCs — plain Linux
# services, no kernel/VM need. Template = debian-13-standard (ships sshd);
# access via the rune SSH key (feedback_credentials_rune_ssh_and_secret_folder).
#
# Placement = PROD SVC segment per infra/0004-network-architecture §3:
#   VLAN 1030 · 10.1.3.0/24 · fd01:3::/64 · gw 10.1.3.1 / fd01:3::1
# Prod LXC VMID range 500-999 (infra/0004 §6). Hostnames carry NO env
# (naming/0001 §7/§10) — env lives in the NetBox `env` field + DNS zone; prod
# zone is clean → FQDN `{host}.by-research.be`.
#
# NOTE — NetBox self-registration (services/0003 §1): every LXC created here,
# plus lxc-nbox-01 itself (role=cmdb), its IPs, and the SVC prefix/VLAN, MUST be
# registered IN NetBox once NetBox is up (Phase D — terraform-provider-netbox +
# load script). Creating the shell is not the end state.
#
# Apply prerequisite: the prod SDN zone + VLAN 1030 must be live on Proxmox and
# routed by the FW before these LXCs are reachable (FW/VLAN/Proxmox setup).
################################################################################

locals {
  cl_node   = "srv-proxmox-poc-01"
  cl_bridge = "vmbrAPPS"
  cl_domain = "by-research.be"          # prod zone — clean, no env sub-domain (naming/0001 §7)
  cl_dns    = ["10.1.3.1", "fd01:3::1"] # OPNsense is the only resolver (infra/0004 §6)
  cl_gw4    = "10.1.3.1"
  cl_gw6    = "fd01:3::1"

  # host = last octet (v4) and hextet label (v6) on 10.1.3.x / fd01:3::x
  cluster_lxc = {
    "lxc-pgsql-01"    = { vmid = 510, host = 10, cores = 2, mem = 2048, disk = 30, tags = ["role-db", "patroni"] }
    "lxc-pgsql-02"    = { vmid = 511, host = 11, cores = 2, mem = 2048, disk = 30, tags = ["role-db", "patroni"] }
    "lxc-pgsql-03"    = { vmid = 512, host = 12, cores = 2, mem = 2048, disk = 30, tags = ["role-db", "patroni"] }
    "lxc-pgpool-01"   = { vmid = 513, host = 13, cores = 1, mem = 512, disk = 4, tags = ["role-db", "pooler"] }
    "lxc-etcd-01"     = { vmid = 514, host = 14, cores = 1, mem = 512, disk = 4, tags = ["role-db", "etcd"] }
    "lxc-etcd-02"     = { vmid = 515, host = 15, cores = 1, mem = 512, disk = 4, tags = ["role-db", "etcd"] }
    "lxc-etcd-03"     = { vmid = 516, host = 16, cores = 1, mem = 512, disk = 4, tags = ["role-db", "etcd"] }
    "lxc-redis-01"    = { vmid = 517, host = 17, cores = 1, mem = 1024, disk = 8, tags = ["role-cache", "redis", "sentinel"] }
    "lxc-redis-02"    = { vmid = 518, host = 18, cores = 1, mem = 1024, disk = 8, tags = ["role-cache", "redis", "sentinel"] }
    "lxc-sentinel-01" = { vmid = 519, host = 19, cores = 1, mem = 256, disk = 4, tags = ["role-cache", "sentinel"] }
    "lxc-nbox-01"     = { vmid = 520, host = 20, cores = 2, mem = 4096, disk = 30, tags = ["role-cmdb", "netbox"] }
  }
}

# Proxmox-standard Debian 13 LXC template (ships openssh-server).
resource "proxmox_virtual_environment_download_file" "tmpl_debian_13" {
  content_type        = "vztmpl"
  datastore_id        = "poc-iso"
  node_name           = local.cl_node
  url                 = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
  file_name           = "debian-13-standard_13.1-2_amd64.tar.zst"
  overwrite           = false
  overwrite_unmanaged = true
}

module "db_cluster" {
  source   = "../../modules/lxc-cloudinit"
  for_each = local.cluster_lxc

  name        = each.key
  vmid        = each.value.vmid
  target_node = local.cl_node
  env         = "prod"
  os_type     = "debian"
  tags        = concat(["service", "vlan1030", "zone-svc"], each.value.tags)

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = each.value.cores
  memory             = each.value.mem
  disk_gb            = each.value.disk
  storage            = "poc-data"

  network_bridge = local.cl_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.${each.value.host}/24"
  ipv4_gateway   = local.cl_gw4
  ipv6_address   = "fd01:3::${each.value.host}/64"
  ipv6_gateway   = local.cl_gw6

  dns_domain  = local.cl_domain
  dns_servers = local.cl_dns
  ssh_keys    = local.standard_ssh_keys # rune key + ref ws (prod locals in main.tf)
  # features defaults to nesting=true (systemd 255+ on Debian 13; also enables
  # Docker-NetBox on lxc-nbox-01 if chosen at the Ansible stage).
}

output "db_cluster" {
  description = "Shared DB/cache cluster + NetBox LXCs — register every entry in NetBox (services/0003 §1)"
  value = {
    for k, m in module.db_cluster : k => {
      vmid = local.cluster_lxc[k].vmid
      ipv4 = "10.1.3.${local.cluster_lxc[k].host}"
      ipv6 = "fd01:3::${local.cluster_lxc[k].host}"
      fqdn = "${k}.by-research.be"
    }
  }
}

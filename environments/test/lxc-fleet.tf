################################################################################
# BY-SYSTEMS — Test LXC Fleet
# One LXC per VLAN, mixed distros (Debian 13 / Ubuntu 24.04 / Rocky 9)
#
# Purpose: functional validation of the FW rule pack — each LXC tests its zone's
# allowed + denied flows (per the 15-case test matrix in services/0006).
#
# Hostname convention (naming/0001 §9, see modules/lxc-cloudinit/README.md):
#   lxc-{role}-{os_slug}-{env}-{seq:02d}
#   → FQDN = ${name}.${dns_domain}
#
# VMID range: 1510–1519 (test LXCs are 1500–1999 per infra/0004 §5;
# 1500–1509 reserved for ad-hoc probes — vm 1500 already exists as lxc-test-ops-01).
#
# Addressing matches CURRENT live FW state (old seed: 10.11.20x.x / fd11:20x::/64).
# After FW reseed lands the ADR /24 addressing (10.11.x.x / fd11:x::/64), update
# this file in one pass.
#
# Templates: cloud-init enabled images from images.linuxcontainers.org —
# proxmox_virtual_environment_download_file fetches them declaratively.
################################################################################

# ---------------------------------------------------------------------------
# Template URLs — Proxmox-standard tarballs from download.proxmox.com.
#
# Why Proxmox-standard (not linuxcontainers.org cloud):
#   - cloud variant from images.linuxcontainers.org does NOT include openssh-server
#     (it expects cloud-init runcmd to install it — but bpg's LXC initialization
#     block doesn't support user_data_file_id / runcmd, so sshd never gets installed
#     → port 22 RST'd on all containers, integration tests blocked).
#   - Proxmox-standard tarballs ship with openssh-server preinstalled and enabled.
#   - BPG's initialization.user_account.keys writes /root/.ssh/authorized_keys
#     natively (no cloud-init dependency), so the standard-template switch is clean.
#
# Rocky Linux 9 has NO Proxmox-standard variant in the aplinfo catalogue.
# For now Rocky LXCs use debian-13-standard (loses distro diversity but unblocks
# integration tests). Follow-up: pre-bake a Rocky-9 vztmpl with openssh-server.
# Update the *_url variables when newer snapshots are released.
# ---------------------------------------------------------------------------
variable "tmpl_debian_13_url" {
  description = "URL to Debian 13 (trixie) Proxmox-standard LXC vztmpl (openssh-server preinstalled + enabled). From http://download.proxmox.com/images/system/."
  type        = string
  default     = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
}

variable "tmpl_ubuntu_2404_url" {
  description = "URL to Ubuntu 24.04 (noble) Proxmox-standard LXC vztmpl (openssh-server preinstalled + enabled). From http://download.proxmox.com/images/system/."
  type        = string
  default     = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

resource "proxmox_virtual_environment_download_file" "tmpl_debian_13" {
  content_type        = "vztmpl"
  datastore_id        = "poc-iso"
  node_name           = "srv-proxmox-poc-01"
  url                 = var.tmpl_debian_13_url
  file_name           = "debian-13-standard_13.1-2_amd64.tar.zst"
  overwrite           = false
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_download_file" "tmpl_ubuntu_2404" {
  content_type        = "vztmpl"
  datastore_id        = "poc-iso"
  node_name           = "srv-proxmox-poc-01"
  url                 = var.tmpl_ubuntu_2404_url
  file_name           = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  overwrite           = false
  overwrite_unmanaged = true
}

# NOTE: rockylinux-9 stays as debian-13-standard until a Rocky vztmpl with
# openssh-server is pre-baked. See follow-up issue.

# ---------------------------------------------------------------------------
# Locals — repeated values
# ---------------------------------------------------------------------------
locals {
  test_node    = "srv-proxmox-poc-01"
  test_domain  = "test.by-research.be"
  test_bridge  = "vmbrAPPS"

  # standard_ssh_keys is defined in main.tf (one key, ED25519, passphrase-protected per ADR-0033)

  # Per-zone DNS = OPNsense Unbound on this VLAN (dual-stack).
  # Addressing per ADR infra/0004 §4 (post-reseed 2026-05-27).
  dns_mgmt    = ["10.11.1.1", "fd11:1::1"]
  dns_dmz     = ["10.11.2.1", "fd11:2::1"]
  dns_svc     = ["10.11.3.1", "fd11:3::1"]
  dns_vpn     = ["10.11.4.1", "fd11:4::1"]
  dns_iot     = ["10.11.10.1", "fd11:10::1"]
  dns_voip    = ["10.11.11.1", "fd11:11::1"]
  dns_storage = ["10.11.20.1", "fd11:20::1"]
  dns_media   = ["10.11.30.1", "fd11:30::1"]
  dns_gaming  = ["10.11.32.1", "fd11:32::1"]
  dns_cctv    = ["10.11.40.1", "fd11:40::1"]
}

# ===========================================================================
# DEBIAN 13 — 4 LXCs (MGMT, DMZ, SVC, VPN)
# ===========================================================================

module "lxc_mgmt_deb13_01" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-mgmt-deb13-test-01"
  vmid        = 1510
  target_node = local.test_node
  env         = "test"
  os_type     = "debian"
  tags        = ["probe", "vlan2010", "os-debian-13", "zone-mgmt"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores   = 1
  memory  = 512
  disk_gb = 4
  storage = "poc-data"

  network_bridge = local.test_bridge
  vlan_tag       = 2010
  ipv4_address   = "10.11.1.100/24"
  ipv4_gateway   = "10.11.1.1"
  ipv6_address   = "fd11:1::100/64"
  ipv6_gateway   = "fd11:1::1"

  dns_domain  = local.test_domain
  dns_servers = local.dns_mgmt
  ssh_keys    = local.standard_ssh_keys
}

module "lxc_dmz_deb13_01" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-dmz-deb13-test-01"
  vmid        = 1511
  target_node = local.test_node
  env         = "test"
  os_type     = "debian"
  tags        = ["probe", "vlan2020", "os-debian-13", "zone-dmz"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores   = 1
  memory  = 512
  disk_gb = 4
  storage = "poc-data"

  network_bridge = local.test_bridge
  vlan_tag       = 2020
  ipv4_address   = "10.11.2.100/24"
  ipv4_gateway   = "10.11.2.1"
  ipv6_address   = "fd11:2::100/64"
  ipv6_gateway   = "fd11:2::1"

  dns_domain  = local.test_domain
  dns_servers = local.dns_dmz
  ssh_keys    = local.standard_ssh_keys
}

module "lxc_svc_deb13_01" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-svc-deb13-test-01"
  vmid        = 1512
  target_node = local.test_node
  env         = "test"
  os_type     = "debian"
  tags        = ["probe", "vlan2030", "os-debian-13", "zone-svc"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores   = 1
  memory  = 512
  disk_gb = 4
  storage = "poc-data"

  network_bridge = local.test_bridge
  vlan_tag       = 2030
  ipv4_address   = "10.11.3.100/24"
  ipv4_gateway   = "10.11.3.1"
  ipv6_address   = "fd11:3::100/64"
  ipv6_gateway   = "fd11:3::1"

  dns_domain  = local.test_domain
  dns_servers = local.dns_svc
  ssh_keys    = local.standard_ssh_keys
}

module "lxc_vpn_deb13_01" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-vpn-deb13-test-01"
  vmid        = 1513
  target_node = local.test_node
  env         = "test"
  os_type     = "debian"
  tags        = ["probe", "vlan2040", "os-debian-13", "zone-vpn"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores   = 1
  memory  = 512
  disk_gb = 4
  storage = "poc-data"

  network_bridge = local.test_bridge
  vlan_tag       = 2040
  ipv4_address   = "10.11.4.100/24"
  ipv4_gateway   = "10.11.4.1"
  ipv6_address   = "fd11:4::100/64"
  ipv6_gateway   = "fd11:4::1"

  dns_domain  = local.test_domain
  dns_servers = local.dns_vpn
  ssh_keys    = local.standard_ssh_keys
}

# ===========================================================================
# UBUNTU 24.04 — 3 LXCs (IoT, VoIP, Storage)
# ===========================================================================

module "lxc_iot_ubu2404_01" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-iot-ubu2404-test-01"
  vmid        = 1514
  target_node = local.test_node
  env         = "test"
  os_type     = "ubuntu"
  tags        = ["probe", "vlan2100", "os-ubuntu-24.04", "zone-iot"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_ubuntu_2404.id
  cores   = 1
  memory  = 512
  disk_gb = 4
  storage = "poc-data"

  network_bridge = local.test_bridge
  vlan_tag       = 2100
  ipv4_address   = "10.11.10.100/24"
  ipv4_gateway   = "10.11.10.1"
  ipv6_address   = "fd11:10::100/64"
  ipv6_gateway   = "fd11:10::1"

  dns_domain  = local.test_domain
  dns_servers = local.dns_iot
  ssh_keys    = local.standard_ssh_keys
}

module "lxc_voip_ubu2404_01" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-voip-ubu2404-test-01"
  vmid        = 1515
  target_node = local.test_node
  env         = "test"
  os_type     = "ubuntu"
  tags        = ["probe", "vlan2110", "os-ubuntu-24.04", "zone-voip"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_ubuntu_2404.id
  cores   = 1
  memory  = 512
  disk_gb = 4
  storage = "poc-data"

  network_bridge = local.test_bridge
  vlan_tag       = 2110
  ipv4_address   = "10.11.11.100/24"
  ipv4_gateway   = "10.11.11.1"
  ipv6_address   = "fd11:11::100/64"
  ipv6_gateway   = "fd11:11::1"

  dns_domain  = local.test_domain
  dns_servers = local.dns_voip
  ssh_keys    = local.standard_ssh_keys
}

module "lxc_storage_ubu2404_01" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-storage-ubu2404-test-01"
  vmid        = 1516
  target_node = local.test_node
  env         = "test"
  os_type     = "ubuntu"
  tags        = ["probe", "vlan2200", "os-ubuntu-24.04", "zone-storage"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_ubuntu_2404.id
  cores   = 1
  memory  = 512
  disk_gb = 4
  storage = "poc-data"

  network_bridge = local.test_bridge
  vlan_tag       = 2200
  ipv4_address   = "10.11.20.100/24"
  ipv4_gateway   = "10.11.20.1"
  ipv6_address   = "fd11:20::100/64"
  ipv6_gateway   = "fd11:20::1"

  dns_domain  = local.test_domain
  dns_servers = local.dns_storage
  ssh_keys    = local.standard_ssh_keys
}

# ===========================================================================
# DEBIAN 13 — 3 LXCs (Media, GAMING, CCTV) — was Rocky-9; switched until
# a Rocky-9 vztmpl with openssh-server is pre-baked. Distro diversity returns
# once the follow-up custom-template work lands.
# ===========================================================================

module "lxc_media_deb13_01" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-media-deb13-test-01"
  vmid        = 1517
  target_node = local.test_node
  env         = "test"
  os_type     = "debian"
  tags        = ["probe", "vlan2300", "os-debian-13", "zone-media"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores   = 1
  memory  = 512
  disk_gb = 4
  storage = "poc-data"

  network_bridge = local.test_bridge
  vlan_tag       = 2300
  ipv4_address   = "10.11.30.100/24"
  ipv4_gateway   = "10.11.30.1"
  ipv6_address   = "fd11:30::100/64"
  ipv6_gateway   = "fd11:30::1"

  dns_domain  = local.test_domain
  dns_servers = local.dns_media
  ssh_keys    = local.standard_ssh_keys
}

module "lxc_gaming_deb13_01" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-gaming-deb13-test-01"
  vmid        = 1518
  target_node = local.test_node
  env         = "test"
  os_type     = "debian"
  tags        = ["probe", "vlan2320", "os-debian-13", "zone-gaming"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores   = 1
  memory  = 512
  disk_gb = 4
  storage = "poc-data"

  network_bridge = local.test_bridge
  vlan_tag       = 2320
  ipv4_address   = "10.11.32.100/24"
  ipv4_gateway   = "10.11.32.1"
  ipv6_address   = "fd11:32::100/64"
  ipv6_gateway   = "fd11:32::1"

  dns_domain  = local.test_domain
  dns_servers = local.dns_gaming
  ssh_keys    = local.standard_ssh_keys
}

module "lxc_cctv_deb13_01" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-cctv-deb13-test-01"
  vmid        = 1519
  target_node = local.test_node
  env         = "test"
  os_type     = "debian"
  tags        = ["probe", "vlan2400", "os-debian-13", "zone-cctv"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores   = 1
  memory  = 512
  disk_gb = 4
  storage = "poc-data"

  network_bridge = local.test_bridge
  vlan_tag       = 2400
  ipv4_address   = "10.11.40.100/24"
  ipv4_gateway   = "10.11.40.1"
  ipv6_address   = "fd11:40::100/64"
  ipv6_gateway   = "fd11:40::1"

  dns_domain  = local.test_domain
  dns_servers = local.dns_cctv
  ssh_keys    = local.standard_ssh_keys
}

# NOTE: AdGuard Home is provisioned as a QEMU VM (see vm-fleet.tf below),
# not as an LXC. Reason: cloud LXC rootfs templates from images.linuxcontainers.org
# do NOT include openssh-server, and PVE LXC API has no `exec` endpoint — so without
# PVE node shell access (we have API-only) we cannot install software in a fresh LXC.
# QEMU VMs include qemu-guest-agent in the cloud-init image, giving us `qm guest exec`
# for post-create bootstrap exactly like vm-opns-test-01. The svc LXC slot 1520 is
# reserved should the LXC bootstrap path ever be solved.

# ---------------------------------------------------------------------------
# Outputs — FQDNs (consumable by DNS / NetBox sync / validation matrix script)
# ---------------------------------------------------------------------------
output "lxc_fleet" {
  description = "All test LXCs with their FQDN, IPv4, IPv6, VLAN, distro"
  value = {
    mgmt    = { fqdn = module.lxc_mgmt_deb13_01.fqdn,    ipv4 = module.lxc_mgmt_deb13_01.ipv4_address,    ipv6 = module.lxc_mgmt_deb13_01.ipv6_address,    vlan = 2010, distro = "debian-13" }
    dmz     = { fqdn = module.lxc_dmz_deb13_01.fqdn,     ipv4 = module.lxc_dmz_deb13_01.ipv4_address,     ipv6 = module.lxc_dmz_deb13_01.ipv6_address,     vlan = 2020, distro = "debian-13" }
    svc     = { fqdn = module.lxc_svc_deb13_01.fqdn,     ipv4 = module.lxc_svc_deb13_01.ipv4_address,     ipv6 = module.lxc_svc_deb13_01.ipv6_address,     vlan = 2030, distro = "debian-13" }
    vpn     = { fqdn = module.lxc_vpn_deb13_01.fqdn,     ipv4 = module.lxc_vpn_deb13_01.ipv4_address,     ipv6 = module.lxc_vpn_deb13_01.ipv6_address,     vlan = 2040, distro = "debian-13" }
    iot     = { fqdn = module.lxc_iot_ubu2404_01.fqdn,   ipv4 = module.lxc_iot_ubu2404_01.ipv4_address,   ipv6 = module.lxc_iot_ubu2404_01.ipv6_address,   vlan = 2100, distro = "ubuntu-24.04" }
    voip    = { fqdn = module.lxc_voip_ubu2404_01.fqdn,  ipv4 = module.lxc_voip_ubu2404_01.ipv4_address,  ipv6 = module.lxc_voip_ubu2404_01.ipv6_address,  vlan = 2110, distro = "ubuntu-24.04" }
    storage = { fqdn = module.lxc_storage_ubu2404_01.fqdn, ipv4 = module.lxc_storage_ubu2404_01.ipv4_address, ipv6 = module.lxc_storage_ubu2404_01.ipv6_address, vlan = 2200, distro = "ubuntu-24.04" }
    media   = { fqdn = module.lxc_media_deb13_01.fqdn,  ipv4 = module.lxc_media_deb13_01.ipv4_address,  ipv6 = module.lxc_media_deb13_01.ipv6_address,  vlan = 2300, distro = "debian-13" }
    gaming  = { fqdn = module.lxc_gaming_deb13_01.fqdn, ipv4 = module.lxc_gaming_deb13_01.ipv4_address, ipv6 = module.lxc_gaming_deb13_01.ipv6_address, vlan = 2320, distro = "debian-13" }
    cctv    = { fqdn = module.lxc_cctv_deb13_01.fqdn,   ipv4 = module.lxc_cctv_deb13_01.ipv4_address,   ipv6 = module.lxc_cctv_deb13_01.ipv6_address,   vlan = 2400, distro = "debian-13" }
  }
}

################################################################################
# BY-SYSTEMS — Production Environment (ADR-0032)
# Node: srv-proxmox-poc-01
# Provider: bpg/proxmox ~> 0.99
# State: local backend → GitLab managed state when GitLab CE deployed
#
# SDN zone: prod (9 segments, VLANs 1010-1400 on vmbrAPPS, ADR-0032)
# All dual-stack IPv4 + IPv6 ULA
#   MGMT    1010  10.1.1.0/24   fd01:1::/64    gw 10.1.1.1
#   DMZ     1020  10.1.2.0/24   fd01:2::/64    gw 10.1.2.1
#   SVC     1030  10.1.3.0/24   fd01:3::/64    gw 10.1.3.1
#   VPN     1040  10.1.4.0/24   fd01:4::/64    gw 10.1.4.1
#   IoT     1100  10.1.10.0/24  fd01:10::/64   gw 10.1.10.1
#   VoIP    1110  10.1.11.0/24  fd01:11::/64   gw 10.1.11.1
#   Storage 1200  10.1.20.0/24  fd01:20::/64   gw 10.1.20.1
#   Media   1300  10.1.30.0/24  fd01:30::/64   gw 10.1.30.1
#   CCTV    1400  10.1.40.0/24  fd01:40::/64   gw 10.1.40.1
#
# Network bridges on node:
#   vmbrWAN1  — WAN1 Proximus PPPoE (OPNsense WAN primary)
#   vmbrWAN2  — WAN2 Telenet (OPNsense WAN secondary)
#   vmbrWAN3  — bootstrap internet path (active during ISP migration)
#   vmbrAPPS  — VLAN trunk bridge (OPNsense LAN + all VM NICs)
#   vmbrOOB   — break-glass only (no IP, isolated, emergency console)
#   vmbrFAB   — fabric supervision (disabled, not yet wired)
#
# Deploy order: OPNsense → SDN VNets → all other VMs
################################################################################

locals {
  standard_ssh_keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJ8rXlV8+/e20imHW/hTry2DbqQ9bIpwslC4MIINlJW by-systems@ws-win11-ref",
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuUNkyvMaETbPeBGsBPEfzeYsL1SuVbvPUOMIb/2VU8 by-systems@rune-vm",
  ]
}

################################################################################
# Layer -1 — Proxmox SDN (pre-requisite for ALL VM networking)
# Deploy FIRST. Creates SDN zone `prod` + 9 VNets on vmbrAPPS (ADR-0032).
# Without this, VM NICs referencing VNets will fail to attach.
# Ref: ADR-0032, ADR-0015 (superseded for VLAN ranges)
################################################################################

module "sdn" {
  source = "../../modules/sdn-poc"

  node_name = "srv-proxmox-poc-01"
  zone_id   = "prod"
  bridge    = "vmbrAPPS"
  mtu       = 1500

  vnets = {
    mgmt = {
      tag     = 1010
      alias   = "Management"
      subnet  = "10.1.1.0/24"
      gateway = "10.1.1.1"
    }
    dmz = {
      tag     = 1020
      alias   = "DMZ"
      subnet  = "10.1.2.0/24"
      gateway = "10.1.2.1"
    }
    svc = {
      tag     = 1030
      alias   = "Services"
      subnet  = "10.1.3.0/24"
      gateway = "10.1.3.1"
    }
    vpn = {
      tag     = 1040
      alias   = "VPN"
      subnet  = "10.1.4.0/24"
      gateway = "10.1.4.1"
    }
    iot = {
      tag     = 1100
      alias   = "IoT"
      subnet  = "10.1.10.0/24"
      gateway = "10.1.10.1"
    }
    voip = {
      tag     = 1110
      alias   = "VoIP"
      subnet  = "10.1.11.0/24"
      gateway = "10.1.11.1"
    }
    storage = {
      tag     = 1200
      alias   = "Storage"
      subnet  = "10.1.20.0/24"
      gateway = "10.1.20.1"
    }
    media = {
      tag     = 1300
      alias   = "Media"
      subnet  = "10.1.30.0/24"
      gateway = "10.1.30.1"
    }
    cctv = {
      tag     = 1400
      alias   = "CCTV"
      subnet  = "10.1.40.0/24"
      gateway = "10.1.40.1"
    }
  }
}

output "sdn_zone_id" {
  value = module.sdn.zone_id
}

output "sdn_vnet_ids" {
  value = module.sdn.vnet_ids
}

################################################################################
# Layer 0 — Network Gateway
# Deploy after SDN. OPNsense LAN NIC attaches to vmbrAPPS as VLAN trunk.
# After apply: open Proxmox noVNC console → complete OPNsense install wizard (~5 min)
# Then Ansible configures interfaces, WireGuard, VLAN subinterfaces, Unbound DoT.
################################################################################

module "opnsense" {
  source = "../../modules/vm-opnsense"

  name        = "vm-opnsense-01" # env=prod → no env suffix (ADR-0010)
  vm_id       = 100
  env         = "prod"
  target_node = "srv-proxmox-poc-01"

  cores        = 2
  memory       = 8192
  disk_size    = 20
  disk_storage = "poc-data"

  iso_storage = "poc-iso"
  iso_file    = "OPNsense-26.1.2-dvd-amd64.iso"

  wan_bridge = "vmbrWAN3"
  lan_bridge = "vmbrAPPS"
}

output "opnsense_vm_id" {
  value = module.opnsense.vm_id
}

################################################################################
# Layer 1 — DNS
# Pi-hole: DNS resolver + blocklist. MGMT zone.
# DNS flow: VM → Pi-hole :53 → OPNsense Unbound :853 → DoT 1.1.1.1
################################################################################

module "pihole" {
  source = "../../modules/vm-linux"

  name        = "vm-pihole-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 512
  disk_size = "10G"
  storage   = "poc-data"

  network_bridge = "mgmt"
  ip             = "10.1.1.60/24"
  gateway        = "10.1.1.1"
  dns            = "10.1.1.1"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "pihole_vm_id" {
  value = module.pihole.vm_id
}

output "pihole_ip" {
  value = module.pihole.ip_address
}

################################################################################
# Layer 1 — Reverse Proxy
# Traefik: edge proxy + TLS termination. DMZ zone.
################################################################################

module "traefik" {
  source = "../../modules/vm-linux"

  name        = "vm-traefik-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 1024
  disk_size = "10G"
  storage   = "poc-data"

  network_bridge = "dmz"
  ip             = "10.1.2.10/24"
  gateway        = "10.1.2.1"
  dns            = "10.1.1.60"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "traefik_vm_id" {
  value = module.traefik.vm_id
}

output "traefik_ip" {
  value = module.traefik.ip_address
}

################################################################################
# Layer 2 — Identity & Secrets
################################################################################

module "vault" {
  source = "../../modules/vm-linux"

  name        = "vm-vault-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 2048
  disk_size = "20G"
  storage   = "poc-data"

  network_bridge = "svc"
  ip             = "10.1.3.10/24"
  gateway        = "10.1.3.1"
  dns            = "10.1.1.60"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "vault_vm_id" {
  value = module.vault.vm_id
}

output "vault_ip" {
  value = module.vault.ip_address
}

module "vaultwarden" {
  source = "../../modules/vm-linux"

  name        = "vm-vaultwarden-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 512
  disk_size = "10G"
  storage   = "poc-data"

  network_bridge = "svc"
  ip             = "10.1.3.11/24"
  gateway        = "10.1.3.1"
  dns            = "10.1.1.60"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "vaultwarden_vm_id" {
  value = module.vaultwarden.vm_id
}

output "vaultwarden_ip" {
  value = module.vaultwarden.ip_address
}

module "authentik" {
  source = "../../modules/vm-linux"

  name        = "vm-authentik-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 2048
  disk_size = "20G"
  storage   = "poc-data"

  network_bridge = "svc"
  ip             = "10.1.3.12/24"
  gateway        = "10.1.3.1"
  dns            = "10.1.1.60"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "authentik_vm_id" {
  value = module.authentik.vm_id
}

output "authentik_ip" {
  value = module.authentik.ip_address
}

################################################################################
# Layer 3 — VCS & CI
################################################################################

module "gitlab" {
  source = "../../modules/vm-linux"

  name        = "vm-gitlab-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 4
  memory    = 8192
  disk_size = "50G"
  storage   = "poc-data"

  network_bridge = "svc"
  ip             = "10.1.3.20/24"
  gateway        = "10.1.3.1"
  dns            = "10.1.1.60"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "gitlab_vm_id" {
  value = module.gitlab.vm_id
}

output "gitlab_ip" {
  value = module.gitlab.ip_address
}

module "gitlab_runner" {
  source = "../../modules/vm-linux"

  name        = "vm-gitlab-runner-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 2048
  disk_size = "20G"
  storage   = "poc-data"

  network_bridge = "svc"
  ip             = "10.1.3.21/24"
  gateway        = "10.1.3.1"
  dns            = "10.1.1.60"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "gitlab_runner_vm_id" {
  value = module.gitlab_runner.vm_id
}

output "gitlab_runner_ip" {
  value = module.gitlab_runner.ip_address
}

################################################################################
# Layer 4 — Collaboration
################################################################################

module "nextcloud" {
  source = "../../modules/vm-linux"

  name        = "vm-nextcloud-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 2048
  disk_size = "20G"
  storage   = "poc-data"

  network_bridge = "svc"
  ip             = "10.1.3.30/24"
  gateway        = "10.1.3.1"
  dns            = "10.1.1.60"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "nextcloud_vm_id" {
  value = module.nextcloud.vm_id
}

output "nextcloud_ip" {
  value = module.nextcloud.ip_address
}

################################################################################
# Layer 5 — IPAM & DCIM
################################################################################

module "netbox" {
  source = "../../modules/vm-linux"

  name        = "vm-netbox-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 2048
  disk_size = "20G"
  storage   = "poc-data"

  network_bridge = "svc"
  ip             = "10.1.3.31/24"
  gateway        = "10.1.3.1"
  dns            = "10.1.1.60"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "netbox_vm_id" {
  value = module.netbox.vm_id
}

output "netbox_ip" {
  value = module.netbox.ip_address
}

################################################################################
# Layer 6 — Package Registry
################################################################################

module "nexus" {
  source = "../../modules/vm-linux"

  name        = "vm-nexus-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 6144
  disk_size = "50G"
  storage   = "poc-data"

  network_bridge = "svc"
  ip             = "10.1.3.40/24"
  gateway        = "10.1.3.1"
  dns            = "10.1.1.60"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "nexus_vm_id" {
  value = module.nexus.vm_id
}

output "nexus_ip" {
  value = module.nexus.ip_address
}

################################################################################
# Layer 7 — Observability
################################################################################

module "observability" {
  source = "../../modules/vm-linux"

  name        = "vm-observability-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 4096
  disk_size = "30G"
  storage   = "poc-data"

  network_bridge = "svc"
  ip             = "10.1.3.50/24"
  gateway        = "10.1.3.1"
  dns            = "10.1.1.60"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "observability_vm_id" {
  value = module.observability.vm_id
}

output "observability_ip" {
  value = module.observability.ip_address
}

################################################################################
# Layer 8 — Shared Infrastructure
################################################################################

module "postgres" {
  source = "../../modules/vm-linux"

  name        = "vm-postgres-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 4096
  disk_size = "50G"
  storage   = "poc-data"

  network_bridge = "svc"
  ip             = "10.1.3.60/24"
  gateway        = "10.1.3.1"
  dns            = "10.1.1.60"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "postgres_vm_id" {
  value = module.postgres.vm_id
}

output "postgres_ip" {
  value = module.postgres.ip_address
}

module "redis" {
  source = "../../modules/vm-linux"

  name        = "vm-redis-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 1024
  disk_size = "10G"
  storage   = "poc-data"

  network_bridge = "svc"
  ip             = "10.1.3.61/24"
  gateway        = "10.1.3.1"
  dns            = "10.1.1.60"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "redis_vm_id" {
  value = module.redis.vm_id
}

output "redis_ip" {
  value = module.redis.ip_address
}

################################################################################
# Layer 9 — Network Management
################################################################################

module "unifi" {
  source = "../../modules/vm-linux"

  name        = "vm-unifi-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 2048
  disk_size = "10G"
  storage   = "poc-data"

  network_bridge = "mgmt"
  ip             = "10.1.1.70/24"
  gateway        = "10.1.1.1"
  dns            = "10.1.1.60"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "unifi_vm_id" {
  value = module.unifi.vm_id
}

output "unifi_ip" {
  value = module.unifi.ip_address
}

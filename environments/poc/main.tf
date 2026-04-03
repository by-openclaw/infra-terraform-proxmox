################################################################################
# BY-SYSTEMS — Proxmox PoC Environment
# Node: srv-proxmox-poc-01 (10.6.224.105)
# Provider: bpg/proxmox ~> 0.66 (PVE 9.x compatible)
# State: local backend (migrate to GitLab managed state when GitLab CE deployed)
#
# IP strategy:
#   10.6.224.x — OOB infrastructure (Proxmox host, NAS, switches, pfSense) — physical only
#   10.1.0.0/20  — PoC VM supernet (OPNsense manages, 4 VLANs: 300/310/320/330)
#   10.6.225.x   — DO NOT USE for VMs — OOB bootstrap range, decommissioned
#
# Network bridges on srv-proxmox-poc-01 (as of 2026-04-03):
#   vmbrWAN1 — WAN1 Proximus PPPoE — OPNsense WAN primary
#   vmbrWAN2 — WAN Telenet — OPNsense WAN secondary (untested)
#   vmbrWAN3 — OOB Proximus path (10.6.224.0/20) — internet access during ISP migration
#   vmbrOOB  — break-glass only (planned — no IP, isolated, emergency console access)
#   vmbrFAB  — fabric supervision bridge (disabled until PoC fabric physically wired)
#   vmbrAPPS — application/production VLAN bridge (placeholder, no ports)
#   vmbrPOC  — REMOVED 2026-04-03 (was virtual internal bridge, not in any ADR)
#
# Deploy order: OPNsense first → SDN VLANs → all other VMs
################################################################################

# Standard SSH keys injected into all VMs
# Updated 2026-03-29: new by-systems keys (no personal email in comments)
locals {
  standard_ssh_keys = [
    # Win11 reference station — human OOB access
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJ8rXlV8+/e20imHW/hTry2DbqQ9bIpwslC4MIINlJW by-systems@ws-win11-ref",
    # Rune VM — automation / ansible
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuUNkyvMaETbPeBGsBPEfzeYsL1SuVbvPUOMIb/2VU8 by-systems@rune-vm",
  ]
}

################################################################################
# Layer 0 — Network Gateway (deploy first — everything depends on this)
################################################################################

# OPNsense — PoC virtual router and firewall (ADR-0015)
# WAN: vmbrWAN3 → gets 10.6.225.1/20, GW 10.6.224.1 (set in OPNsense post-install)
# LAN: SDN VNet bridge → 10.1.0.1/20 (gateway for all PoC VLANs 310/320/330)
# WireGuard: Rune VM peer → access to 10.1.x.x without physical VLAN switch
#
# ⚠ INSTALL REQUIRED: After terraform apply, open Proxmox noVNC console for
#   vm-opnsense-poc-01 and complete the OPNsense install wizard (~5 min).
#   Then Ansible takes over for WireGuard + interface config.
module "opnsense" {
  source = "../../modules/vm-opnsense"

  name         = "vm-opnsense-poc-01"
  vm_id        = 100
  target_node  = "srv-proxmox-poc-01"

  cores        = 2
  memory       = 2048
  disk_size    = 20
  disk_storage = "poc-data"

  iso_storage  = "local"
  iso_file     = "OPNsense-25.1-dvd-amd64.iso"

  wan_bridge   = "vmbrWAN3"
  lan_bridge   = "vmbrSDN"
}

output "opnsense_vm_id" {
  value = module.opnsense.vm_id
}

# Bootstrap test VM — DESTROYED 2026-04-03. Removed from config.

################################################################################
# Platform services — deployment order matters
# Layer 0: OPNsense      (virtual router + WireGuard — all VM networking depends on this)
# Layer 1: Pi-hole       (DNS — must be up before any service needs name resolution)
# Layer 1: Traefik       (reverse proxy — HTTP/S entry point)
# Layer 2: step-ca       (internal CA — optional for PoC, LE covers public certs)
# Layer 2: Vault         (secrets — Traefik, Authentik, NetBox depend on this)
# Layer 3: Vaultwarden   (human password manager — needs Traefik for HTTPS)
# Layer 3: Authentik     (SSO — needs Vault + Traefik)
# Layer 4: NetBox        (CMDB — needs Authentik for SSO, Vault for secrets)
# ...
#
################################################################################

################################################################################
# Layer 1 — DNS
# Pi-hole only — no Unbound sidecar. Blocklist + local DNS overrides.
# DNS flow: VM :53 → [OPNsense NAT redirect] → Pi-hole :53 → OPNsense Unbound :853 → DoT 1.1.1.1:853
# OPNsense NAT rule: intercepts all :53 from PoC zones, redirects to Pi-hole. Bypass prevention.
# OPNsense Unbound: DoT terminator (enabled). Pi-hole upstream = OPNsense internal IP :853.
# Local overrides: *.by-systems.be → private IPs via Pi-hole v6 REST API (Ansible)
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

  network_bridge = "vmbrWAN3" # TODO: move to vnet-poc-mgmt (10.1.1.60) once SDN deployed — renamed from vmbrOOB 2026-04-03
  ip             = "10.6.225.60/20" # OOB bootstrap IP — reassign to 10.1.1.60 post-SDN
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1" # Bootstrap: upstream DNS. Post-deploy: points to itself.

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "pihole_vm_id" {
  value = module.pihole.vm_id
}

output "pihole_ip" {
  value = module.pihole.ip_address
}

# (stale vm-linux opnsense block removed 2026-04-03 — replaced by vm-opnsense module above)

# Traefik — Reverse proxy + TLS termination
# Ports: 80 (redirect), 443 (HTTPS)
module "traefik" {
  source = "../../modules/vm-linux"

  name        = "vm-traefik-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 1024
  disk_size = "10G"
  storage   = "poc-data"

  network_bridge = "vmbrWAN3"
  ip             = "10.6.225.15/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

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
# Layer 1 — DNS
################################################################################

# NOTE: Pi-hole module definition is above (Layer 1 DNS section)

################################################################################
# Layer 2 — Identity & Secrets
################################################################################

# Vault — Machine secrets (CI/CD, Ansible, services)
# Port: 8200
# Spec: 2 GB PoC (1 GB Vault JVM + Docker/OS overhead). Raft backend on 20 GB disk.
module "vault" {
  source = "../../modules/vm-linux"

  name        = "vm-vault-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 2048
  disk_size = "20G"
  storage   = "poc-data"

  network_bridge = "vmbrWAN3" // renamed from vmbrOOB 2026-04-03
  ip             = "10.6.225.13/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "vault_vm_id" {
  value = module.vault.vm_id
}

output "vault_ip" {
  value = module.vault.ip_address
}

# Vaultwarden — Human password manager (Bitwarden-compatible)
# Port: 8080
# Spec: 512 MB PoC (Rust binary ~50-100 MB + Docker/OS overhead; 256 MB is OOM risk)
module "vaultwarden" {
  source = "../../modules/vm-linux"

  name        = "vm-vaultwarden-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 512
  disk_size = "10G"
  storage   = "poc-data"

  network_bridge = "vmbrWAN3" // renamed from vmbrOOB 2026-04-03
  ip             = "10.6.225.14/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "vaultwarden_vm_id" {
  value = module.vaultwarden.vm_id
}

output "vaultwarden_ip" {
  value = module.vaultwarden.ip_address
}

# Authentik — SSO (OIDC/SAML)
# Depends on: vm-postgres-poc-01, vm-redis-poc-01, vm-vault-poc-01, vm-traefik-poc-01
# Ports: 9000 (HTTP), 9443 (HTTPS)
# Spec: 2 GB minimum — OOMs below 2 GB. Vendor confirmed.
module "authentik" {
  source = "../../modules/vm-linux"

  name        = "vm-authentik-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 2048
  disk_size = "20G"
  storage   = "poc-data"

  network_bridge = "vmbrWAN3" // renamed from vmbrOOB 2026-04-03
  ip             = "10.6.225.16/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

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

# GitLab CE — VCS, CI orchestrator, container registry
# Port: 8080 (HTTP — Traefik terminates TLS)
# Exception: GitLab bundles nginx — Traefik proxies via HTTP mode
# Spec: 4 vCPU / 8 GB minimum per vendor. 8 GB vendor minimum, kept at constraint.
module "gitlab" {
  source = "../../modules/vm-linux"

  name        = "vm-gitlab-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 4
  memory    = 8192
  disk_size = "50G"
  storage   = "poc-data"

  network_bridge = "vmbrWAN3" // renamed from vmbrOOB 2026-04-03
  ip             = "10.6.225.20/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "gitlab_vm_id" {
  value = module.gitlab.vm_id
}

output "gitlab_ip" {
  value = module.gitlab.ip_address
}

# GitLab Runner — CI pipeline executor (Docker executor)
# Spec: 2 vCPU / 2 GB PoC for light pipelines (lint, build, test).
module "gitlab_runner" {
  source = "../../modules/vm-linux"

  name        = "vm-gitlab-runner-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 2048
  disk_size = "20G"
  storage   = "poc-data"

  network_bridge = "vmbrWAN3" // renamed from vmbrOOB 2026-04-03
  ip             = "10.6.225.21/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

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

# Nextcloud — Team file storage + collaboration
# Docker: nextcloud-fpm + nginx sidecar. Primary storage: Contabo S3.
# Spec: 2 vCPU / 2 GB PoC — fpm workers + nginx sidecar + S3 client.
module "nextcloud" {
  source = "../../modules/vm-linux"

  name        = "vm-nextcloud-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 2048
  disk_size = "20G"
  storage   = "poc-data"

  network_bridge = "vmbrWAN3" // renamed from vmbrOOB 2026-04-03
  ip             = "10.6.225.35/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

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

# NetBox — CMDB / IPAM
# Depends on: vm-postgres-poc-01, vm-redis-poc-01, vm-vault-poc-01, vm-traefik-poc-01
# Port: 8080
# Spec: 2 vCPU / 2 GB PoC — Django + worker, modest RAM usage.
module "netbox" {
  source = "../../modules/vm-linux"

  name        = "vm-netbox-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 2048
  disk_size = "20G"
  storage   = "poc-data"

  network_bridge = "vmbrWAN3" // renamed from vmbrOOB 2026-04-03
  ip             = "10.6.225.17/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

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

# Nexus OSS — Artifact registry (pip, npm, Docker, Maven)
# Ports: 8081 (HTTP), 8082 (Docker proxy)
# Spec: 2 vCPU / 6 GB PoC — JVM default heap 2703 MB + MaxDirectMemory 2703 MB = ~5.4 GB JVM
#       + Docker/OS overhead. 2 GB is CRITICALLY UNDERSIZED — OOM on startup guaranteed.
#       6 GB minimum for stable operation. See: sonatype.com/system-requirements
module "nexus" {
  source = "../../modules/vm-linux"

  name        = "vm-nexus-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 6144
  disk_size = "50G"
  storage   = "poc-data"

  network_bridge = "vmbrWAN3" // renamed from vmbrOOB 2026-04-03
  ip             = "10.6.225.40/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

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

# Observability — Prometheus + Grafana + Loki (colocated for PoC)
# Docker Compose. Loki S3 backend (Contabo). Prometheus TSDB on local disk.
# Spec: 2 vCPU / 4 GB PoC — Prometheus ~256 MB + Grafana ~256 MB + Loki ~512 MB + overhead.
module "observability" {
  source = "../../modules/vm-linux"

  name        = "vm-observability-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 4096
  disk_size = "30G"
  storage   = "poc-data"

  network_bridge = "vmbrWAN3" // renamed from vmbrOOB 2026-04-03
  ip             = "10.6.225.50/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

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

# PostgreSQL — shared database server (Authentik, NetBox, Nextcloud, Vaultwarden)
# Port: 5432
# Spec: 2 vCPU / 4 GB PoC — shared_buffers ~1 GB for 4 active databases + connections.
module "postgres" {
  source = "../../modules/vm-linux"

  name        = "vm-postgres-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 4096
  disk_size = "50G"
  storage   = "poc-data"

  network_bridge = "vmbrWAN3" // renamed from vmbrOOB 2026-04-03
  ip             = "10.6.225.19/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "postgres_vm_id" {
  value = module.postgres.vm_id
}

output "postgres_ip" {
  value = module.postgres.ip_address
}

# Redis — shared cache/queue server (Authentik, NetBox, Nextcloud)
# Port: 6379
# Spec: 1 vCPU / 1 GB PoC — in-memory store, ~50-100 MB baseline; 1 GB gives headroom.
module "redis" {
  source = "../../modules/vm-linux"

  name        = "vm-redis-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 1024
  disk_size = "10G"
  storage   = "poc-data"

  network_bridge = "vmbrWAN3" // renamed from vmbrOOB 2026-04-03
  ip             = "10.6.225.18/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

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

# Unifi Network App — Ubiquiti controller (WiFi AP + VLAN management)
# Port: 8443 (UI), 8080 (device inform)
# Spec: 1 vCPU / 2 GB PoC — Java app + bundled MongoDB. 1 GB is OOM risk.
module "unifi" {
  source = "../../modules/vm-linux"

  name        = "vm-unifi-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 2048
  disk_size = "10G"
  storage   = "poc-data"

  network_bridge = "vmbrWAN3" // renamed from vmbrOOB 2026-04-03
  ip             = "10.6.225.62/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "unifi_vm_id" {
  value = module.unifi.vm_id
}

output "unifi_ip" {
  value = module.unifi.ip_address
}

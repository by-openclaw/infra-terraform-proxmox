################################################################################
# BY-SYSTEMS — Proxmox PoC Environment
# Node: srv-proxmox-poc-01 (10.6.224.105)
# Provider: bpg/proxmox ~> 0.66 (PVE 9.x compatible)
# State: local backend (migrate to GitLab managed state when GitLab CE deployed)
#
# IP strategy:
#   10.6.224.x — infrastructure (fw, switches, Proxmox nodes, NAS)
#   10.6.225.x — VMs/LXCs (PoC/dev)
#   10.6.239.101-199 — DHCP pool (avoid for static)
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

# Bootstrap test VM — validating VM baseline standard before deploying apps
# Once validated, this will be destroyed and the pattern used for real VMs
module "bootstrap_test" {
  source = "../../modules/vm-linux"

  name        = "vm-debian-bootstrap-test-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 1024
  disk_size = "10G"
  storage   = "poc-data"

  network_bridge = "vmbrOOB"
  ip             = "10.6.225.11/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "bootstrap_test_vm_id" {
  value = module.bootstrap_test.vm_id
}

output "bootstrap_test_ip" {
  value = module.bootstrap_test.ip_address
}

# NOTE: vm-netbox-poc-01 (ID 100) still exists with old config
# Will be destroyed manually after bootstrap test is validated

################################################################################
# Platform services — deployment order matters
# 1. step-ca  (internal CA — all other TLS depends on this)
# 2. Vault     (secrets — Traefik, Authentik, NetBox depend on this)
# 3. Traefik   (reverse proxy — needs certs from step-ca)
# 4. Vaultwarden (human password manager — needs Traefik for HTTPS)
# 5. Authentik (SSO — needs Vault + Traefik)
# 6. NetBox    (CMDB — needs Authentik for SSO, Vault for secrets)
# 7. MinIO     (object storage — needs Authentik for console SSO)
################################################################################

# step-ca — Internal CA for *.poc.by-systems.arpa
# Ports: 443 (ACME/HTTPS), 9000 (step-ca API)
module "step_ca" {
  source = "../../modules/vm-linux"

  name        = "vm-step-ca-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 1024
  disk_size = "10G"
  storage   = "poc-data"

  network_bridge = "vmbrOOB"
  ip             = "10.6.225.12/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "step_ca_vm_id" {
  value = module.step_ca.vm_id
}

output "step_ca_ip" {
  value = module.step_ca.ip_address
}

# Vault — Machine secrets (CI/CD, Ansible, services)
# Port: 8200
module "vault" {
  source = "../../modules/vm-linux"

  name        = "vm-vault-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 4096
  disk_size = "20G"
  storage   = "poc-data"

  network_bridge = "vmbrOOB"
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
module "vaultwarden" {
  source = "../../modules/vm-linux"

  name        = "vm-vaultwarden-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 1
  memory    = 1024
  disk_size = "10G"
  storage   = "poc-data"

  network_bridge = "vmbrOOB"
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

# Traefik — Reverse proxy + TLS termination for *.poc.by-systems.arpa
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

  network_bridge = "vmbrOOB"
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

# Authentik — SSO (OIDC/SAML) + bundled postgres + redis
# Ports: 9000 (HTTP), 9443 (HTTPS)
module "authentik" {
  source = "../../modules/vm-linux"

  name        = "vm-authentik-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 4096
  disk_size = "20G"
  storage   = "poc-data"

  network_bridge = "vmbrOOB"
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

# NetBox — CMDB + bundled postgres + redis
# Port: 8080
module "netbox" {
  source = "../../modules/vm-linux"

  name        = "vm-netbox-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 4096
  disk_size = "30G"
  storage   = "poc-data"

  network_bridge = "vmbrOOB"
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

# MinIO — S3-compatible object storage (ILM → Contabo S3 for DR)
# Ports: 9000 (S3 API), 9001 (console)
module "minio" {
  source = "../../modules/vm-linux"

  name        = "vm-minio-poc-01"
  target_node = "srv-proxmox-poc-01"
  clone       = "debian-12-cloud"

  cores     = 2
  memory    = 2048
  disk_size = "100G"
  storage   = "poc-data"

  network_bridge = "vmbrOOB"
  ip             = "10.6.225.18/20"
  gateway        = "10.6.224.1"
  dns            = "10.6.224.1"

  ci_user  = "by-systems"
  ssh_keys = local.standard_ssh_keys
}

output "minio_vm_id" {
  value = module.minio.vm_id
}

output "minio_ip" {
  value = module.minio.ip_address
}

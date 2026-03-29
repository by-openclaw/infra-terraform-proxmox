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

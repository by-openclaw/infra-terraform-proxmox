# BY-SYSTEMS — dev tier on node br-pmox-03 (the owner's "pve.dev", standalone,
# onboarded by ansible-platform 2026-10-13: adopt → identity-baseline → updates →
# hardening → monitoring; its own Terraform identity minted into Vault dev/).
#
# Node hardware: 2×12-core Xeon (HT off) = 24 cores in 4 NUMA nodes of 6 cores /
# ~63 GiB each; ZFS raid10 (local-zfs). Guests sit on vmbr0 (OOB 10.6.224.0/20,
# gw 10.6.224.1; the 10.1.0.0/16 platform networks route via the firewall's OOB
# leg — Ansible adds that route inside each guest, same as on the node).

locals {
  env        = "dev"
  node       = "br-pmox-03"
  storage    = "local-zfs"
  bridge     = "vmbr0"
  gateway    = "10.6.224.1"
  dns        = ["10.1.3.1"] # AdGuard, reachable once the guest carries the 10.1.0.0/16 route
  svc_domain = "dev.by-research.be"

  # First-boot seed only: on a running guest the keys are owned by ansible-platform
  # (roles/user-mgmt: root's list is exclusive; roles/windows_guest: Administrator's list is
  # exclusive) — a change here never reaches an existing guest (lifecycle ignore in the modules).
  # The early rune-vm key was retired on 2026-10-15 (ansible-platform files/keys/_retired).
  standard_ssh_keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJ8rXlV8+/e20imHW/hTry2DbqQ9bIpwslC4MIINlJW by-systems@ws-win11-ref",
    # Rune automation key (no passphrase) — lets ansible/CI reach managed VMs non-interactively.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAPtVxi41CKLEZuYr1PhIdPTJJEQ+bqbhnBuZgAVcT1U rune@by-systems-automation-nopass",
  ]
}

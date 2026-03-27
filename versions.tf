terraform {
  # Minimum Terraform version — use 1.5+ for best HCL features and stability
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      # Telmate Proxmox provider — pinned to 2.9.x for stability
      # Note: bpg/proxmox provider is more actively maintained but requires Proxmox 7.x+
      # Consider migrating to bpg/proxmox when provider matures further
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

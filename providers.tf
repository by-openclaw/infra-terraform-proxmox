terraform {
  required_providers {
    proxmox = {
      # Telmate Proxmox provider — most mature provider for Proxmox VE
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  # Proxmox API endpoint — set via variable or TF_VAR_proxmox_api_url
  pm_api_url = var.proxmox_api_url

  # API token authentication — preferred over username/password
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret

  # Allow self-signed TLS certificate (PoC — replace with valid cert in prod)
  pm_tls_insecure = true

  # Enable debug logging when needed
  # pm_log_enable = true
  # pm_log_file   = "terraform-plugin-proxmox.log"
}

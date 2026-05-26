# Copyright (c) 2026 BY-SYSTEMS SRL. MIT License.
# SPDX-License-Identifier: MIT
# Repo: https://github.com/by-openclaw/infra-terraform-proxmox
#
# lxc-cloudinit — provisioning module for cloud-init-enabled LXC containers
#
# Provider: bpg/proxmox (proxmox_virtual_environment_container)
# Template requirement: image MUST have cloud-init pre-installed
#                       (images.linuxcontainers.org/.../<distro>/<ver>/.../cloud)
#
# Tested templates:
#   - debian-13-cloud_amd64.tar.xz       (debian/13/amd64/cloud)
#   - ubuntu-24.04-cloud_amd64.tar.xz    (ubuntu/24.04/amd64/cloud)
#   - rockylinux-9-cloud_amd64.tar.xz    (rockylinux/9/amd64/cloud)
#
# Dual-stack: supports IPv4 + IPv6 static or DHCP per NIC.
# VLAN tagging on bridge (vmbrAPPS) via initialization.dns + network_interface block.
#
# ADRs:
#   - infra/0003-terraform-standard (module layout)
#   - infra/0004-network-architecture §4 (VLAN assignment, dual-stack)
#   - services/0007-provisioning-orchestrator (step 3 = create_shell)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.99"
    }
  }
}

resource "proxmox_virtual_environment_container" "this" {
  vm_id     = var.vmid
  node_name = var.target_node
  tags      = concat(["env-${var.env}", "lxc", "cloudinit"], var.tags)

  description = "Managed by Terraform — BY-SYSTEMS infra-terraform-proxmox / lxc-cloudinit"

  unprivileged = var.unprivileged
  start_on_boot = var.start_on_boot
  started       = var.started

  features {
    nesting = var.features.nesting
    fuse    = var.features.fuse
    keyctl  = var.features.keyctl
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
    swap      = 0
  }

  disk {
    datastore_id = var.storage
    size         = var.disk_gb
  }

  operating_system {
    template_file_id = var.ostemplate_file_id
    type             = var.os_type              # required for Proxmox to write /etc/network/interfaces, /etc/hostname, ~/.ssh/authorized_keys natively
  }

  network_interface {
    name        = "eth0"                        # NIC name AS SEEN inside the container — Proxmox managed setup expects eth0
    bridge      = var.network_bridge
    vlan_id     = var.vlan_tag > 0 ? var.vlan_tag : null
    firewall    = false
    enabled     = true
  }

  initialization {
    hostname = var.name

    dns {
      servers = var.dns_servers
      domain  = var.dns_domain != "" ? var.dns_domain : null
    }

    # IPv4 — static (CIDR) or DHCP
    dynamic "ip_config" {
      for_each = var.ipv4_address != "" ? [1] : []
      content {
        ipv4 {
          address = var.ipv4_address
          gateway = var.ipv4_address == "dhcp" ? null : (var.ipv4_gateway != "" ? var.ipv4_gateway : null)
        }
        ipv6 {
          address = var.ipv6_address != "" ? var.ipv6_address : null
          gateway = var.ipv6_address != "" && var.ipv6_address != "dhcp" && var.ipv6_gateway != "" ? var.ipv6_gateway : null
        }
      }
    }

    user_account {
      keys     = var.ssh_keys
      password = var.ci_password != "" ? var.ci_password : null
    }

    # Note: bpg/proxmox's container initialization does NOT accept user_data_file_id
    # or vendor_data_file_id (those are VM-only). For richer first-boot config
    # (packages, runcmd, files) use a pre-customised template OR run Ansible after
    # the container is up (services/0001 §Phase-2 pattern).
  }

  # Lifecycle: do NOT ignore network_interface — that previously swallowed legitimate
  # changes (NIC rename, VLAN re-tag). Proxmox auto-generates MAC only on first create;
  # subsequent applies keep the existing MAC unless Terraform explicitly changes it.
}

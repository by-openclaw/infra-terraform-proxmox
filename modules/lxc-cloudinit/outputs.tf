# Copyright (c) 2026 BY-SYSTEMS SRL. MIT License.
# SPDX-License-Identifier: MIT

output "vmid" {
  description = "Proxmox VMID assigned to the container"
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "name" {
  description = "Container short hostname"
  value       = var.name
}

output "fqdn" {
  description = "Container FQDN (name.dns_domain). Empty if dns_domain is unset."
  value       = var.dns_domain != "" ? "${var.name}.${var.dns_domain}" : var.name
}

output "ipv4_address" {
  description = "Static IPv4 (or 'dhcp')"
  value       = var.ipv4_address
}

output "ipv6_address" {
  description = "Static IPv6 (or 'dhcp' / empty)"
  value       = var.ipv6_address
}

output "tags" {
  description = "Proxmox tags applied"
  value       = concat(["env-${var.env}", "lxc", "cloudinit"], var.tags)
}

output "vm_id" {
  description = "Proxmox VM ID"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "VM name / Windows hostname"
  value       = proxmox_virtual_environment_vm.this.name
}

output "ip" {
  description = "Configured static IPv4 (CIDR)"
  value       = var.ip
}

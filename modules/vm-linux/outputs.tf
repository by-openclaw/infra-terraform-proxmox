output "vm_id" {
  value = proxmox_virtual_environment_vm.this.id
}

output "vm_name" {
  value = proxmox_virtual_environment_vm.this.name
}

output "ip_address" {
  description = "VM IP address (from cloud-init config)"
  value       = var.ip
}

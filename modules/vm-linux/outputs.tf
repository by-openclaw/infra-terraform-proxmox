output "vm_id" {
  description = "Proxmox VM ID assigned to this VM"
  value       = proxmox_vm_qemu.this.vmid
}

output "vm_name" {
  description = "Name of the created VM"
  value       = proxmox_vm_qemu.this.name
}

output "vm_ip" {
  description = "IP address assigned to the VM via cloud-init"
  value       = var.ip
}

output "target_node" {
  description = "Proxmox node on which the VM is deployed"
  value       = proxmox_vm_qemu.this.target_node
}

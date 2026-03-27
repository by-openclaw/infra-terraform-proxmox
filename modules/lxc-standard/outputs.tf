output "lxc_id" {
  description = "Proxmox LXC container ID"
  value       = proxmox_lxc.this.vmid
}

output "lxc_name" {
  description = "Hostname of the created LXC container"
  value       = proxmox_lxc.this.hostname
}

output "lxc_ip" {
  description = "IP address assigned to the LXC container"
  value       = var.ip
}

output "target_node" {
  description = "Proxmox node on which the LXC is deployed"
  value       = proxmox_lxc.this.target_node
}

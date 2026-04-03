output "zone_id" {
  description = "SDN zone identifier"
  value       = proxmox_sdn_zone_vlan.poc.id
}

output "vnet_ids" {
  description = "Map of VNet ID to VNet resource ID"
  value       = { for k, v in proxmox_sdn_vnet.vnets : k => v.id }
}

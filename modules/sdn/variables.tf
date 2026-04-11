variable "node_name" {
  description = "Proxmox node name to deploy SDN on (e.g., srv-proxmox-01)"
  type        = string
}

variable "zone_id" {
  description = "SDN zone identifier — must be environment name (e.g., prod, dev, test)"
  type        = string
  default     = "prod"
}

variable "bridge" {
  description = "VLAN-aware Linux bridge used as SDN uplink (must be vlan_aware=true)"
  type        = string
  default     = "vmbrAPPS"
}

variable "mtu" {
  description = "MTU for the SDN zone"
  type        = number
  default     = 1500
}

variable "vnets" {
  description = "Map of VNet definitions. Key = VNet ID (max 8 chars), value = VNet config."
  type = map(object({
    tag     = number
    alias   = string
    subnet  = string
    gateway = string
  }))
  default = {
    mgmt = {
      tag     = 310
      alias   = "Management"
      subnet  = "10.1.1.0/24"
      gateway = "10.1.1.1"
    }
    dmz = {
      tag     = 320
      alias   = "DMZ"
      subnet  = "10.1.2.0/24"
      gateway = "10.1.2.1"
    }
    svc = {
      tag     = 330
      alias   = "Services"
      subnet  = "10.1.3.0/24"
      gateway = "10.1.3.1"
    }
  }
}

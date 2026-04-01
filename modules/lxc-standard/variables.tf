variable "name" {
  description = "LXC container hostname — must follow convention: lxc-{service}-{env}-{seq:02d}"
  type        = string
}

variable "target_node" {
  description = "Proxmox node name to deploy the LXC on (e.g., srv-proxmox-poc-01)"
  type        = string
}

variable "ostemplate" {
  description = "Proxmox LXC OS template path (e.g., local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst)"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores to allocate to the LXC"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in MB to allocate to the LXC"
  type        = number
  default     = 512
}

variable "swap" {
  description = "Swap space in MB for the LXC (0 = no swap)"
  type        = number
  default     = 0
}

variable "disk" {
  description = "Root filesystem size (e.g., '8G')"
  type        = string
  default     = "8G"
}

variable "storage" {
  description = "Proxmox storage pool name for the LXC rootfs (e.g., poc-data)"
  type        = string
}

variable "network_bridge" {
  description = "Proxmox network bridge to attach the LXC NIC to (e.g., vmbrOOB, vmbrFAB)"
  type        = string
  default     = "vmbrOOB"
}

variable "ip" {
  description = "Static IP address in CIDR notation (e.g., 10.6.241.10/20)"
  type        = string
}

variable "gateway" {
  description = "Default gateway IP for the LXC network config"
  type        = string
}

variable "unprivileged" {
  description = "Run the LXC as unprivileged container (recommended: true)"
  type        = bool
  default     = true
}

variable "onboot" {
  description = "Start the LXC automatically when the Proxmox node boots"
  type        = bool
  default     = true
}

variable "ssh_keys" {
  description = "List of SSH public keys to inject into the LXC root account"
  type        = list(string)
  default     = []
}

variable "name" {
  description = "VM name — must follow convention: vm-{service}-{env}-{seq:02d}"
  type        = string
}

variable "target_node" {
  description = "Proxmox node name to deploy the VM on (e.g., srv-proxmox-poc-01)"
  type        = string
}

variable "clone" {
  description = "Name of the Proxmox template to clone from (e.g., debian-12-cloud)"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores to allocate to the VM"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in MB to allocate to the VM"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Disk size for the primary disk (e.g., '20G')"
  type        = string
  default     = "20G"
}

variable "storage" {
  description = "Proxmox storage pool name for the VM disk (e.g., poc-data)"
  type        = string
}

variable "network_bridge" {
  description = "Proxmox network bridge to attach the VM NIC to (e.g., vmbrMGMT)"
  type        = string
  default     = "vmbrMGMT"
}

variable "ip" {
  description = "Static IP address in CIDR notation for cloud-init (e.g., 10.6.240.10/20)"
  type        = string
}

variable "gateway" {
  description = "Default gateway IP for cloud-init network config"
  type        = string
}

variable "ci_user" {
  description = "Cloud-init default user (created by cloud-init on first boot)"
  type        = string
  default     = "debian"
}

variable "ssh_keys" {
  description = "List of SSH public keys to inject via cloud-init"
  type        = list(string)
  default     = []
}

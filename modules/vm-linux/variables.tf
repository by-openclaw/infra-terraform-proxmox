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
  description = "Proxmox network bridge to attach the VM NIC to (e.g., vmbrOOB)"
  type        = string
  default     = "vmbrOOB"
}

variable "ip" {
  description = "Static IP address in CIDR notation for cloud-init (e.g., 10.6.240.10/20)"
  type        = string
}

variable "gateway" {
  description = "Default gateway IP for cloud-init network config"
  type        = string
}

variable "dns" {
  description = "DNS server IP (usually same as gateway)"
  type        = string
  default     = "10.6.224.1"
}

variable "domain" {
  description = "DNS domain for FQDN (e.g. by-systems.arpa)"
  type        = string
  default     = "by-systems.arpa"
}

variable "keyboard_layout" {
  description = "Keyboard layout for the VM console (e.g., fr-be for Belgian)"
  type        = string
  default     = "fr-be"
}

variable "ci_user" {
  description = "Cloud-init default user (created by cloud-init on first boot)"
  type        = string
  default     = "by-systems"
}

variable "ci_password" {
  description = "Password for the cloud-init default user (for Proxmox web console access)"
  type        = string
  sensitive   = true
  default     = "<REDACTED:password>"
}

variable "ssh_keys" {
  description = "List of SSH public keys to inject via cloud-init"
  type        = list(string)
  default     = []
}

variable "env" {
  description = "Environment tier for this VM (prod/dev/test/staging/acc). prod = no env suffix in hostname (ADR-0010). Env is per-VM, not per-node."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "dev", "test", "staging", "acc"], var.env)
    error_message = "env must be one of: prod, dev, test, staging, acc."
  }
}

variable "tags" {
  description = "Additional Proxmox tags. env-{var.env} is always added automatically. No colons in tag values."
  type        = list(string)
  default     = ["linux"]
}

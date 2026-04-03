variable "name" {
  description = "LXC container hostname — must follow convention: lxc-{service}-{env}-{seq:02d}"
  type        = string
}

variable "target_node" {
  description = "Proxmox node name to deploy the LXC on (e.g., srv-proxmox-poc-01)"
  type        = string
}

variable "ostemplate" {
  description = "Proxmox LXC OS template path — must reference poc-iso storage (e.g., poc-iso:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst). Never use local:vztmpl."
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

variable "env" {
  description = "Environment tier for this LXC (prod/dev/test/staging/acc). prod = no env suffix in hostname (ADR-0010). Env is per-VM/LXC, not per-node."
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
  default     = ["lxc"]
}

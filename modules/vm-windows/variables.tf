variable "name" {
  description = "VM name = Windows hostname (cloudbase-init SetHostName). NetBIOS caps it at 15 chars."
  type        = string
  validation {
    condition     = length(var.name) <= 15
    error_message = "Windows computer names are limited to 15 characters (NetBIOS)."
  }
}

variable "target_node" {
  description = "Proxmox node name"
  type        = string
}

variable "clone" {
  description = "Windows template name to clone (built by ansible-platform roles/windows_template)"
  type        = string
}

variable "vmid" {
  description = "VM ID (0 = auto)"
  type        = number
  default     = 0
}

variable "env" {
  description = "Environment tier tag (dev/test/staging/acc/prod)"
  type        = string
}

variable "tags" {
  description = "Extra Proxmox tags"
  type        = list(string)
  default     = []
}

variable "cores" {
  description = "vCPU cores (single socket)"
  type        = number
  default     = 6
}

variable "cpu_type" {
  description = "CPU model. cpu=host panics multi-core VMs on the platform's hardware — keep the baseline."
  type        = string
  default     = "x86-64-v2-AES"
}

variable "numa_hostnode" {
  description = "Host NUMA node the guest's memory is bound to (policy=bind), e.g. \"0\". Empty = no binding."
  type        = string
  default     = ""
}

variable "memory" {
  description = "RAM in MB, dedicated (ballooning off: the template carries balloon=0 and no floating is set)"
  type        = number
  default     = 32768
}

variable "storage" {
  description = "Datastore for the OS disk and the cloud-init drive"
  type        = string
  default     = "local-zfs"
}

variable "disk_size" {
  description = "OS disk size, e.g. \"80G\" (>= the template's disk; growing it online is fine, Windows extends via cloudbase ExtendVolumes)"
  type        = string
  default     = "80G"
}

variable "network_bridge" {
  description = "Bridge"
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "VLAN tag (0 = none)"
  type        = number
  default     = 0
}

variable "ip" {
  description = "Static IPv4 in CIDR form, e.g. 10.0.0.10/24"
  type        = string
}

variable "gateway" {
  description = "IPv4 gateway"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
}

variable "domain" {
  description = "DNS search domain"
  type        = string
}

variable "ssh_keys" {
  description = "Public keys for Administrator. Written twice: by cloudbase to the profile's authorized_keys, and by first-boot user-data to administrators_authorized_keys (Windows sshd reads THAT one for members of the Administrators group)."
  type        = list(string)
}

variable "use_admin_key_userdata" {
  description = "Upload the first-boot #ps1 snippet that fills administrators_authorized_keys (needs provider SSH access to the node for snippet upload). Off = key SSH as Administrator will NOT work until configured another way."
  type        = bool
  default     = true
}

variable "agent_timeout" {
  description = "qemu-guest-agent wait on create. First boot runs the sysprep specialize pass + cloudbase-init before the agent answers."
  type        = string
  default     = "20m"
}

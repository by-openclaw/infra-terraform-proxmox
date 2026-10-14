# vm-windows

Windows Server VM cloned from an **ansible-platform `windows_template`** build
(sysprep-generalised, qemu-guest-agent + cloudbase-init inside, cloud-init drive
`ide2` with `citype=configdrive2`, `balloon=0`, `boot order=scsi0`).

What the module adds on top of the clone:

- **NUMA pinning** — `cpu_affinity` pins the vCPUs to one host node's cores and
  the `numa` block binds the guest's memory to the same `numa_hostnode`
  (`policy=bind`): the VM never crosses the QPI link ("fits as a VM, no freeze").
- **Ballooning off** — `memory.dedicated` only, the template carries `balloon=0`.
- **CPU `x86-64-v2-AES`** — `cpu=host` panics multi-core VMs on this platform's
  hardware (see ansible-platform memory/ADR notes).
- **First boot via cloudbase-init** (configdrive2): static IP/DNS, Administrator
  SSH keys — and the hostname via the user-data (Proxmox's configdrive2 metadata
  carries no hostname key, so SetHostName cannot act; the script renames to
  `name` and exits 1003, cloudbase's reboot-once convention), plus the same
  `#ps1` user-data fills
  `C:\ProgramData\ssh\administrators_authorized_keys` — Windows sshd reads THAT
  file for members of the Administrators group, not the profile's
  `authorized_keys`. The snippet uploads over SSH (provider `ssh {}` block).
- **No password anywhere** — Ansible sets Administrator's password from Vault
  once it is in over key SSH; Terraform never carries it.

Windows hostnames are NetBIOS-limited to 15 characters (validated).

Example: `environments/dev/svc-windows.tf`.

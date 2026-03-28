#cloud-config
# BY-SYSTEMS VM baseline — vendor data
# User + SSH keys are set via native Proxmox CI (visible in UI)
# This file handles: locale, timezone, keyboard, hostname, packages, sudo

hostname: ${hostname}
fqdn: ${hostname}.${domain}
manage_etc_hosts: true

locale: fr_BE.UTF-8
timezone: Europe/Brussels

keyboard:
  layout: be
  variant: ""

# Grant sudo to admin user (created via native CI user_account)
write_files:
  - path: /etc/sudoers.d/${username}
    content: "${username} ALL=(ALL) NOPASSWD:ALL\n"
    permissions: "0440"

package_update: true
package_upgrade: true

packages:
  - curl
  - wget
  - git
  - htop
  - unattended-upgrades
  - qemu-guest-agent
  - net-tools
  - sudo

runcmd:
  - systemctl enable qemu-guest-agent --now
  - echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  - sysctl -p

final_message: |
  Cloud-init complete on ${hostname}.
  User: ${username} | Locale: fr_BE | TZ: Europe/Brussels

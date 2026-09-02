################################################################################
# BY-SYSTEMS — Diagram rendering services (Kroki + drawio) — shared platform svc
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Stateless, shared diagram services (used by GitLab, docs, NetBox, admin portal…):
#   - Kroki (+ Mermaid companion) — diagrams-as-code API; PlantUML/Graphviz/Ditaa/
#     etc. are built into the main Kroki image, Mermaid runs as a companion.
#   - drawio (diagrams.net) — visual editor + embed.
# Internal-only API (server-to-server from GitLab et al.); drawio UI behind Traefik.
# Docker-in-LXC (same nested-Docker pattern as the other svc LXCs).
################################################################################

module "svc_diagrams" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-diagrams-01"
  vmid        = 570
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-diagrams", "kroki", "drawio", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 2
  memory             = 2048 # Kroki + Mermaid + drawio containers (JVM-ish; 2G headroom)
  disk_gb            = 12
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.220/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::220/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = ["10.1.3.1", "fd01:3::1"] # OPNsense resolver on SVC VLAN
  ssh_keys    = local.standard_ssh_keys
}

output "svc_diagrams" {
  description = "Diagram services LXC (Kroki + drawio) — shared platform service"
  value = {
    name = "lxc-diagrams-01"
    vmid = 570
    ipv4 = "10.1.3.220"
    ipv6 = "fd01:3::220"
    vlan = 1030
  }
}

################################################################################
# BY-SYSTEMS — Monitoring stack (Prometheus + Grafana — metrics + dashboards)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# Native Prometheus (TSDB + scraper) + Grafana (dashboards), systemd-managed, no
# nested Docker. Prometheus scrapes node-exporter on every host (fleet playbook) +
# key service exporters. Grafana sits behind Traefik + Authentik SSO (VPN-only) and
# wires two datasources: Prometheus (metrics) and the existing Loki (logs).
#
# STORAGE: metrics live on the root disk (Prometheus TSDB, ~30d retention). Unlike
# SeaweedFS/GitLab this holds no irreplaceable state — a rebuild re-scrapes the
# fleet — so no ZFS bind-mount; a comfortable 30 GB root covers TSDB + OS + Grafana.
#
# VMID 580 (LXC range; 550=seaweedfs, 560=gitlab, 570=diagrams, 571=jumpserver).
# Provisions the LXC only — Prometheus/Grafana/node-exporter + SSO + Traefik edge
# are installed/configured by the ansible-platform monitoring roles.
################################################################################

module "svc_monitoring" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-monitoring-01"
  vmid        = 580
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-monitoring", "prometheus", "grafana"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 2
  memory             = 4096 # Prometheus TSDB + Grafana headroom
  disk_gb            = 30   # OS + Prometheus TSDB (~30d) + Grafana
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.230/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::230/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = ["10.1.3.1", "fd01:3::1"] # OPNsense resolver on SVC VLAN
  ssh_keys    = local.standard_ssh_keys
}

output "svc_monitoring" {
  description = "Monitoring LXC (Prometheus + Grafana) — register in NetBox once up"
  value = {
    name = "lxc-monitoring-01"
    vmid = 580
    ipv4 = "10.1.3.230"
    ipv6 = "fd01:3::230"
    vlan = 1030
  }
}

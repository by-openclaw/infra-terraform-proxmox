################################################################################
# BY-SYSTEMS — Harbor (OCI container registry + Trivy scanning)
# Node: srv-proxmox-poc-01 | env=prod | SVC zone (vlan1030, 10.1.3.0/24)
#
# docker-compose stack in a nested unprivileged LXC (ansible: roles/docker +
# roles/harbor). Stateless-ish: image blobs -> SeaweedFS S3 (lxc-seaweedfs-01),
# metadata -> shared PostgreSQL (postgres_db: harbor), sessions -> Harbor's own
# bundled Redis. Fronted by Traefik (wildcard TLS) + Authentik OIDC. nesting=true
# (module default) runs Docker. Mirrors svc-authentik.tf. Static .240, dual-stack.
# Serves Docker today, Swarm/k3s images + Helm charts tomorrow (all OCI pulls).
################################################################################

module "svc_harbor" {
  source = "../../modules/lxc-cloudinit"

  name        = "lxc-harbor-01"
  vmid        = 590 # next free LXC decade after 580 (monitoring); verified free
  target_node = local.svc_node
  env         = "prod"
  os_type     = "debian"
  tags        = ["service", "vlan1030", "zone-svc", "role-registry", "harbor", "docker"]

  ostemplate_file_id = proxmox_virtual_environment_download_file.tmpl_debian_13.id
  cores              = 4
  memory             = 8192 # Trivy scanning headroom (drop to 4096 if Trivy disabled)
  disk_gb            = 30   # OS + docker + Harbor images + Trivy DB cache; blobs live on SeaweedFS S3
  storage            = "poc-data"

  network_bridge = local.svc_bridge
  vlan_tag       = 1030
  ipv4_address   = "10.1.3.240/24"
  ipv4_gateway   = "10.1.3.1"
  ipv6_address   = "fd01:3::240/64"
  ipv6_gateway   = "fd01:3::1"

  dns_domain  = local.svc_domain
  dns_servers = ["10.1.3.1", "fd01:3::1"]
  ssh_keys    = local.standard_ssh_keys
}

output "svc_harbor" {
  description = "Harbor LXC (OCI registry) — register in NetBox once up (services/0003 §1)"
  value = {
    name = "lxc-harbor-01"
    vmid = 590
    ipv4 = "10.1.3.240"
    ipv6 = "fd01:3::240"
    vlan = 1030
    fqdn = "lxc-harbor-01.by-research.be"
  }
}

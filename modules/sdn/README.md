# Module: sdn

Provisions Proxmox SDN VLAN zone and standard VNets for a PoC environment.

## What it creates

| Resource | ID | Details |
|---|---|---|
| SDN zone (VLAN type) | `prod` | Uplink: `vmbrAPPS`, MTU 1500, node `srv-proxmox-01` |
| VNet | `mgmt` | VLAN 310, `10.1.1.0/24`, gw `10.1.1.1` |
| VNet | `dmz` | VLAN 320, `10.1.2.0/24`, gw `10.1.2.1` |
| VNet | `svc` | VLAN 330, `10.1.3.0/24`, gw `10.1.3.1` |
| SDN applier | — | Triggers Proxmox SDN reload after all resources |

## Naming standard (ADR-0010 / ADR-0015)

- Zone name = environment (`prod`, `dev`, `test`)
- VNet names are environment-agnostic (`mgmt`, `dmz`, `svc`)
- Environment context lives in VM hostname + FQDN + cert — not in SDN primitives

## Usage

```hcl
module "sdn" {
  source = "../../modules/sdn"

  node_name = "srv-proxmox-01"
  zone_id   = "prod"
  bridge    = "vmbrAPPS"
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `node_name` | string | — | Proxmox node name |
| `zone_id` | string | `prod` | SDN zone identifier |
| `bridge` | string | `vmbrAPPS` | VLAN-aware uplink bridge |
| `mtu` | number | `1500` | MTU |
| `vnets` | map(object) | mgmt/dmz/svc | VNet definitions |

## Outputs

| Name | Description |
|---|---|
| `zone_id` | SDN zone identifier |
| `vnet_ids` | Map of VNet IDs |

## References

- ADR-0015: Network VLAN architecture
- platform-setup #78
- `infra-terraform-proxmox/environments/prod/main.tf`

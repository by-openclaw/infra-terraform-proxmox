# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0](https://github.com/by-openclaw/infra-terraform-proxmox/compare/v1.1.0...v1.2.0) (2026-06-02)


### Features

* **prod:** AdGuard VM + automation SSH key ([#19](https://github.com/by-openclaw/infra-terraform-proxmox/issues/19)) ([0340019](https://github.com/by-openclaw/infra-terraform-proxmox/commit/03400190867d075aa07561cf25bb462bed881e0e))
* **prod:** AdGuard VM + automation SSH key ([#19](https://github.com/by-openclaw/infra-terraform-proxmox/issues/19)) ([c3fad08](https://github.com/by-openclaw/infra-terraform-proxmox/commit/c3fad08c7a554a6b0243d8e229ddd37320d5b569))
* **prod:** shared DB/cache cluster + NetBox as LXC fleet (Phase A) ([19d9d9d](https://github.com/by-openclaw/infra-terraform-proxmox/commit/19d9d9d7a9f3b962cbecc7c0b4816bdca3a6a2dc))
* **prod:** shared DB/cache cluster + NetBox as LXC fleet (Phase A) ([cc9c124](https://github.com/by-openclaw/infra-terraform-proxmox/commit/cc9c124020b3e1450916142dec1c95d7c1a43ffe))
* **seed:** minimal bootstrap seed — 4 interfaces + SSH only ([#17](https://github.com/by-openclaw/infra-terraform-proxmox/issues/17)) ([3c56b64](https://github.com/by-openclaw/infra-terraform-proxmox/commit/3c56b649ab869baf60a7b0c298e28ccf213410db))
* **seed:** minimal bootstrap seed — 4 interfaces + SSH only ([#17](https://github.com/by-openclaw/infra-terraform-proxmox/issues/17)) ([34b47df](https://github.com/by-openclaw/infra-terraform-proxmox/commit/34b47df4cf94ea1aee6d061a5c309117acc964e7))
* **seed:** post-reseed security baseline — Unbound stats + NetFlow + Insight ([6f8a967](https://github.com/by-openclaw/infra-terraform-proxmox/commit/6f8a967e8337c432f16bdb10be0efac420f2d946))
* **seed:** setup-adguard-tls.sh — full TLS + DoT/DoH/DoQ + per-VLAN clients ([a587104](https://github.com/by-openclaw/infra-terraform-proxmox/commit/a587104fb67a8c374aba4ed988f90efde3d9abe0))
* **test:** AdGuard Home LXC scaffold (DNS chain Phase 2) — BLOCKED on cloud-init ([34ed907](https://github.com/by-openclaw/infra-terraform-proxmox/commit/34ed907f3173bf9f959f7862ca6679bac047806b))
* **test:** AdGuard Home VM (DNS chain Phase 2) — LIVE & verified ([ab9868b](https://github.com/by-openclaw/infra-terraform-proxmox/commit/ab9868b43b1be391d4db31a66cef5e6e9233a69c))
* **test:** re-address LXCs + AdGuard to ADR; static OOB IP in seed JSON ([ad255e7](https://github.com/by-openclaw/infra-terraform-proxmox/commit/ad255e765c49492544d63d5f7db37d1412addf63))
* **test:** replace AdGuard LXC scaffold with AdGuard VM — LIVE ([71d5ac9](https://github.com/by-openclaw/infra-terraform-proxmox/commit/71d5ac924901df12927624c76f32869799a3e8cc))
* **test:** switch LXCs to Proxmox-standard tarballs + AdGuard VM via terraform ([1f3a9bc](https://github.com/by-openclaw/infra-terraform-proxmox/commit/1f3a9bc2494130ea75ffa1ac61f6280875e3d2d1))


### Bug Fixes

* **agents:** link to doc-platform-core for agent contract files ([796433e](https://github.com/by-openclaw/infra-terraform-proxmox/commit/796433e584f52cc66056c68a4811925ede5cb64f))
* **agents:** remove unreachable OPERATING-STANDARD.md link ([c4813e1](https://github.com/by-openclaw/infra-terraform-proxmox/commit/c4813e14c253204f4855a9abb039fe1028fa5967))
* **agents:** restore OPERATING-STANDARD reference as plain text ([7d1b7bd](https://github.com/by-openclaw/infra-terraform-proxmox/commit/7d1b7bd248237998a255b0519a830563c988b463))
* **prod:** repair SDN module ref + align vm-opnsense bridges; re-enable prod CI ([880f498](https://github.com/by-openclaw/infra-terraform-proxmox/commit/880f498ad6f562587cf0bbcbb713f7a203f239b0))
* **prod:** repair SDN module ref + align vm-opnsense bridges; re-enable prod CI ([b6aa1a5](https://github.com/by-openclaw/infra-terraform-proxmox/commit/b6aa1a592a387479b6af86f699f422504304fc38))
* **seed:** disable dnsmasq + restart Kea in apply_security_baseline() ([e0fd4d8](https://github.com/by-openclaw/infra-terraform-proxmox/commit/e0fd4d8ec6eb339771736d6b60176a80ee24ff11))
* **seed:** provision FW disk at 20G + add WAN NICs + auto growfs ([c1791bf](https://github.com/by-openclaw/infra-terraform-proxmox/commit/c1791bf90c1b0bd64d7957f36166256f09ad0e6d))

## [1.1.0](https://github.com/by-openclaw/infra-terraform-proxmox/compare/v1.0.0...v1.1.0) (2026-04-12)


### Features

* **modules:** add env variable to all modules — env is per-VM not per-node ([3997309](https://github.com/by-openclaw/infra-terraform-proxmox/commit/39973094892d3cc3fd757d5b661bf372b165aa6c))
* **poc:** add mailcow VM to PoC environment ([e821482](https://github.com/by-openclaw/infra-terraform-proxmox/commit/e821482086ec0c6ac7b351ccfa7a3e558ca329e7))
* **poc:** add mailcow VM to PoC environment ([53767f6](https://github.com/by-openclaw/infra-terraform-proxmox/commit/53767f66d7158712b200ada5f263a529b1761bf1)), closes [#4](https://github.com/by-openclaw/infra-terraform-proxmox/issues/4)
* **vm-opnsense:** apply audit fixes + merge response ([8b6237e](https://github.com/by-openclaw/infra-terraform-proxmox/commit/8b6237eb77d7b0ffd650386c7cdb8a095282ac54))


### Bug Fixes

* **fmt:** terraform fmt — align comment whitespace ([93cef2f](https://github.com/by-openclaw/infra-terraform-proxmox/commit/93cef2f19e2d4cec85d50b298ac0408f90977549))
* **poc:** vm-opnsense-poc-01 memory 3072MB, disk 16GB — reflect actual install ([ba96334](https://github.com/by-openclaw/infra-terraform-proxmox/commit/ba96334d8041ca0a4d7e3d51d39ecfccacbf5ae5))
* run terraform fmt on all .tf files ([b707a27](https://github.com/by-openclaw/infra-terraform-proxmox/commit/b707a27afcea9688a83b212a2a78b7f447bb03d1)), closes [#6](https://github.com/by-openclaw/infra-terraform-proxmox/issues/6)
* terraform fmt alignment for CI ([eeb624f](https://github.com/by-openclaw/infra-terraform-proxmox/commit/eeb624fd06cd3fbdfeefa31dad012928ec15c95a))
* **vm-opnsense:** align module with ADR-0010 + Proxmox reality ([641902b](https://github.com/by-openclaw/infra-terraform-proxmox/commit/641902b4d3de7eab0d9fa0f21067c57c3bbf5a7e))
* **vm-opnsense:** use raw disk format for ZFS datastore compatibility ([17ab32f](https://github.com/by-openclaw/infra-terraform-proxmox/commit/17ab32f03d22d1859e56d654fa7c1b37e7fef81d))

## [1.0.0](https://github.com/by-openclaw/infra-terraform-proxmox/compare/v0.2.1...v1.0.0) (2026-04-11)


### ⚠ BREAKING CHANGES

* purge all poc references — rename to prod standard
* rename zone poc → prod, renumber VLANs to ADR-0032
* remove VM 101 (vm-opnsense-test-01), keep only VM 1100

### Features

* add test environment with vm-fw-test-01 (VMID 1100) ([ea079b9](https://github.com/by-openclaw/infra-terraform-proxmox/commit/ea079b941fd950088918639419e6478609052d2b))
* **poc:** add platform service VMs — step-ca, vault, vaultwarden, traefik, authentik, netbox, minio ([7a089c4](https://github.com/by-openclaw/infra-terraform-proxmox/commit/7a089c4d0d5281409ce3ca3b40ed8767fb54f626))
* **poc:** add shared postgres and redis VMs — one VM per service ([0a00f9a](https://github.com/by-openclaw/infra-terraform-proxmox/commit/0a00f9a7634313e5b74bc4eac1903a55a36b2356))
* **poc:** add vm-pihole-poc-01 — Pi-hole + Unbound DNS, DoT upstream :853, all VMs point to Pi-hole ([628593c](https://github.com/by-openclaw/infra-terraform-proxmox/commit/628593cfdb3fa6356561a1a6f63f505173303514))
* **poc:** apply finalized VM sizing from spec sheet ([35505ba](https://github.com/by-openclaw/infra-terraform-proxmox/commit/35505bab4cc54899a7f3a29057f98d9dd704bd22))
* purge all poc references — rename to prod standard ([eabe1db](https://github.com/by-openclaw/infra-terraform-proxmox/commit/eabe1dbd00f9cd62fa15ac1301a88a0da79bae11))
* remove VM 101 (vm-opnsense-test-01), keep only VM 1100 ([456fc44](https://github.com/by-openclaw/infra-terraform-proxmox/commit/456fc44f1c4f53fd648448fdb7d2cf7bf6fb07a7))
* rename zone poc → prod, renumber VLANs to ADR-0032 ([7d51d2c](https://github.com/by-openclaw/infra-terraform-proxmox/commit/7d51d2cd9954e32912bf0f04385a36761b9cd963))
* renumber test VLANs to ADR-0032, add all 9 segments ([d17d3e2](https://github.com/by-openclaw/infra-terraform-proxmox/commit/d17d3e2393b58a5a59bca3d1475740745ef4f9ae))
* **sdn:** deploy PoC SDN zone poc with VNets mgmt/dmz/svc ([7d173ea](https://github.com/by-openclaw/infra-terraform-proxmox/commit/7d173ea53a3b42daa8e7dd39add3dafa897c81ad))


### Bug Fixes

* **lxc:** update ostemplate var description to reference poc-iso not local ([8dabced](https://github.com/by-openclaw/infra-terraform-proxmox/commit/8dabced44ee7123ba038daaa9cd7cdede9110817))
* **opnsense:** update ISO to OPNsense 26.1.2 ([#8](https://github.com/by-openclaw/infra-terraform-proxmox/issues/8)) ([8bd76b9](https://github.com/by-openclaw/infra-terraform-proxmox/commit/8bd76b980c4e3b3e45a1d30b1c618472863018b5))
* **poc:** correct Proxmox API token comment — svc-rune@pve!terraform (was svc-terraform@pve!ci which does not exist) ([7c6d4be](https://github.com/by-openclaw/infra-terraform-proxmox/commit/7c6d4be801aaac62a8c45127a80095fc76bf26de))
* **poc:** replace env-prefixed VNet bridge names with agnostic SDN VNets ([8e7d839](https://github.com/by-openclaw/infra-terraform-proxmox/commit/8e7d83988ccfa224e56163ea03d1c5c2b68776f7))
* **poc:** resolve IP collision — vm-redis 10.6.225.20 → 10.6.225.18 ([7d9202a](https://github.com/by-openclaw/infra-terraform-proxmox/commit/7d9202a92f373698309dbcd2a29e823448f0cfb5))
* **poc:** update Pi-hole module comment — no Unbound sidecar, upstream=OPNsense Unbound DoT :853 ([2281dba](https://github.com/by-openclaw/infra-terraform-proxmox/commit/2281dbac384efdda4e0842ddb8605fb026744275))
* **poc:** use poc-iso for OPNsense ISO media ([bd7d04a](https://github.com/by-openclaw/infra-terraform-proxmox/commit/bd7d04a44fb2d1f6d27b135a3bad48eea0e81726))
* revert module rename (keeps VM 101 state), single SSH key ([c8af68f](https://github.com/by-openclaw/infra-terraform-proxmox/commit/c8af68f9f42ac04d9bb2ab2b773f225262e81069))
* **scripts:** update backup-state.py for ADR-0007 upload return dict ([b6b089b](https://github.com/by-openclaw/infra-terraform-proxmox/commit/b6b089b4be52e0d0c631af67e7259ee2f274cd67))
* SSH key comment svc-rune@by-systems.be (agnostic identity) ([00f3e0e](https://github.com/by-openclaw/infra-terraform-proxmox/commit/00f3e0eb9a37f869af362665158391de1a3b94dc))
* update lxc-standard network_bridge default from vmbrMGMT to vmbrOOB ([d870841](https://github.com/by-openclaw/infra-terraform-proxmox/commit/d8708414886bb39e716329e2dbf0ba7d3c8ebbb6))

## [Unreleased]

### Features

* **sdn:** add `modules/sdn-poc` — Proxmox SDN VLAN zone + VNets (mgmt/dmz/svc) + subnets + applier
* **poc:** wire `module.sdn` into `environments/poc/main.tf` as Layer -1 (pre-requisite for all VM networking)
* **poc:** update provider pin `~> 0.99` (resolved to 0.100.0, tested and validated)

### Fixes

* **sdn:** replace deprecated `proxmox_virtual_environment_sdn_*` aliases with short-form `proxmox_sdn_*` resources
* **proxmox:** update `TerraformRole` to include `SDN.Allocate + SDN.Audit` (was missing, caused 403)

### Applied

* SDN applied 2026-04-03 on `srv-proxmox-poc-01` — zone `poc`, VNets mgmt/dmz/svc, subnets, applier
* Refs: platform-setup #78, ADR-0015

---

## [0.2.1](https://github.com/by-openclaw/infra-terraform-proxmox/compare/v0.2.0...v0.2.1) (2026-03-30)


### Bug Fixes

* correct pull_request trigger in project-board-sync workflow ([a866fb7](https://github.com/by-openclaw/infra-terraform-proxmox/commit/a866fb7852285520f446568bba8e56af8f2668ab))
* terraform fmt provider.tf (double space before comment) ([161fa67](https://github.com/by-openclaw/infra-terraform-proxmox/commit/161fa67b651c13f475c9ef01ba0fc1f359f530fe))

## [Unreleased]

### Added
- `scripts/backup-state.py`: Backs up `terraform.tfstate` to Synology NAS `/by-terraform-state/<env>/`
- `scripts/tf.sh`: Terraform wrapper — auto-runs state backup after every `apply` or `destroy`

### Fixed
- OOB gateway corrected everywhere: `10.6.255.254` → `10.6.224.1` (pfSense) in all docs, READMEs, diagrams

### Changed
- `environments/poc/main.tf`: replaced stale `vnet-poc-*` bridge names with environment-agnostic SDN VNets `mgmt`, `dmz`, `svc`
- `environments/poc/main.tf`: `iso_storage` changed from `local` to `poc-iso`
- `modules/vm-opnsense/variables.tf`, `AGENTS.md`, `CLAUDE.md`, `RAID.md`: removed stale `vmbrPOC` language and aligned with `vmbrAPPS` trunk + SDN VNet model
- Locked storage rule: ISO / vztmpl media must live on `poc-iso`; never use `local`, `local-lvm`, or thin-LVM for ISO storage

## [0.2.0] — 2026-03-28

### Added
- `modules/vm-linux`: Reusable module for Linux VMs with cloud-init, VirtIO disk/NIC, qemu-guest-agent
- `modules/lxc-standard`: Reusable module for unprivileged LXC containers
- `environments/poc`: PoC environment — `vm-debian-bootstrap-test-01` (ID 100, 10.6.225.11) validated
- `providers.tf`: bpg/proxmox v0.99.0 (replaced telmate — incompatible with PVE 9)
- `versions.tf`: Terraform >= 1.5.0, provider pins
- `docs/variables-reference.md`: Full module input reference
- GitHub Actions CI: `terraform fmt -check` + `terraform validate` on PRs
- `.gitignore`: Excludes `*.tfvars`, `.terraform/`, tfstate files
- `assets/diagrams/`: PlantUML + ASCII architecture diagrams

### Validated
- `vm-debian-bootstrap-test-01` (ID 100, IP 10.6.225.11): SSH (Win11 + Rune VM keys), cloud-init, QEMU agent, locale, timezone all confirmed working
- `debian-12-cloud` template (VM 9000): serial port removed, clean baseline

[Unreleased]: https://github.com/by-openclaw/infra-terraform-proxmox/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/by-openclaw/infra-terraform-proxmox/releases/tag/v0.2.0

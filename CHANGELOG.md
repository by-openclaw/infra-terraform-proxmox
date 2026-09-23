# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.0](https://github.com/by-openclaw/infra-terraform-proxmox/compare/v1.5.0...v1.6.0) (2026-09-23)


### Features

* **collab:** lxc-collab-01 — Nextcloud collaboration backend (ONLYOFFICE, Talk HPB/TURN, recording, whiteboard) ([47979ec](https://github.com/by-openclaw/infra-terraform-proxmox/commit/47979ecca230d4e31c86962278a38556fa3b6808))
* **collab:** lxc-collab-01 — Nextcloud collaboration backend container (ONLYOFFICE, Talk HPB, recording, whiteboard) ([fe8d4a3](https://github.com/by-openclaw/infra-terraform-proxmox/commit/fe8d4a34c86af75034f88a5242d585985c702918))
* **opnsense-seed:** FAB fabric-MGMT interface (opt14/vtnet4, VLAN 600) in seed + VM definitions ([17eb53b](https://github.com/by-openclaw/infra-terraform-proxmox/commit/17eb53b8cb1b64df483f70676c5c65f0a9414e15))
* **opnsense-seed:** FAB interface (opt14/VLAN 600) + oob-admin genesis credential ([8c0a646](https://github.com/by-openclaw/infra-terraform-proxmox/commit/8c0a64625700a809113a5956948b6ed638710bd9))
* **opnsense-seed:** full config on the test FW — Telenet uplink UP by default, IPv6 allowed, WAN2 default gateways ([aa5d1c3](https://github.com/by-openclaw/infra-terraform-proxmox/commit/aa5d1c3149afc6a6af48f631c7e93d3168e7abbc))
* **opnsense-seed:** seed the oob-admin GENESIS credential, hashes computed at render time ([45e6c1a](https://github.com/by-openclaw/infra-terraform-proxmox/commit/45e6c1a34e5e7d1dceef4c68e9d07353a4df53f5))
* **opnsense-seed:** seed-driven VM hardware profiles + --check drift gate ([1517ed8](https://github.com/by-openclaw/infra-terraform-proxmox/commit/1517ed8a8be26286d5ec923841630dd025818182))
* **opnsense-seed:** seed-driven VM hardware profiles + --check drift gate (prod VM 100 asserted from code) ([aae0804](https://github.com/by-openclaw/infra-terraform-proxmox/commit/aae080415e3ffb8ad9c5e7122471eba283ede242))
* **opnsense-seed:** test FW gets its OWN Telenet identity (.220 / ::6, HA pool borrowed) + ISP-ALLOCATION.md ([c5e4546](https://github.com/by-openclaw/infra-terraform-proxmox/commit/c5e45467dc2f29b55150d11a4326759f6ef8ff0d))
* **prod:** CISO Assistant guest (lxc-grc-01) + repair the Terraform state backup ([431b370](https://github.com/by-openclaw/infra-terraform-proxmox/commit/431b37023f19630ee94e63027d431f040cbe92a2))
* **prod:** CISO Assistant guest (lxc-grc-01) + repair the Terraform state backup ([aae0e67](https://github.com/by-openclaw/infra-terraform-proxmox/commit/aae0e675601da48c2362ceba732c6965a5c85fd9))
* **prod:** lxc-jitsi-01 — Jitsi Meet (Docker-in-LXC, SVC 10.1.3.193) ([85d8ad5](https://github.com/by-openclaw/infra-terraform-proxmox/commit/85d8ad5341de8e8f8865748ab6bdfff8712b711f))
* **prod:** lxc-portainer-01 — dedicated guest for the container console ([22469dd](https://github.com/by-openclaw/infra-terraform-proxmox/commit/22469dd6509dd17580169e12c0d399be8349d2be))
* **prod:** lxc-portainer-01 — dedicated guest for the container console (2 vCPU / 2 GiB / 10 GiB, SVC) ([29aa1b7](https://github.com/by-openclaw/infra-terraform-proxmox/commit/29aa1b733b7e797554d9989312370d9b5da9df0b))
* **prod:** lxc-wazuh-01 — security monitoring guest ([10d8317](https://github.com/by-openclaw/infra-terraform-proxmox/commit/10d83173deaf7716da1a8fdd3465f9618f0c31fb))
* **prod:** lxc-wazuh-01 — security monitoring guest (4 vCPU / 8 GiB / 40 GiB, SVC) ([22e2201](https://github.com/by-openclaw/infra-terraform-proxmox/commit/22e22017edaed021c56ab2e5236ffe6cd9ad8c34))
* **prod:** vm-jitsi-01 — Jitsi Meet VM (SVC vlan1030, 10.1.3.193, vmid 507) ([592d33f](https://github.com/by-openclaw/infra-terraform-proxmox/commit/592d33f1057bb5c1ef5fed25e6bf11b5304ba465))
* **prod:** vm-k3s-01 — single-node k3s application platform (SVC, 4 vCPU / 8 GiB / 60 GiB) ([cc1804b](https://github.com/by-openclaw/infra-terraform-proxmox/commit/cc1804b5a18e29c4ce11d6dfd26f2ca0d9389724))
* **prod:** vm-k3s-01 — single-node k3s application platform (SVC) ([725874c](https://github.com/by-openclaw/infra-terraform-proxmox/commit/725874c9812e7f415fd0d901f276ff697d23fc25))
* **seed:** --apply-hw in-place hardware converge + FW VMs 3072 -&gt; 8192 MiB (Suricata sizing review) ([799b0b1](https://github.com/by-openclaw/infra-terraform-proxmox/commit/799b0b146a7f38547f173af3e0e2dc1bf76409d8))
* **seed:** --apply-hw in-place hardware converge + FW VMs 3072 → 8192 MiB (Suricata sizing review) ([3501ca6](https://github.com/by-openclaw/infra-terraform-proxmox/commit/3501ca6742ef4336ff228581a6214ef0443ba5be))
* **seed:** lab profile, and archive the renderer Ansible replaced ([4829f3b](https://github.com/by-openclaw/infra-terraform-proxmox/commit/4829f3bd08270a33e3cc938e8ada5416498f2e74))
* **seed:** lab profile, and archive the renderer Ansible replaced ([b74ea08](https://github.com/by-openclaw/infra-terraform-proxmox/commit/b74ea0882827ce0c46689a64839d00c62326cec6))
* **seed:** prod profiles carry the GUI alternate hostname and the wheel sudo policy ([b614e1f](https://github.com/by-openclaw/infra-terraform-proxmox/commit/b614e1fffa1fb178d2fb46637792a3e7c1271c2e))
* **seed:** prod profiles carry the GUI alternate hostname and the wheel sudo policy ([e3714cb](https://github.com/by-openclaw/infra-terraform-proxmox/commit/e3714cbcd448cce0983ecbb0d2d5e88b56a338fa))
* **seed:** prod profiles seed the WebGUI certificate slot (webgui_acme_fqdn) ([69d21c2](https://github.com/by-openclaw/infra-terraform-proxmox/commit/69d21c26617670b489e440677678f61b7694d440))
* **seed:** prod profiles seed the WebGUI certificate slot (webgui_acme_fqdn) ([84f62a9](https://github.com/by-openclaw/infra-terraform-proxmox/commit/84f62a94837b6cc5b23ad4183bf89b19fb95dceb))
* **seed:** the prod firewall keeps its hardware addresses across rebuilds ([fa2c3f6](https://github.com/by-openclaw/infra-terraform-proxmox/commit/fa2c3f69f422085410e6648761fa8922797f8ad2))
* **seed:** the prod firewall keeps its hardware addresses across rebuilds ([078457b](https://github.com/by-openclaw/infra-terraform-proxmox/commit/078457bad3c8b2b9fe301705c16a469a730c8c15))
* **seed:** throwaway scratch profile to prove the provisioning path ([#93](https://github.com/by-openclaw/infra-terraform-proxmox/issues/93)) ([00f23e3](https://github.com/by-openclaw/infra-terraform-proxmox/commit/00f23e3e1d8e53fc40dd72ba8fbdd0ba86a7b7f0))
* **seed:** throwaway scratch profile to prove the provisioning path ([#93](https://github.com/by-openclaw/infra-terraform-proxmox/issues/93)) ([ab06567](https://github.com/by-openclaw/infra-terraform-proxmox/commit/ab06567c221b183951aeb525e9338b7eaed52537))
* **seed:** track the profiles the prod cutover was built from ([15f8dd1](https://github.com/by-openclaw/infra-terraform-proxmox/commit/15f8dd1c5e947cd2d29f9fd6a04f79e9d9fdf6e1))
* **seed:** track the profiles the prod cutover was built from ([273eb71](https://github.com/by-openclaw/infra-terraform-proxmox/commit/273eb71b3c9df7fc0bbf5790d527e15ede873d2a))


### Bug Fixes

* **dns:** create guests pointing at AdGuard, not the firewall ([47c7518](https://github.com/by-openclaw/infra-terraform-proxmox/commit/47c751842850df087a2854f37cb842b1199d5633))
* **dns:** create guests pointing at AdGuard, not the firewall ([16ea586](https://github.com/by-openclaw/infra-terraform-proxmox/commit/16ea586e8d31112520bda777738e04ec442abc2e))
* **jitsi:** 2 cores (multi-core cold-clone boot panic on the Xeon; 4→2 boots reliably) ([ad2d673](https://github.com/by-openclaw/infra-terraform-proxmox/commit/ad2d67344e185deb39b27c8311f9300ed0e32b09))
* **jitsi:** deploy as Docker-in-LXC (508), not a VM — avoids the old-Xeon cold-clone VM boot flake ([5e1f7c8](https://github.com/by-openclaw/infra-terraform-proxmox/commit/5e1f7c8b459bd8f4aa6894a81c6f7468227f509c))
* **opnsense-seed:** oob-admin shell=/bin/sh (identity/0004 §6, IDN-31) ([8c27ca5](https://github.com/by-openclaw/infra-terraform-proxmox/commit/8c27ca530fac37b1c3427ec73224c007699a8aa7))
* **opnsense-seed:** oob-admin shell=/bin/sh (IDN-31) ([9554d8e](https://github.com/by-openclaw/infra-terraform-proxmox/commit/9554d8e8a43684b9a0492025421e40758e05d9c3))
* **opnsense-seed:** test FW ISP NICs link_down by default — never a duplicate of prod's Telenet identity ([90ebb31](https://github.com/by-openclaw/infra-terraform-proxmox/commit/90ebb310c799a6c338dc555aee4e4b3b231f382b))
* **opnsense-seed:** test FW ISP NICs link_down by default — never a duplicate of prod's Telenet identity ([d5b908b](https://github.com/by-openclaw/infra-terraform-proxmox/commit/d5b908bd19eab19a10b6c2b82d4aed4dc3f35d48))
* **opnsense-seed:** test FW Telenet NIC link_down by default — boot-time ARP poisons the shared prod CPE ([d06dc6d](https://github.com/by-openclaw/infra-terraform-proxmox/commit/d06dc6d8ccaf2b12659b46fac37843c3f3359850))
* **opnsense-seed:** test LAN/trunk descriptions identical to prod ([2b114f0](https://github.com/by-openclaw/infra-terraform-proxmox/commit/2b114f0007f4c1f4015930120f2921f69a558f04))
* **opnsense-seed:** test LAN/trunk descriptions identical to prod (OOB / LAN_TRUNK) ([6916ea9](https://github.com/by-openclaw/infra-terraform-proxmox/commit/6916ea9d2147384ab051accc70a0777dfa75ffa9))
* **opnsense-seed:** WAN interface + gateway names identical to prod live ([9e19779](https://github.com/by-openclaw/infra-terraform-proxmox/commit/9e19779a9db7602cdcd27b6cfe9782baf559b41e))
* **opnsense-seed:** WAN names identical to prod live (WAN_PROXIMUS/WAN_TELENET, WAN_TELENET_GW*) ([1d03e8b](https://github.com/by-openclaw/infra-terraform-proxmox/commit/1d03e8b905171ba59684dece656a219ab6f0a9ff))
* **seed:** drop &lt;timeservers&gt; so a fresh boot does not start legacy ntpd ([baa6e54](https://github.com/by-openclaw/infra-terraform-proxmox/commit/baa6e544f66b5176c96b4b414db3d89e498b0bb7))
* **seed:** drop &lt;timeservers&gt; so a fresh boot does not start legacy ntpd ([5c12ea9](https://github.com/by-openclaw/infra-terraform-proxmox/commit/5c12ea9ababcbbdd32dbfc4541475e1d7fdadd75)), closes [#92](https://github.com/by-openclaw/infra-terraform-proxmox/issues/92)
* **svc-traefik:** 2 vCPU / 2 GiB — the reverse proxy terminates every HTTPS request of the platform; 1 vCPU was the choke point ([2b9bb64](https://github.com/by-openclaw/infra-terraform-proxmox/commit/2b9bb6454db2248a8191aaeb726a6ce6584c0910))
* **svc-traefik:** 2 vCPU / 2 GiB for the reverse proxy ([36eec10](https://github.com/by-openclaw/infra-terraform-proxmox/commit/36eec10c6a7460f6678b5793e276e873d2404c51))
* **vm-linux:** cloud-init user is by-research (the OOB/local admin identity) — never the retired by-systems bootstrap account ([76d16fb](https://github.com/by-openclaw/infra-terraform-proxmox/commit/76d16fb18bbed246ccc63583b1402f71311ec541))
* **vm-linux:** cloud-init user is by-research, not the retired by-systems account ([d557e43](https://github.com/by-openclaw/infra-terraform-proxmox/commit/d557e43f8d7f3dceda86e8ecf226453d3fb897c3))
* **vm-linux:** ignore the template-set operating_system (imported VMs planned l26 → null) ([4de38d5](https://github.com/by-openclaw/infra-terraform-proxmox/commit/4de38d55cd56e5a5c369ca69ff13a782473f1e89))
* **vm-linux:** ignore the template-set operating_system on VMs ([41b4970](https://github.com/by-openclaw/infra-terraform-proxmox/commit/41b4970c5c0f6b37ec8aa943d1befd6ebc34467f))
* **vm-linux:** stop first-boot dist-upgrade + 15m agent wait — healthy clones no longer look dead ([220298e](https://github.com/by-openclaw/infra-terraform-proxmox/commit/220298ed8d049eda0e9272270f06a1180425d375))
* **vm-linux:** stop first-boot dist-upgrade + 15m agent wait — healthy clones no longer look dead ([4881ed5](https://github.com/by-openclaw/infra-terraform-proxmox/commit/4881ed519a7004b542fe0cbeb77f826e88926923))

## [1.5.0](https://github.com/by-openclaw/infra-terraform-proxmox/compare/v1.4.0...v1.5.0) (2026-09-04)


### Features

* **crowdsec:** provision lxc-crowdsec-01 (central LAPI/engine) ([47e45bd](https://github.com/by-openclaw/infra-terraform-proxmox/commit/47e45bda5c7582171bbccbade87ecd8c85daaec9))
* **crowdsec:** provision lxc-crowdsec-01 (central LAPI/engine) ([e85b285](https://github.com/by-openclaw/infra-terraform-proxmox/commit/e85b2851fea5672911db767e9f4dd5ab12fadd11))
* **gitlab-runner:** provision runner VM + fix vm-linux boot_order ([176ed58](https://github.com/by-openclaw/infra-terraform-proxmox/commit/176ed580d0a7b93f740530ee04289c946ef0303f)), closes [#8](https://github.com/by-openclaw/infra-terraform-proxmox/issues/8)
* **gitlab:** GitLab CE server LXC + CI runner VM + reliable VM boot ([#8](https://github.com/by-openclaw/infra-terraform-proxmox/issues/8)) ([edbf008](https://github.com/by-openclaw/infra-terraform-proxmox/commit/edbf008fcb4ffaf2961b151754fc6e3e0f70725d))
* **gitlab:** provision lxc-gitlab-01 (vmid 560, SVC 10.1.3.210) ([73beab0](https://github.com/by-openclaw/infra-terraform-proxmox/commit/73beab08f31383f9e1678f8594c3a9fc2e9d3a59)), closes [#8](https://github.com/by-openclaw/infra-terraform-proxmox/issues/8)
* **harbor:** lxc-harbor-01 guest — OCI registry (VMID 590, SVC .240) ([8a4691f](https://github.com/by-openclaw/infra-terraform-proxmox/commit/8a4691f48124a7258646e6752fb40bd92b8ca3af))
* **harbor:** lxc-harbor-01 guest (deployed + live) ([13cdeb1](https://github.com/by-openclaw/infra-terraform-proxmox/commit/13cdeb11b78af124c54193b9c119ebc3d2f6d6e2))
* **monitoring:** provision lxc-monitoring-01 (VMID 580, SVC 10.1.3.230) ([e882f70](https://github.com/by-openclaw/infra-terraform-proxmox/commit/e882f70fb0701e463917d688636a08338c332ee5))
* **opnsense-seed:** Authentik LDAP auth server (svc-ldap-prod) + platform-admins in the seed ([87943e0](https://github.com/by-openclaw/infra-terraform-proxmox/commit/87943e06c79b0bcee3e7c09290bffa55919a8bae))
* **opnsense-seed:** Authentik LDAP auth server in the seed (binddn svc-ldap-prod), platform-admins group, authmode ([d10fb68](https://github.com/by-openclaw/infra-terraform-proxmox/commit/d10fb687373354cfc882b9cf349709be3f5e4d68))
* **opnsense-seed:** by-research break-glass user + fabric path fixes (FW-4b) ([75b4bb7](https://github.com/by-openclaw/infra-terraform-proxmox/commit/75b4bb7c07e5d46108af4394f6bb35008a511fa6))
* **opnsense-seed:** by-research break-glass user + fabric path fixes (FW-4b) ([048e975](https://github.com/by-openclaw/infra-terraform-proxmox/commit/048e975e7ef4840737110996a5cc28b3711bba52))
* **opnsense-seed:** svc-ansible-prod in, by-rune out (naming/0002 §3) ([43f4ef3](https://github.com/by-openclaw/infra-terraform-proxmox/commit/43f4ef3aa270974e690f0f7e5f4026e943670219))
* **opnsense-seed:** svc-ansible-prod replaces by-rune (naming/0002 §3) ([a32c54c](https://github.com/by-openclaw/infra-terraform-proxmox/commit/a32c54c09365a34a4dfcfd1863a67beb1107fbf4))
* **pbs:** provision vm-pbs-01 (VMID 103, SVC 10.1.3.222) — PBS 4 backup server ([e23e771](https://github.com/by-openclaw/infra-terraform-proxmox/commit/e23e771d4eed68e3bec7c1b35cd3505745445cee))
* **pbs:** provision vm-pbs-01 (VMID 103, SVC 10.1.3.222) — PBS 4 backup server ([c58fb77](https://github.com/by-openclaw/infra-terraform-proxmox/commit/c58fb776f42d741db844cb89e7e00a9c7bfdb35d))
* **prod:** lxc-pgsql-02 — Postgres HA replica guest (VMID 511, 10.1.3.111) ([d345fa6](https://github.com/by-openclaw/infra-terraform-proxmox/commit/d345fa67b6f2ad85d4d0933eb5376c0c3b351ab2))
* **prod:** lxc-pgsql-02 — Postgres HA replica guest (VMID 511, 10.1.3.111) ([8f44f0a](https://github.com/by-openclaw/infra-terraform-proxmox/commit/8f44f0a189c6ba63006166325c2106c22dfa8929))
* **prod:** lxc-stepca-01 — internal CA guest (VMID 506, 10.1.3.192) ([10182cf](https://github.com/by-openclaw/infra-terraform-proxmox/commit/10182cf813292b838e2766f56ce2eb110aa919ca))
* **prod:** lxc-stepca-01 — internal CA guest (VMID 506, 10.1.3.192) ([94c4181](https://github.com/by-openclaw/infra-terraform-proxmox/commit/94c4181810f2dc2c5d86a9d3c5a4530e8915e251))
* **prod:** lxc-verdaccio-01 — npm registry guest (VMID 505, 10.1.3.191) ([062dd52](https://github.com/by-openclaw/infra-terraform-proxmox/commit/062dd52ef678e936ff38d7e28bdd2220eaa09046))
* **prod:** lxc-verdaccio-01 — npm registry guest (VMID 505, 10.1.3.191) ([c275d76](https://github.com/by-openclaw/infra-terraform-proxmox/commit/c275d763944d1d89196bbb7b69d0f8e87befeb18))
* **prod:** lxc-warden-01 — boot-time orchestrator ([a2b0f2f](https://github.com/by-openclaw/infra-terraform-proxmox/commit/a2b0f2fbb78a3c4f44c70b62e1a7a3673f176e38))
* **prod:** lxc-warden-01 — boot-time platform orchestrator (vault unseal + cold-start verify) ([1305aa6](https://github.com/by-openclaw/infra-terraform-proxmox/commit/1305aa61c809af237291a856bca8e69e8bc0b27c))
* **prod:** mailcow mail-server VM (vm-mailcow-01, DMZ) ([f3a0011](https://github.com/by-openclaw/infra-terraform-proxmox/commit/f3a00117a85a5e7e885c8d024136616a573c476d))
* **prod:** mailcow mail-server VM (vm-mailcow-01, DMZ) + cpu_type fix ([cb352f2](https://github.com/by-openclaw/infra-terraform-proxmox/commit/cb352f20a6492f576bcd00b1a770e5ae570bcb5a))
* **seaweedfs:** provision lxc-seaweedfs-01 (small root, Ansible ZFS data mount) ([d73bd60](https://github.com/by-openclaw/infra-terraform-proxmox/commit/d73bd6008048aa1b1a9294a8c27f39afaa8e632e))
* **seaweedfs:** provision lxc-seaweedfs-01 (small root; data on Ansible ZFS mount) ([7825012](https://github.com/by-openclaw/infra-terraform-proxmox/commit/78250126d92bc07a399e1b5988a190f2abde8b13))
* **seed:** enable WebGUI access log + confirm NetFlow covers all interfaces (closes [#23](https://github.com/by-openclaw/infra-terraform-proxmox/issues/23)) ([0ab1986](https://github.com/by-openclaw/infra-terraform-proxmox/commit/0ab19861cbd2acb3a1f889acfe42ed54337f8789))
* **seed:** enable WebGUI access log in baseline (httpaccesslog) — closes [#23](https://github.com/by-openclaw/infra-terraform-proxmox/issues/23) ([8df3115](https://github.com/by-openclaw/infra-terraform-proxmox/commit/8df311501a34d4275b647e0c268c572d0c3ddbc6))
* **vm-linux:** persistent journald so boot failures are diagnosable ([7681c92](https://github.com/by-openclaw/infra-terraform-proxmox/commit/7681c922ac2ca1c3194337c4f1b4441f951158f3)), closes [#8](https://github.com/by-openclaw/infra-terraform-proxmox/issues/8)


### Bug Fixes

* **gitlab-runner:** revert vendor_data — guest config moves to Ansible ([54802a0](https://github.com/by-openclaw/infra-terraform-proxmox/commit/54802a00e2035ef4343182ec61f900403397f2a0)), closes [#8](https://github.com/by-openclaw/infra-terraform-proxmox/issues/8)
* **prod:** restore svc-diagrams + svc-jumpserver definitions — plan wanted to DESTROY both guests ([f3e532d](https://github.com/by-openclaw/infra-terraform-proxmox/commit/f3e532d10325f1f5186a99f959452f8f23e49b26))
* **prod:** restore svc-diagrams + svc-jumpserver definitions — plan wanted to DESTROY both guests ([d850eab](https://github.com/by-openclaw/infra-terraform-proxmox/commit/d850eab6a16a1cce5ac1b794b0c208eb042dee19))
* **prod:** terraform fmt svc-pbs.tf ([ab51ad6](https://github.com/by-openclaw/infra-terraform-proxmox/commit/ab51ad6386f03e50a9ef84a4b2e9266042d08c71))
* **prod:** terraform fmt svc-pbs.tf (pre-existing; broke CI validate) ([c30f97b](https://github.com/by-openclaw/infra-terraform-proxmox/commit/c30f97bdea3eef961a0838000466feaa90efa1c2))
* **seaweedfs:** 2048-&gt;4096 MB — OOM-killed during nightly PBS-&gt;S3 backup burst ([92b9134](https://github.com/by-openclaw/infra-terraform-proxmox/commit/92b9134b8d4a1a0418f3913673699c2d2bae39da))
* **seaweedfs:** 2048-&gt;4096 MB — OOM-killed during nightly PBS-&gt;S3 backup burst ([a25c5c7](https://github.com/by-openclaw/infra-terraform-proxmox/commit/a25c5c7efad2216173342da51b1c7a3f6ee0da98))
* **seed:** align interface idents to live FW + ansible (VLANs opt2-11, WANs opt12-13) ([c99e428](https://github.com/by-openclaw/infra-terraform-proxmox/commit/c99e428dea179e60c8c7b5a338466bec813f3ecc))
* **seed:** align interface idents to live FW + ansible (VLANs opt2-11, WANs opt12-13) — part of [#21](https://github.com/by-openclaw/infra-terraform-proxmox/issues/21) ([2993033](https://github.com/by-openclaw/infra-terraform-proxmox/commit/29930331267f4fb1280dc6d7b4a10b883a7bda3d))
* **vm-linux:** add cpu_type var; use stable model for mailcow VM (panic fix) ([ceae378](https://github.com/by-openclaw/infra-terraform-proxmox/commit/ceae378eab1b8514c275e3a69b2c9d079a0838f9))
* **vm-linux:** auto-reboot guests on kernel panic (old-host boot flakiness) ([5ea0b64](https://github.com/by-openclaw/infra-terraform-proxmox/commit/5ea0b64dc24267e573c0e9a8fa276104facfde92)), closes [#8](https://github.com/by-openclaw/infra-terraform-proxmox/issues/8)

## [1.4.0](https://github.com/by-openclaw/infra-terraform-proxmox/compare/v1.3.0...v1.4.0) (2026-06-08)


### Features

* **prod:** minimal cluster foundation LXCs — Traefik (DMZ) + Postgres + Redis ([26d7bc1](https://github.com/by-openclaw/infra-terraform-proxmox/commit/26d7bc1b1c3397cb71d9dbffdc0afeaadea04812))
* **svc:** add NetBird CE VPN LXC (lxc-netbird-01, SVC .181) ([de86421](https://github.com/by-openclaw/infra-terraform-proxmox/commit/de864217333f32ddd403ab98d2d40e4203cb748e)), closes [#45](https://github.com/by-openclaw/infra-terraform-proxmox/issues/45)
* **svc:** add Nextcloud LXC (lxc-nextcloud-01, SVC .170, Contabo S3) ([528c23f](https://github.com/by-openclaw/infra-terraform-proxmox/commit/528c23ff208949a6a7d72ca989e309ee9cc780f2)), closes [#41](https://github.com/by-openclaw/infra-terraform-proxmox/issues/41)
* **svc:** Authentik nested LXC (lxc-authentik-01, SVC) ([2f560c0](https://github.com/by-openclaw/infra-terraform-proxmox/commit/2f560c0b0ce1442098d6c2dfdc7e8d494af1c3e0))
* **svc:** Authentik nested LXC (lxc-authentik-01, SVC) for Docker SSO/IdP ([874968e](https://github.com/by-openclaw/infra-terraform-proxmox/commit/874968ebf6e2a5aa62c00f2c89886746ba974218)), closes [#33](https://github.com/by-openclaw/infra-terraform-proxmox/issues/33)
* **svc:** NetBird CE VPN LXC (lxc-netbird-01, SVC .181) — replaces defguard ([1c30699](https://github.com/by-openclaw/infra-terraform-proxmox/commit/1c3069902163f1a219fca8b0c884fecbdea38879))
* **svc:** NetBox nested LXC (lxc-nbox-01, SVC) ([f5b9727](https://github.com/by-openclaw/infra-terraform-proxmox/commit/f5b9727f12f7ff44b89b9da52edf2f16ea62e83e))
* **svc:** NetBox nested LXC (lxc-nbox-01, SVC) for Docker IPAM/SoT ([8d797dd](https://github.com/by-openclaw/infra-terraform-proxmox/commit/8d797dda75b21b93cbf0c7e58cf305f2ce6d3b62)), closes [#37](https://github.com/by-openclaw/infra-terraform-proxmox/issues/37)
* **svc:** Nextcloud LXC (lxc-nextcloud-01, SVC .170, Contabo S3 primary) ([e167311](https://github.com/by-openclaw/infra-terraform-proxmox/commit/e1673119d3611ce23223d532f1bfcc4d160ffe2f))
* **svc:** pgAdmin nested LXC (lxc-pgadmin-01, SVC) ([7195346](https://github.com/by-openclaw/infra-terraform-proxmox/commit/7195346fc265536ddcf44907c8f795a3cf3dbcb2))
* **svc:** pgAdmin nested LXC (lxc-pgadmin-01, SVC) for Docker-hosted DB admin ([166accc](https://github.com/by-openclaw/infra-terraform-proxmox/commit/166accce6ac3b6fac9f8fd09b0381a111c7cc18e)), closes [#31](https://github.com/by-openclaw/infra-terraform-proxmox/issues/31)
* **svc:** provision lxc-vaultwarden-01 (Vaultwarden password manager) ([d1dc3b8](https://github.com/by-openclaw/infra-terraform-proxmox/commit/d1dc3b8b5d4549dca4cac0fa2024c976561a3ddb)), closes [#39](https://github.com/by-openclaw/infra-terraform-proxmox/issues/39)
* **svc:** provision lxc-vaultwarden-01 (Vaultwarden) ([a36ab8d](https://github.com/by-openclaw/infra-terraform-proxmox/commit/a36ab8d98fcb3d80fa0f56cc75597a80aa7722a3))
* **svc:** Vault nested LXC (lxc-vault-01, SVC) ([cd611f9](https://github.com/by-openclaw/infra-terraform-proxmox/commit/cd611f9c72980d0bca724324f37483ebdbf4f506))
* **svc:** Vault nested LXC (lxc-vault-01, SVC) for Docker secrets backend ([94dbf06](https://github.com/by-openclaw/infra-terraform-proxmox/commit/94dbf0681d25e56b4a5d985a24448c39b834e333)), closes [#33](https://github.com/by-openclaw/infra-terraform-proxmox/issues/33)


### Bug Fixes

* **prod:** reconcile terraform with live FW + AdGuard (defuse drift landmine) ([88576b3](https://github.com/by-openclaw/infra-terraform-proxmox/commit/88576b37d6f572dad4fd0cc1be93ea2fb5b979c9))
* **prod:** unmanage seed-provisioned FW VM from terraform ([#27](https://github.com/by-openclaw/infra-terraform-proxmox/issues/27) v2 — defuse drift permanently) ([1e0c39e](https://github.com/by-openclaw/infra-terraform-proxmox/commit/1e0c39e9f452e2e34ac72816f29d8e84e91f9ed5))
* **prod:** unmanage seed-provisioned FW VM from terraform ([#27](https://github.com/by-openclaw/infra-terraform-proxmox/issues/27) v2) ([c63984e](https://github.com/by-openclaw/infra-terraform-proxmox/commit/c63984e4a35afaf4ceef1da53f9e0b77a07dc032))

## [1.3.0](https://github.com/by-openclaw/infra-terraform-proxmox/compare/v1.2.0...v1.3.0) (2026-06-04)


### Features

* **seed:** add full VLAN set to vm-opns-01 base seed ([#21](https://github.com/by-openclaw/infra-terraform-proxmox/issues/21)) ([431e1bb](https://github.com/by-openclaw/infra-terraform-proxmox/commit/431e1bb5c225b6bbbffd6d177b330f39679abe9b))
* **seed:** render NetFlow/Insight capture block from slot_map ([#23](https://github.com/by-openclaw/infra-terraform-proxmox/issues/23)) ([a62ad0e](https://github.com/by-openclaw/infra-terraform-proxmox/commit/a62ad0e18fbb5cbdb1d11b035e59ea6b2e46d48b))
* **seed:** render WAN2 Telenet in vm-opns-01 base seed ([#21](https://github.com/by-openclaw/infra-terraform-proxmox/issues/21)) ([a3c1583](https://github.com/by-openclaw/infra-terraform-proxmox/commit/a3c158364ee4383a84795e6cb887ecc513b58908))
* **seed:** render WAN2 Telenet in vm-opns-01 base seed ([#21](https://github.com/by-openclaw/infra-terraform-proxmox/issues/21)) ([3833a86](https://github.com/by-openclaw/infra-terraform-proxmox/commit/3833a86b078f0e3e9a0b40394887ed820be78f38))


### Bug Fixes

* **seed:** DNS search domain from vault secret, not hardcoded ([5bb1411](https://github.com/by-openclaw/infra-terraform-proxmox/commit/5bb141186e799c2088e4af63a1490589104f2799))
* **seed:** drop WAN_PROXIMUS_Parent — it breaks PPPoE auth ([#21](https://github.com/by-openclaw/infra-terraform-proxmox/issues/21)) ([e760f62](https://github.com/by-openclaw/infra-terraform-proxmox/commit/e760f62f10df6ad39ff4d32aabf831ec5e9eab8e))
* **seed:** OOB IPv4-only, no gateway — match pfSense01 ([#21](https://github.com/by-openclaw/infra-terraform-proxmox/issues/21)) ([2f781e6](https://github.com/by-openclaw/infra-terraform-proxmox/commit/2f781e66cbd1009b6b9e71d9eb308bcf7b6f64a3))
* **seed:** WAN mss=1452 + OOB dual-stack static IPv6 (no gateway) ([#21](https://github.com/by-openclaw/infra-terraform-proxmox/issues/21)) ([7812bae](https://github.com/by-openclaw/infra-terraform-proxmox/commit/7812bae9376abef4b3e2c5f8b0ed0a7c75561c34))

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

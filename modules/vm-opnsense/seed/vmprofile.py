#!/usr/bin/env python3
# Copyright (c) BY-SYSTEMS SRL
# SPDX-License-Identifier: Apache-2.0
"""Seed-driven VM hardware profile for the OPNsense firewalls (prod + test).

The FW VMs are deliberately NOT Terraform-managed (environments/prod/main.tf,
issue #27: bpg cannot model the 1 MB virtio1 config-import disk; a phantom-disk
drift would revert the running firewall on apply). The SEED pipeline owns the
hardware instead — and the definition must live in code, not in `qm set`
history. Each seed JSON carries a ``vm`` block:

    "vm": {
      "vmid": 100, "name": "vm-opns-01", "node": "srv-proxmox-poc-01", "env": "prod",
      "onboot": 1, "agent_enabled": true, "cores": 2, "memory": 3072,
      "tags": "layer0;opnsense;env-prod;seed-nano",
      "uplinks": {"proximus": true, "telenet": true},
      "nics": {"net0": "vmbrAPPS", "net1": "vmbrOOB", "net2": "vmbrWAN1",
               "net3": "vmbrWAN2", "net4": "vmbrFAB"}
    }

Two consumers in recreate-and-seed.py:
  * desired_config()  -> the `qm create` payload (recreate flow, test FW by default)
  * check_drift()     -> a NON-DESTRUCTIVE plan-like gate: live `qm config` vs the
                         code definition (name/cpu/memory/machine/tags/onboot/agent/
                         NIC bridges + link state/disks). Exit code 2 on drift.
                         This is how prod's hardware (e.g. net4 -> vmbrFAB) is
                         asserted from code without ever touching the running FW.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

DEFAULTS = {
    "node": "srv-proxmox-poc-01",
    "onboot": 0,
    "agent_enabled": True,
    "cores": 2,
    "memory": 3072,
    "cpu": "host",
    "machine": "q35",
    "bios": "seabios",
    "scsihw": "virtio-scsi-single",
    "ostype": "other",
    "keyboard": "fr-be",
    "target_disk_gb": 20,
    "uplinks": {"proximus": False, "telenet": True},
    "nics": {"net0": "vmbrAPPS", "net1": "vmbrOOB", "net2": "vmbrWAN1", "net3": "vmbrWAN2", "net4": "vmbrFAB"},
}
# NIC -> which uplink flag governs its link state (link_down when the flag is False).
UPLINK_NIC = {"net2": "proximus", "net3": "telenet"}


def load_profile(seed_path: Path) -> dict:
    """Return the merged hardware profile of a seed (seed['vm'] over DEFAULTS)."""
    seed = json.loads(Path(seed_path).read_text())
    vm = seed.get("vm")
    if not vm:
        raise SystemExit(f"{seed_path}: missing 'vm' block (hardware profile)")
    for k in ("vmid", "name", "env", "tags"):
        if k not in vm:
            raise SystemExit(f"{seed_path}: vm.{k} is required")
    prof = {**DEFAULTS, **vm}
    prof["uplinks"] = {**DEFAULTS["uplinks"], **(vm.get("uplinks") or {})}
    prof["nics"] = dict(vm.get("nics") or DEFAULTS["nics"])
    # Pinned hardware addresses (optional, per NIC). A firewall's MACs are part of its identity:
    # the OOB router's ARP/DHCP mapping and the ISP modem key on them, so a rebuild keeps them.
    prof["nic_macs"] = {k: str(m).upper() for k, m in (vm.get("nic_macs") or {}).items()}
    prof["seed_name"] = Path(seed_path).stem
    return prof


def is_prod(profile: dict) -> bool:
    return str(profile.get("env")) == "prod"


def link_suffix(profile: dict, nic: str) -> str:
    """',link_down=1' for an ISP NIC whose uplink flag is False, else ''."""
    flag = UPLINK_NIC.get(nic)
    if flag is None:
        return ""
    return "" if profile["uplinks"].get(flag) else ",link_down=1"


def desired_config(profile: dict, nano: str, seed_import: str) -> dict:
    """The `qm create` payload for this profile (2-disk virtio layout).

    vtnet0 = trunk (SDN VLANs), vtnet1 = OOB/LAN, vtnet2 = WAN1 parent (PPPoE),
    vtnet3 = WAN2 (Telenet static), vtnet4 = FAB fabric MGMT (VLAN 600). All
    NICs must exist so the seed's physical_interfaces map and the rendered
    config.xml assignments (opt12 Proximus, opt13 Telenet, opt14 FAB) match.
    firewall=0: pf rules are managed by OPNsense, not by PVE.
    """
    cfg = {
        "vmid": profile["vmid"],
        "name": profile["name"],
        "bios": profile["bios"], "machine": profile["machine"], "scsihw": profile["scsihw"],
        "tablet": 0, "onboot": int(profile["onboot"]), "ostype": profile["ostype"],
        "cpu": profile["cpu"], "cores": int(profile["cores"]), "sockets": 1, "memory": int(profile["memory"]),
        "boot": "order=virtio0",
        "tags": profile["tags"],
        # agent is switched on by the pipeline AFTER the importer run (qm guest exec
        # needs it for growfs); at create time it stays off so the first boot is quiet.
        "agent": "0",
        "keyboard": profile["keyboard"],
        "serial0": "socket", "vga": "std",
        "virtio0": f"poc-data:0,import-from={nano},iothread=1,discard=on",
        "virtio1": f"poc-data:0,import-from={seed_import},iothread=1,discard=on",
    }
    for nic, bridge in sorted(profile["nics"].items()):
        mac = profile.get("nic_macs", {}).get(nic)
        model = f"virtio={mac}" if mac else "virtio"
        cfg[nic] = f"{model},bridge={bridge},firewall=0{link_suffix(profile, nic)}"
    return cfg


# --- drift check -------------------------------------------------------------
def _kv(s: str) -> dict:
    """'virtio=MAC,bridge=X,firewall=0,link_down=1' -> {'virtio': MAC, 'bridge': X, ...}"""
    out = {}
    for part in str(s).split(","):
        k, _, v = part.partition("=")
        out[k.strip()] = v.strip()
    return out


def _agent_enabled(val) -> bool:
    if val is None:
        return False
    d = _kv(str(val))
    if "enabled" in d:
        return d["enabled"] == "1"
    return str(val).split(",")[0].strip() == "1"


def check_drift(profile: dict, live: dict) -> list[tuple[str, str, str]]:
    """Compare the live `qm config` dict with the profile. Returns [(key, want, have)]."""
    drift = []

    def cmp(key, want, have):
        if str(want) != str(have):
            drift.append((key, str(want), str(have)))

    cmp("name", profile["name"], live.get("name"))
    cmp("cores", profile["cores"], live.get("cores"))
    cmp("memory", profile["memory"], live.get("memory"))
    cmp("cpu", profile["cpu"], live.get("cpu"))
    cmp("machine", profile["machine"], live.get("machine"))
    cmp("bios", profile["bios"], live.get("bios"))
    cmp("scsihw", profile["scsihw"], live.get("scsihw"))
    cmp("ostype", profile["ostype"], live.get("ostype"))
    cmp("onboot", int(profile["onboot"]), int(live.get("onboot", 0) or 0))
    cmp("tablet", 0, int(live.get("tablet", 1) if live.get("tablet") is not None else 1))
    cmp("keyboard", profile["keyboard"], live.get("keyboard"))
    cmp("serial0", "socket", live.get("serial0"))
    cmp("vga", "std", live.get("vga"))
    cmp("boot", "order=virtio0", live.get("boot"))
    cmp("tags", ";".join(sorted(profile["tags"].split(";"))), ";".join(sorted(str(live.get("tags", "")).split(";"))))
    cmp("agent.enabled", bool(profile["agent_enabled"]), _agent_enabled(live.get("agent")))
    # NICs: bridge + link state + firewall; extra NICs on the box are drift too
    for nic, bridge in sorted(profile["nics"].items()):
        have = _kv(live.get(nic, "")) if live.get(nic) else {}
        cmp(f"{nic}.bridge", bridge, have.get("bridge", "<absent>"))
        cmp(f"{nic}.link_down", "1" if link_suffix(profile, nic) else "0", have.get("link_down", "0"))
        cmp(f"{nic}.firewall", "0", have.get("firewall", "0"))
        mac = profile.get("nic_macs", {}).get(nic)
        if mac:
            cmp(f"{nic}.macaddr", mac, str(have.get("virtio", "<absent>")).upper())
    for k in live:
        if re.fullmatch(r"net\d+", k) and k not in profile["nics"]:
            drift.append((f"{k}", "<absent>", str(live[k])))
    # disks: virtio0 root size >= target, virtio1 (seed import drive) present
    d0 = _kv(live.get("virtio0", ""))
    size = d0.get("size", "0G")
    gb = float(size[:-1]) if size.endswith("G") else 0.0
    if gb < float(profile["target_disk_gb"]):
        drift.append(("virtio0.size", f">={profile['target_disk_gb']}G", size))
    if "virtio1" not in live:
        drift.append(("virtio1", "present (seed import drive)", "<absent>"))
    return drift


def format_drift(profile: dict, drift: list[tuple[str, str, str]]) -> str:
    head = f"[check] {profile['name']} (vmid {profile['vmid']}, env {profile['env']}): "
    if not drift:
        return head + "NO DRIFT — live hardware == seed profile"
    lines = [head + f"{len(drift)} drift item(s)"]
    lines += [f"    {k:18s} want={w:<45s} have={h}" for k, w, h in drift]
    return "\n".join(lines)

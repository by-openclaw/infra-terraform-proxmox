#!/usr/bin/env python3
# Copyright (c) BY-SYSTEMS SRL
# SPDX-License-Identifier: Apache-2.0
# Source: https://github.com/by-openclaw/infra-terraform-proxmox
#
# OPNsense seed-ISO builder.
#
# Reads a per-VM JSON seed under seeds/, renders <interfaces> + <vlans> into
# templates/baseline.xml, and packs the result into a FAT/ISO9660 image with
# volume label "OPNsense" containing /conf/config.xml at the root.
#
# Mount that ISO as a secondary CD during install (or boot). OPNsense's installer
# prompts "Import existing configuration?" and picks up /conf/config.xml from
# the labeled media.
#
# Usage:
#   ./build-seed.py vm-opns-01            # builds out/vm-opns-01.iso
#   ./build-seed.py vm-opns-01 --xml-only # writes only out/vm-opns-01/conf/config.xml
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

HERE = Path(__file__).resolve().parent
SEEDS = HERE / "seeds"
TEMPLATES = HERE / "templates"
OUT = HERE / "out"

# Bootstrap creds (admin API key + password hashes) are injected at build time
# from the secret store, never committed. baseline.xml holds placeholders.
BOOTSTRAP_SECRET = Path(
    os.path.expanduser("~/.openclaw/workspace/infra/secrets/fabric/OPNsense.seed-bootstrap.json")
)
_PLACEHOLDERS = {
    "__ROOT_PASSWORD_HASH__": "root_password_hash",
    "__BYRESEARCH_PASSWORD_HASH__": "byresearch_password_hash",  # pragma: allowlist secret
    "__BYRESEARCH_AUTHORIZEDKEYS__": "byresearch_authorizedkeys",
    "__SVCANSIBLE_AUTHORIZEDKEYS__": "svcansible_authorizedkeys",
}
# Secrets that live in OTHER fabric files: placeholder -> (file, field). The LDAP
# bind password is the Authentik LDAP outpost service account (svc-ldap-prod).
_EXTRA_PLACEHOLDERS = {
    "__LDAP_BIND_PASSWORD__": ("app-ldap-bind.json", "password"),  # pragma: allowlist secret
}


def _inject_bootstrap_secrets(text: str) -> str:
    """Replace baseline.xml secret placeholders with values from the secret store.

    Fail loud if a placeholder is present but its secret is missing — never ship a
    seed with an empty admin credential.
    """
    if not any(p in text for p in list(_PLACEHOLDERS) + list(_EXTRA_PLACEHOLDERS)):
        return text
    if not BOOTSTRAP_SECRET.exists():
        raise SystemExit(f"bootstrap secret not found: {BOOTSTRAP_SECRET}")
    fields = json.loads(BOOTSTRAP_SECRET.read_text()).get("fields", {})
    for ph, key in _PLACEHOLDERS.items():
        if ph in text:
            val = fields.get(key, "").strip()
            if not val:
                raise SystemExit(f"{BOOTSTRAP_SECRET}: missing/empty field '{key}' for {ph}")
            text = text.replace(ph, val)
    for ph, (fname, key) in _EXTRA_PLACEHOLDERS.items():
        if ph in text:
            fpath = BOOTSTRAP_SECRET.parent / fname
            if not fpath.exists():
                raise SystemExit(f"secret file not found: {fpath} (for {ph})")
            val = json.loads(fpath.read_text()).get("fields", {}).get(key, "").strip()
            if not val:
                raise SystemExit(f"{fpath}: missing/empty field '{key}' for {ph}")
            text = text.replace(ph, val)
    return text


def _ip_network(prefix: int) -> int:
    # Used only for log/sanity; OPNsense doesn't need the network address.
    return prefix


def build_interfaces(seed: dict) -> ET.Element:
    """Emit <interfaces> matching OPNsense's serialization.

    Layout — matches the LIVE FW + the ansible MVC catalog (verified 2026-06-13):
      <lan>      = OOB management (vtnet1).                Always present.
      <opt1>     = SDN trunk (vtnet0) — VLAN parent.       Always present.
      <opt2..>   = VLANs hanging off the trunk (MGMT=opt2 … CCTV=opt11).
      <lo0>      = loopback.
      <opt12>    = WAN1 Proximus PPPoE (pppoe0).           Only if seed has "wan".
      <opt13>    = WAN2 Telenet static (vtnet3).           Only if seed has "wan2".
      <opt14>    = FAB fabric MGMT VLAN 600 (vtnet4).      Only if seed has "fab".

    The WANs are numbered AFTER the VLANs so the slot idents equal the running
    FW (Proximus=opt12, Telenet=opt13) and the ansible catalog — which assigns
    every rule/VLAN by these idents — applies correctly after a reseed. The old
    WAN-first numbering (Telenet=opt2, VLANs on opt3+) did NOT match live and
    would put every rule on the wrong interface on reseed.

    Track-Interface IPv6: when seed has "ipv6_pd_tracking", each internal NIC
    is configured to track WAN1's /56 PD with a unique sub-prefix ID.
    """
    pd = seed.get("ipv6_pd_tracking")
    ifs = ET.Element("interfaces")

    # lan = OOB management (with optional IPv6 tracking)
    lan = ET.SubElement(ifs, "lan")
    _lan(lan, seed["lan"], track6=_track6_for("lan", pd))

    # opt1 = LAN_TRUNK (VLAN parent, with optional IPv6 tracking)
    opt1 = ET.SubElement(ifs, "opt1")
    _trunk(opt1, seed["trunk"], track6=_track6_for("trunk", pd))

    # opt2..optN = VLANs FIRST (matches live/ansible: MGMT=opt2 … CCTV=opt11).
    # Minimal seed declares no VLANs — ansible/MVC adds them post-boot.
    opt_idx = 2
    for v in seed.get("vlans", []):
        opt = ET.SubElement(ifs, f"opt{opt_idx}")
        _opt(opt, v, ipv4_prefix=seed["ipv4_prefix"], ipv6_prefix=seed["ipv6_prefix"],
             track6=_track6_for(v["vlanif"], pd))
        opt_idx += 1

    # lo0 — loopback (live serializes it between the VLANs and the WANs)
    lo = ET.SubElement(ifs, "lo0")
    ET.SubElement(lo, "internal_dynamic").text = "1"
    ET.SubElement(lo, "descr").text = "Loopback"
    ET.SubElement(lo, "enable").text = "1"
    ET.SubElement(lo, "if").text = "lo0"
    ET.SubElement(lo, "ipaddr").text = "127.0.0.1"
    ET.SubElement(lo, "ipaddrv6").text = "::1"
    ET.SubElement(lo, "subnet").text = "8"
    ET.SubElement(lo, "subnetv6").text = "128"
    ET.SubElement(lo, "type").text = "none"
    ET.SubElement(lo, "virtual").text = "1"

    # opt12 = WAN1 Proximus PPPoE — numbered after the VLANs to match the live FW.
    if "wan" in seed:
        wan = ET.SubElement(ifs, f"opt{opt_idx}")
        _wan(wan, seed["wan"])
        opt_idx += 1

    # opt13 = WAN2 Telenet static.
    if "wan2" in seed:
        wan2_node = ET.SubElement(ifs, f"opt{opt_idx}")
        _wan2(wan2_node, seed["wan2"])
        opt_idx += 1

    # opt14 = FAB fabric MGMT (vtnet4 -> vmbrFAB). Only if seed has "fab".
    if "fab" in seed:
        fab_node = ET.SubElement(ifs, f"opt{opt_idx}")
        _fab(fab_node, seed["fab"])
        opt_idx += 1

    return ifs


def _fab(node: ET.Element, f: dict) -> None:
    """OPNsense <opt14> = FAB — fabric MGMT (VLAN 600 = 10.6.240.0/20) on a dedicated
    physical NIC (vtnet4 -> vmbrFAB; the node bridges nic4.600, so untagged here).

    Static IPv4 only: no gateway, no IPv6, no DHCP. The fabric VRF (10.6.255.254)
    is the gateway; OPNsense is a member on the segment, not its router. Mirrors
    the LIVE prod block exactly (vm-opns-01, verified 2026-09-06): if, descr,
    enable, spoofmac, ipaddr, subnet — and nothing else. Prod = .2, test = .3.
    """
    ET.SubElement(node, "if").text = f["if"]
    ET.SubElement(node, "descr").text = f.get("descr", "FAB")
    ET.SubElement(node, "enable").text = "1"
    ET.SubElement(node, "spoofmac")
    ET.SubElement(node, "ipaddr").text = f["ipaddr"]
    ET.SubElement(node, "subnet").text = str(f.get("subnet", 20))


def _wan(node: ET.Element, w: dict) -> None:
    """OPNsense <wan> = ISP PPPoE interface. Proximus quirks baked in.

    Key Proximus-specific settings:
    - dhcp6-ia-pd-only = Proximus DHCPv6 only hands out PD, not IA_NA. Without
      this, dhcp6c logs 'advertise contains no address/prefix' and IPv6 fails.
    - dhcp6-prefix-id-statement matches Proximus's standard /56 delegation.
    - block_private/block_bogons MUST be ON: real internet exposure.
    """
    ET.SubElement(node, "if").text = w["if"]
    ET.SubElement(node, "descr").text = w.get("descr", "WAN")
    ET.SubElement(node, "enable").text = "1"
    ET.SubElement(node, "lock").text = "1"
    ET.SubElement(node, "ipaddr").text = w["ipv4"]
    ET.SubElement(node, "ipaddrv6").text = w["ipv6"]
    if w.get("block_private"):
        ET.SubElement(node, "blockpriv").text = "1"
    if w.get("block_bogons"):
        ET.SubElement(node, "blockbogons").text = "1"
    if w.get("mtu"):
        ET.SubElement(node, "mtu").text = str(w["mtu"])
    if w.get("mss"):
        ET.SubElement(node, "mss").text = str(w["mss"])
    if w["ipv6"] == "dhcp6":
        # Proximus DHCPv6 quirk: only IA_PD, no IA_NA
        if w.get("ipv6_dhcp6_ia_pd_only"):
            ET.SubElement(node, "dhcp6prefixonly").text = "1"
        prefix_hint = w.get("ipv6_prefix_hint", 56)
        ET.SubElement(node, "dhcp6-ia-pd-len").text = str(_pd_hint_to_len(prefix_hint))
        ET.SubElement(node, "dhcp6-ia-pd-send-hint").text = "1"
        if w.get("ipv6_send_rapid_commit"):
            ET.SubElement(node, "dhcp6-rapid-commit").text = "1"


def _wan_parent(node: ET.Element, p: dict) -> None:
    """OPNsense <opt> for the raw NIC under pppoe0.

    Assigned with no IP. block_private/block_bogons recommended so the raw
    layer also drops RFC1918/bogon traffic at the parent (defense in depth).
    """
    ET.SubElement(node, "if").text = p["if"]
    ET.SubElement(node, "descr").text = p.get("descr", "WAN1_Parent")
    ET.SubElement(node, "enable").text = "1"
    ET.SubElement(node, "lock").text = "1"
    if p.get("block_private"):
        ET.SubElement(node, "blockpriv").text = "1"
    if p.get("block_bogons"):
        ET.SubElement(node, "blockbogons").text = "1"


def _pd_hint_to_len(hint: int) -> int:
    """OPNsense expects the PD length in a 0-based scale (0 = /64, 8 = /56, ...).

    Empirically: dhcp6-ia-pd-len = 64 - hint. Most ISPs use /56 → len 8.
    """
    return max(0, 64 - int(hint))


def _lan(node: ET.Element, l: dict, *, track6: dict | None = None) -> None:
    """OPNsense <lan> = OOB admin network. DHCP from upstream, no block_private.

    If track6 is provided, IPv6 is set to "track6" mode and gets a /64 carved
    from the WAN1 /56 PD using the supplied prefix_id.
    """
    ET.SubElement(node, "if").text = l["if"]
    ET.SubElement(node, "descr").text = l.get("descr", "OOB_MGMT")
    ET.SubElement(node, "enable").text = "1"
    ET.SubElement(node, "ipaddr").text = l["ipv4"]
    if l.get("ipv4") not in ("dhcp", "none", ""):
        ET.SubElement(node, "subnet").text = str(l["ipv4_prefix"])
    _emit_ipv6(node, l, track6=track6)


def _trunk(node: ET.Element, t: dict, *, track6: dict | None = None) -> None:
    """OPNsense <opt1> = LAN_TRUNK (vlan parent).

    A bare VLAN parent carries no IP — the VLAN interfaces hung off it (added by
    ansible) hold the addressing. When "ipv4" is omitted the trunk is emitted
    enabled with no address; ansible/MVC configures VLANs on top.
    """
    ET.SubElement(node, "if").text = t["if"]
    ET.SubElement(node, "descr").text = t.get("descr", "LAN_TRUNK")
    ET.SubElement(node, "enable").text = "1"
    if "ipv4" in t:
        ET.SubElement(node, "ipaddr").text = t["ipv4"]
        ET.SubElement(node, "subnet").text = str(t["ipv4_prefix"])
    if "ipv4" in t or "ipv6" in t or track6 is not None:
        _emit_ipv6(node, t, track6=track6)


def _opt(node: ET.Element, v: dict, *, ipv4_prefix: int, ipv6_prefix: int, track6: dict | None = None) -> None:
    ET.SubElement(node, "if").text = v["vlanif"]
    ET.SubElement(node, "descr").text = v["descr"]
    ET.SubElement(node, "enable").text = "1"
    ET.SubElement(node, "ipaddr").text = v["ipv4"]
    ET.SubElement(node, "subnet").text = str(v.get("ipv4_prefix", ipv4_prefix))
    _emit_ipv6(node, v, track6=track6, default_prefix=ipv6_prefix)


def _emit_ipv6(node: ET.Element, cfg: dict, *, track6: dict | None = None, default_prefix: int | None = None) -> None:
    """Emit IPv6 config — either static ULA, dhcp6, or track6 (PD sub-prefix).

    Precedence: track6 wins over the static ipv6 declared in the seed. This lets
    an internal NIC use both ULA-in-seed (for documentation) and Track-Interface-
    at-runtime (actual config), without duplicating the seed entry.
    """
    if track6 is not None:
        ET.SubElement(node, "ipaddrv6").text = "track6"
        ET.SubElement(node, "track6-interface").text = track6["track_source_slot"]
        ET.SubElement(node, "track6-prefix-id").text = track6["prefix_id"]
        return
    v6 = cfg.get("ipv6")
    if not v6:
        return
    ET.SubElement(node, "ipaddrv6").text = v6
    if v6 not in ("dhcp6", "none", "", "track6"):
        ET.SubElement(node, "subnetv6").text = str(cfg.get("ipv6_prefix", default_prefix or 64))
    if v6 == "dhcp6":
        ET.SubElement(node, "dhcp6-ia-pd-len").text = "0"


def _track6_for(if_name: str, pd: dict | None) -> dict | None:
    """Look up Track-Interface config for an interface name in the seed's ipv6_pd_tracking."""
    if not pd:
        return None
    entry = pd.get("interfaces", {}).get(if_name)
    if entry is None:
        return None
    # Map track_source seed key ("wan") to OPNsense interface slot identifier
    return {
        "track_source_slot": pd.get("track_source", "wan"),
        "prefix_id": entry.get("prefix_id", "0x0"),
    }


def _wan2(node: ET.Element, w2: dict) -> None:
    """OPNsense static WAN2 (e.g. Telenet). Reads IPs from secret file at build time.

    No PPPoE — IPv4 and IPv6 are both static. Gateway is referenced by name
    (WAN2GW for IPv4, WAN2GWv6 for IPv6) — those gateway entries are emitted
    by build_gateways().
    """
    creds_path = w2.get("creds_secret")
    if not creds_path:
        raise SystemExit("wan2.creds_secret is required for static WAN2")
    creds = _read_wan_creds(creds_path)

    ET.SubElement(node, "if").text = w2["if"]
    ET.SubElement(node, "descr").text = w2.get("descr", "WAN2")
    ET.SubElement(node, "enable").text = "1"
    ET.SubElement(node, "lock").text = "1"
    if w2.get("block_private"):
        ET.SubElement(node, "blockpriv").text = "1"
    if w2.get("block_bogons"):
        ET.SubElement(node, "blockbogons").text = "1"
    # IPv4 static
    ET.SubElement(node, "ipaddr").text = creds["ipv4_address"]
    ET.SubElement(node, "subnet").text = str(creds["ipv4_prefix"])
    ET.SubElement(node, "gateway").text = "WAN2GW"
    # IPv6 static (independent — not PPPoE-tracked)
    ET.SubElement(node, "ipaddrv6").text = creds["ipv6_address"]
    ET.SubElement(node, "subnetv6").text = str(creds["ipv6_prefix"])
    ET.SubElement(node, "gatewayv6").text = "WAN2GWv6"


def compute_slot_map(seed: dict) -> dict:
    """Return a mapping from logical role → OPNsense slot identifier (lan|optN).

    Mirrors build_interfaces() so other generators (gateways, NAT, NetFlow) can
    reference the correct slot. Layout matches the LIVE FW + ansible catalog
    (verified 2026-06-13): trunk=opt1, VLANs=opt2..optN, then the WANs last —
    Proximus=opt12, Telenet=opt13. The ansible MVC catalog assigns rules/VLANs by
    these idents, so a reseed MUST reproduce them or every rule lands wrong.
    """
    slots = {}
    slots["lan"] = "lan"
    slots["trunk"] = "opt1"
    idx = 2
    # VLANs first → opt2..optN (MGMT=opt2 … CCTV=opt11).
    for v in seed.get("vlans", []):
        slots[v["vlanif"]] = f"opt{idx}"
        idx += 1
    # WANs last → Proximus=opt12, Telenet=opt13 (the live/ansible idents).
    if "wan" in seed:
        slots["wan"] = f"opt{idx}"
        idx += 1
    if "wan2" in seed:
        slots["wan2"] = f"opt{idx}"
        idx += 1
    # FAB last -> opt14 (fabric MGMT NIC; matches the live prod ident).
    if "fab" in seed:
        slots["fab"] = f"opt{idx}"
        idx += 1
    return slots


def build_gateways(seed: dict, slot_map: dict) -> ET.Element | None:
    """Emit <gateways> block — primarily for static WAN2 (Telenet).

    WAN1 PPPoE auto-generates dynamic gateways (WAN1_PPPOE + WAN_DHCP6) on first
    boot when OPNsense processes the <wan> with ipaddr=pppoe — we don't need to
    declare them here. Only static gateways need explicit <gateway_item> entries.
    """
    w2 = seed.get("wan2")
    if not w2:
        return None
    creds = _read_wan_creds(w2["creds_secret"])
    wan2_slot = slot_map.get("wan2")
    if not wan2_slot:
        raise SystemExit("wan2 has no slot in compute_slot_map — should not happen")

    gws = ET.Element("gateways")

    # IPv4 gateway
    g4 = ET.SubElement(gws, "gateway_item")
    ET.SubElement(g4, "interface").text = wan2_slot
    ET.SubElement(g4, "gateway").text = creds["ipv4_gateway"]
    ET.SubElement(g4, "name").text = "WAN2GW"
    ET.SubElement(g4, "weight").text = "1"
    ET.SubElement(g4, "ipprotocol").text = "inet"
    ET.SubElement(g4, "descr").text = w2.get("gateway_descr", "WAN2 gateway")
    ET.SubElement(g4, "monitor").text = creds["ipv4_gateway"]
    if w2.get("monitor_disable"):
        ET.SubElement(g4, "monitor_disable").text = "1"
    if w2.get("default_gateway_v4"):
        ET.SubElement(g4, "defaultgw").text = "1"

    # IPv6 gateway
    g6 = ET.SubElement(gws, "gateway_item")
    ET.SubElement(g6, "interface").text = wan2_slot
    ET.SubElement(g6, "gateway").text = creds["ipv6_gateway"]
    ET.SubElement(g6, "name").text = "WAN2GWv6"
    ET.SubElement(g6, "weight").text = "1"
    ET.SubElement(g6, "ipprotocol").text = "inet6"
    ET.SubElement(g6, "descr").text = w2.get("gateway_descr", "WAN2 gateway")
    ET.SubElement(g6, "monitor").text = creds["ipv6_gateway"]
    if w2.get("monitor_disable"):
        ET.SubElement(g6, "monitor_disable").text = "1"
    if w2.get("default_gateway_v6"):
        ET.SubElement(g6, "defaultgw").text = "1"

    return gws


def build_netflow(slot_map: dict) -> ET.Element:
    """Emit <OPNsense><Netflow> so a fresh seed boots with NetFlow/Insight active.

    The capture interface list is rendered from compute_slot_map (which now
    matches the live FW + ansible layout: VLANs opt2..opt11, Proximus opt12,
    Telenet opt13). Rendering from slot_map keeps capture = every internal + WAN
    ident and egress_only = the WAN idents correct no matter how many VLANs the
    seed defines, and guarantees the idents equal the running FW after a reseed.

    Why the seed and not Ansible MVC: the OPNsense diagnostics/netflow/setconfig
    endpoint is broken (returns {"result":"failed"} for every body shape) and root
    SSH is blocked, so the capture config cannot be asserted over the API. The seed
    writes config.xml directly, so it is the only reproducible home for it. On a
    fresh boot OPNsense reads this block; collect.enable=1 starts the local Insight
    aggregator (flowd_aggregate). Fields mirror the live getconfig model on
    vm-opns-01: NetFlow v9 -> 127.0.0.1:2056. Tracks ansible-platform #31.
    """
    def _order(ident: str) -> tuple:
        # Deterministic: OOB first, then optN by number, WAN/pppoe last.
        if ident == "lan":
            return (0, 0)
        if ident.startswith("opt"):
            return (1, int(ident[3:]))
        return (2, 0)

    wan_idents = [v for k, v in slot_map.items() if k in ("wan", "wan2", "wan_parent")]
    # FAB (fabric MGMT, opt14) is NOT captured — mirrors the live prod capture list
    # (lan,opt1..opt13); a management segment needs no flow accounting.
    capture = sorted([v for k, v in slot_map.items() if k != "fab"], key=_order)
    egress = sorted(wan_idents, key=_order)

    opnsense = ET.Element("OPNsense")
    nf = ET.SubElement(opnsense, "Netflow")
    cap = ET.SubElement(nf, "capture")
    ET.SubElement(cap, "interfaces").text = ",".join(capture)
    ET.SubElement(cap, "egress_only").text = ",".join(egress)
    ET.SubElement(cap, "version").text = "v9"
    ET.SubElement(cap, "targets").text = "127.0.0.1:2056"
    collect = ET.SubElement(nf, "collect")
    ET.SubElement(collect, "enable").text = "1"
    # OPNsense Netflow model defaults (live leaves them unset → these apply).
    ET.SubElement(nf, "activeTimeout").text = "1800"
    ET.SubElement(nf, "inactiveTimeout").text = "15"
    return opnsense


def _read_wan_creds(secret_path: str) -> dict:
    """Read static WAN credentials from a JSON secret file.

    Expected fields: ipv4_address, ipv4_prefix, ipv4_gateway, ipv6_address, ipv6_prefix, ipv6_gateway.
    Fails loudly if any required field is missing or empty.
    """
    p = Path(secret_path)
    if not p.exists():
        raise SystemExit(f"WAN secret file not found: {secret_path}")
    d = json.loads(p.read_text())
    f = d.get("fields", d)
    required = ("ipv4_address", "ipv4_prefix", "ipv4_gateway",
                "ipv6_address", "ipv6_prefix", "ipv6_gateway")
    missing = [k for k in required if not f.get(k)]
    if missing:
        raise SystemExit(f"{secret_path}: missing/empty fields: {missing}")
    return f


def _resolve_domain(seed: dict) -> str:
    """Resolve the DNS search domain at build time.

    Prefer `domain_secret` (path to a JSON secret with fields.domain) so the real
    internal domain never lands in the committed seed (no-real-domains rule). Fall
    back to the literal `domain` (placeholder) if no secret is configured.
    """
    secret_path = seed.get("domain_secret")
    if secret_path:
        p = Path(secret_path)
        if not p.exists():
            raise SystemExit(f"domain secret file not found: {secret_path}")
        f = json.loads(p.read_text()).get("fields", {})
        domain = f.get("domain")
        if not domain:
            raise SystemExit(f"{secret_path}: missing/empty fields.domain")
        return domain
    return seed["domain"]


def build_vlans(seed: dict) -> ET.Element:
    """Emit <vlans> with one <vlan> child per seed entry. PCP per IEEE 802.1p."""
    parent_if = seed["physical_interfaces"]["trunk"]
    vlans = ET.Element("vlans")
    for v in seed.get("vlans", []):
        node = ET.SubElement(vlans, "vlan")
        ET.SubElement(node, "if").text = parent_if
        ET.SubElement(node, "tag").text = str(v["tag"])
        ET.SubElement(node, "pcp").text = str(v.get("pcp", 0))
        ET.SubElement(node, "proto").text = ""
        ET.SubElement(node, "descr").text = v["descr"]
        ET.SubElement(node, "vlanif").text = v["vlanif"]
    return vlans


def _read_pppoe_creds(secret_path: str) -> tuple[str, str]:
    """Read PPPoE username/password from a JSON secret file.

    Expected structure: {"fields": {"pppoe_username": "...", "pppoe_password": "..."}}.
    Raises with a clear message if the secret file or fields are missing — fail loud
    rather than ship a seed with empty credentials.
    """
    p = Path(secret_path)
    if not p.exists():
        raise SystemExit(f"PPPoE secret file not found: {secret_path}")
    d = json.loads(p.read_text())
    fields = d.get("fields", d)
    user = fields.get("pppoe_username", "").strip()
    pw = fields.get("pppoe_password", "").strip()
    if not user or not pw:
        raise SystemExit(
            f"pppoe_username or pppoe_password missing/empty in {secret_path}. "
            f"Fill them in (no label prefix, just the raw value)."
        )
    return user, pw


def build_ppps(seed: dict) -> ET.Element | None:
    """Emit <ppps> block with one <ppp> per PPPoE link.

    Returns None if seed has no "wan" with a pppoe_link_interface — i.e. we don't
    emit an empty <ppps> block on non-PPPoE seeds.
    """
    wan = seed.get("wan")
    if not wan or wan.get("ipv4") != "pppoe":
        return None

    link_if = wan.get("pppoe_link_interface")
    if not link_if:
        raise SystemExit("wan.pppoe_link_interface is required for PPPoE setup")

    secret_path = wan.get("pppoe_creds_secret")
    if not secret_path:
        raise SystemExit("wan.pppoe_creds_secret is required for PPPoE setup")
    user, pw = _read_pppoe_creds(secret_path)

    ppps = ET.Element("ppps")
    ppp = ET.SubElement(ppps, "ppp")
    ET.SubElement(ppp, "ptpid").text = "0"
    ET.SubElement(ppp, "type").text = "pppoe"
    ET.SubElement(ppp, "if").text = wan.get("if", "pppoe0")
    ET.SubElement(ppp, "ports").text = link_if
    ET.SubElement(ppp, "username").text = user
    ET.SubElement(ppp, "password").text = pw
    ET.SubElement(ppp, "provider").text = wan.get("pppoe_service_name", "")
    ET.SubElement(ppp, "mtu").text = str(wan.get("mtu", 1492))
    ET.SubElement(ppp, "mru").text = str(wan.get("mtu", 1492))
    return ppps


def render(seed_name: str) -> Path:
    seed = json.loads((SEEDS / f"{seed_name}.json").read_text())
    tree = ET.parse(TEMPLATES / "baseline.xml")
    root = tree.getroot()

    # Hostname / domain
    sys_node = root.find("system")
    if sys_node is not None:
        for tag, val in (("hostname", seed["hostname"]), ("domain", _resolve_domain(seed)), ("timezone", seed["timezone"])):
            el = sys_node.find(tag)
            if el is None:
                el = ET.SubElement(sys_node, tag)
            el.text = val

    # Replace interfaces + vlans + ppps + gateways (insert after <system>)
    for tag in ("interfaces", "vlans", "ppps", "gateways"):
        old = root.find(tag)
        if old is not None:
            root.remove(old)
    root.append(build_interfaces(seed))
    root.append(build_vlans(seed))
    ppps = build_ppps(seed)
    if ppps is not None:
        root.append(ppps)
    slot_map = compute_slot_map(seed)
    gws = build_gateways(seed, slot_map)
    if gws is not None:
        root.append(gws)

    # NetFlow/Insight capture block (plugin config lives under <OPNsense>).
    # Idempotent: drop any prior <Netflow>, (re)attach the slot-map-rendered one,
    # reusing an existing <OPNsense> parent if the baseline ever grows one.
    netflow_parent = build_netflow(slot_map)
    opnsense_node = root.find("OPNsense")
    if opnsense_node is None:
        root.append(netflow_parent)
    else:
        old_nf = opnsense_node.find("Netflow")
        if old_nf is not None:
            opnsense_node.remove(old_nf)
        opnsense_node.append(netflow_parent.find("Netflow"))

    ET.indent(tree, space="  ")
    out_dir = OUT / seed_name / "conf"
    out_dir.mkdir(parents=True, exist_ok=True)
    target = out_dir / "config.xml"
    tree.write(target, encoding="UTF-8", xml_declaration=True)
    # Inject bootstrap creds from the secret store (placeholders -> real values).
    target.write_text(_inject_bootstrap_secrets(target.read_text()))
    return target


def build_iso(seed_name: str) -> Path:
    src = OUT / seed_name
    iso = OUT / f"{seed_name}-seed.iso"
    if not (src / "conf" / "config.xml").exists():
        raise SystemExit(f"render first; missing {src / 'conf' / 'config.xml'}")
    cmd = [
        "genisoimage",
        "-V", "OPNsense",      # volume label OPNsense installer searches for
        "-J", "-r",            # Joliet + Rock Ridge
        "-quiet",
        "-o", str(iso),
        str(src),
    ]
    subprocess.run(cmd, check=True)
    return iso


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("seed", help="seed name under seeds/ (without .json)")
    ap.add_argument("--xml-only", action="store_true", help="render config.xml only; skip ISO build")
    args = ap.parse_args()

    if not (SEEDS / f"{args.seed}.json").exists():
        print(f"seed not found: {SEEDS / (args.seed + '.json')}", file=sys.stderr)
        return 2

    xml = render(args.seed)
    print(f"[ok] rendered {xml}")
    if args.xml_only:
        return 0
    if not shutil.which("genisoimage"):
        print("genisoimage not found in PATH; install it or rerun with --xml-only", file=sys.stderr)
        return 3
    iso = build_iso(args.seed)
    size = iso.stat().st_size
    print(f"[ok] built {iso} ({size:,} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

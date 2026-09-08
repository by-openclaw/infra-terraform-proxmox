#!/usr/bin/env python3
# Copyright (c) BY-SYSTEMS SRL
# SPDX-License-Identifier: Apache-2.0
#
# Destroy + recreate an OPNsense FW VM from the verified nano image and drive the
# importer over Proxmox termproxy (seed-driven: seeds/<name>.json "vm"), with
# --check just diff the live hardware against that profile, or with --apply-hw
# push the in-place hardware keys (memory/cores/onboot/tags) to the live VM and
# cold-restart it when memory/cores changed — no recreate, no disk/NIC change.
# Idempotent. Prod: --check always; --apply-hw needs --confirm-prod-restart.
from __future__ import annotations

import json
import ssl
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

import websocket


def load():
    p = Path("/home/by-systems/.openclaw/workspace/infra/secrets/fabric/infra-proxmox-poc.json")
    f = json.loads(p.read_text())["fields"]
    return f["host"], f["admin_token_id"], f["admin_token_secret"]


HOST, TID, TSEC = load()
AUTH = f"PVEAPIToken={TID}={TSEC}"
# NODE / VMID / SEED_IMPORT / uplinks come from the seed profile block below.
# ISP uplinks of the TEST FW (see the NIC block below and seed/ISP-ALLOCATION.md):
#  - net3 / Telenet (vmbrWAN2): UP by default (full config, live Internet). The test
#    FW carries its OWN address (fabric/net-isp-telenet-test.json = 213.214.47.220/29
#    + 2a02:1802:21::6/64, borrowed from the HA-Phase2 pool) — never prod's .222/::5
#    (enforced by _assert_no_prod_isp_identity). The 2026-08-30 incident (prod Telenet
#    v4 flapping, v6 92 % loss) was a DUPLICATE identity: the test seed then leaked
#    prod's .222/::5 onto the shared segment. With a distinct address it is safe —
#    proven 2026-09-06 on the live segment (hot link-up + full boot, prod's .222 ARP
#    entry and both prod Telenet gateways untouched, 0 % loss). If prod's .222 were
#    ever poisoned again: prod API `interfaces/overview/reloadInterface/opt13`.
#  - net2 / Proximus (vmbrWAN1): link_down=1 ALWAYS — one PPPoE account = one
#    session, a second session would fight prod. opt12 still exists in the seed so
#    catalog rules bound to it can be tested.
SECRETS_DIR = Path.home() / ".openclaw/workspace/infra/secrets/fabric"
PROD_TELENET_FILE = "net-isp-telenet.json"          # pragma: allowlist secret (file NAME)
PROD_PPPOE_FILE = "net-isp-proximus-pppoe.json"     # pragma: allowlist secret (file NAME)
NANO = "poc-iso:import/OPNsense-26.7-nano-amd64.raw"  # test FW tracks latest CE for lib/MVC work
DEVICE = "vtbd1"  # virtio-block disk #1 (seed-ISO attached as block, not CDROM)

# Target disk size for the FW root. The OPNsense Nano image is 3G — too small
# for plugin install (acme/chrony/crowdsec/dnscrypt/lldpd/qemu-ga), pkg cache,
# /var/unbound trust anchors, and runtime logs. Without this, every reseed
# leaves the disk at ~109% utilisation, Unbound fails its trust-anchor fsync
# ("No space left on device"), and the DNS chain never comes up. The script
# resizes the PVE disk after import and runs growfs(8) via qemu-agent before
# the importer finishes — so a single `recreate-and-seed.py` run produces a
# fully-sized FW with no manual follow-up. Tracked in CLAUDE.md known blockers.
TARGET_DISK_GB = 20

# ---- seed-driven VM hardware profile (vmprofile.py) -------------------------
# Usage: recreate-and-seed.py [<seed-name>] [--check] [--no-recreate] [--no-growfs]
#        [--no-baseline] [--confirm-prod-recreate]
#   <seed-name> defaults to vm-opns-test-01 (backward compatible).
#   --check     NON-DESTRUCTIVE drift gate: live `qm config` vs seeds/<name>.json "vm".
#   prod seeds (vm.env == "prod") only accept --check unless --confirm-prod-recreate.
from vmprofile import load_profile, desired_config, check_drift, format_drift, is_prod, link_suffix  # noqa: E402

SEED_NAME = next((a for a in sys.argv[1:] if not a.startswith("--")), "vm-opns-test-01")
SEED_PATH = Path(__file__).parent / "seeds" / f"{SEED_NAME}.json"
PROFILE = load_profile(SEED_PATH)
VMID, NODE = int(PROFILE["vmid"]), PROFILE["node"]
SEED_IMPORT = f"poc-iso:import/{SEED_NAME}-seed.raw"
TARGET_DISK_GB = int(PROFILE["target_disk_gb"])
TELENET_UPLINK = bool(PROFILE["uplinks"].get("telenet"))
PROXIMUS_UPLINK = bool(PROFILE["uplinks"].get("proximus"))
TELENET_LINK = link_suffix(PROFILE, "net3")
PROXIMUS_LINK = link_suffix(PROFILE, "net2")


def api(method, path, body=None):
    url = f"https://{HOST}:8006/api2/json{path}"
    headers = {"Authorization": AUTH}
    data = None
    if body is not None:
        data = urllib.parse.urlencode(body).encode()
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        return json.loads(urllib.request.urlopen(req, context=ctx).read())
    except urllib.error.HTTPError as e:
        msg = e.read().decode()
        if e.code == 500 and "does not exist" in msg:
            return {"data": None, "_missing": True}
        raise


def wait_task(upid, timeout=120):
    for _ in range(timeout // 2):
        time.sleep(2)
        s = api("GET", f"/nodes/{NODE}/tasks/{upid}/status")["data"]
        if s.get("status") == "stopped":
            return s.get("exitstatus")
    return "TIMEOUT"


def _assert_no_prod_isp_identity(seed_path: Path) -> None:
    """Refuse to put the test FW on an ISP segment with PROD's identity.

    Telenet: the seed's wan2.creds_secret must be a different file than prod's AND
    carry different IPv4/IPv6 addresses. Proximus: the single PPPoE account must
    never be dialled from the test FW (net2 stays link_down).
    """
    seed = json.loads(Path(seed_path).read_text())
    if TELENET_UPLINK:
        creds = (seed.get("wan2") or {}).get("creds_secret", "")
        if not creds or Path(creds).name == PROD_TELENET_FILE:
            raise SystemExit(
                "TELENET_UPLINK=True but wan2.creds_secret is missing or is PROD's "
                f"{PROD_TELENET_FILE} -> duplicate public IP on vmbrWAN2 (2026-09 incident)."
            )
        test_f = json.loads(Path(creds).read_text()).get("fields", {})
        prod_f = json.loads((SECRETS_DIR / PROD_TELENET_FILE).read_text()).get("fields", {})
        for k in ("ipv4_address", "ipv6_address"):
            if not test_f.get(k) or test_f.get(k) == prod_f.get(k):
                raise SystemExit(f"test Telenet file {k}={test_f.get(k)!r} equals prod's -> refuse.")
    if PROXIMUS_UPLINK:
        pppoe = (seed.get("wan") or {}).get("pppoe_creds_secret", "")
        if Path(pppoe).name == PROD_PPPOE_FILE:
            raise SystemExit("PROXIMUS_UPLINK=True with PROD's PPPoE account: single session, refuse.")


def recreate_vm():
    """Destroy the profile's VM (if it exists) and recreate it from the nano image."""
    # destroy
    cur = api("GET", f"/nodes/{NODE}/qemu/{VMID}/status/current")
    if not cur.get("_missing"):
        if cur["data"].get("status") == "running":
            print("[a] stopping VM...")
            api("POST", f"/nodes/{NODE}/qemu/{VMID}/status/stop")
            for _ in range(15):
                time.sleep(1)
                s = api("GET", f"/nodes/{NODE}/qemu/{VMID}/status/current")
                if s.get("_missing") or s["data"].get("status") == "stopped":
                    break
        print("[b] destroying VM...")
        url = f"/nodes/{NODE}/qemu/{VMID}?destroy-unreferenced-disks=1&purge=1"
        r = api("DELETE", url)
        if r.get("data"):
            ex = wait_task(r["data"])
            print(f"    destroy: {ex}")
        time.sleep(3)

    # create
    print("[c] creating VM...")
    config = desired_config(PROFILE, NANO, SEED_IMPORT)  # seed-driven (vmprofile.py)
    r = api("POST", f"/nodes/{NODE}/qemu", config)
    ex = wait_task(r["data"])
    print(f"    create: {ex}")

    # Resize the imported Nano root disk to TARGET_DISK_GB. PVE's resize is
    # additive (`+NG` adds, bare `NG` sets); we set absolute. The growfs
    # inside the guest is deferred until after the importer reboots — see
    # grow_root_filesystem() called from start_vm_and_drive().
    print(f"[c+] resize virtio0 -> {TARGET_DISK_GB}G")
    rs = api("PUT", f"/nodes/{NODE}/qemu/{VMID}/resize",
             {"disk": "virtio0", "size": f"{TARGET_DISK_GB}G"})
    print(f"    resize: ok")

    # Enable qemu-guest-agent in the VM hardware so growfs + later
    # post-reseed ops (DNS-chain config, plugin install) can be driven via
    # `qm guest exec`. The os-qemu-guest-agent plugin is in the seed's
    # <plugins> list and will install on first boot once internet is up.
    api("PUT", f"/nodes/{NODE}/qemu/{VMID}/config",
        {"agent": "enabled=1,type=virtio"})


def grow_root_filesystem():
    """Run growfs(8) inside the FW via qemu-agent so the UFS root spans the
    full TARGET_DISK_GB. Idempotent — safe to re-run; growfs is a no-op when
    already grown. Requires qemu-agent to be responsive; if it isn't yet, we
    retry a few times because the agent comes up only after the importer's
    second reboot brings the seeded OPNsense fully online."""
    import urllib.parse as _up
    deadline = time.time() + 180
    while time.time() < deadline:
        try:
            api("POST", f"/nodes/{NODE}/qemu/{VMID}/agent/ping")
            break
        except Exception:
            time.sleep(5)
    else:
        print("[g] qemu-agent not responsive after 180s — growfs deferred")
        return False

    def qexec(args):
        body = "&".join(f"command={_up.quote(a)}" for a in args).encode()
        from urllib.request import Request, urlopen
        req = Request(f"https://{HOST}:8006/api2/json/nodes/{NODE}/qemu/{VMID}/agent/exec",
                      data=body, headers={"Authorization": AUTH,
                                          "Content-Type": "application/x-www-form-urlencoded"},
                      method="POST")
        ctx = ssl.create_default_context(); ctx.check_hostname=False; ctx.verify_mode=ssl.CERT_NONE
        pid = json.loads(urlopen(req, context=ctx).read())["data"]["pid"]
        for _ in range(60):
            time.sleep(1)
            s = api("GET", f"/nodes/{NODE}/qemu/{VMID}/agent/exec-status?pid={pid}")["data"]
            if s.get("exited"):
                return s.get("exitcode"), (s.get("out-data","") or "") + (s.get("err-data","") or "")
        return None, "timeout"

    print("[g] growing root UFS to TARGET_DISK_GB...")
    # gpart recover/resize is unreliable on Nano (no GPT, BSD-slice layout —
    # see infra-terraform-proxmox/reference_opnsense_nano_growfs_recipe). growfs
    # operates on the mounted root device directly and succeeds.
    ex, out = qexec(["/sbin/growfs", "-y", "/"])
    print(f"    growfs exit={ex}")
    ex2, out2 = qexec(["df", "-h", "/"])
    print(out2.strip())
    return ex == 0


# OPNsense API credentials are baked into the seed via templates/baseline.xml.
# After reseed, the same key/secret authenticate to https://<FW-OOB>/api.
# We read them from the same secret store the seed builder uses.
_FW_API_SECRET_PATH = Path.home() / ".openclaw/workspace/infra/secrets/OPNsense.prod_root_password.json"


def apply_security_baseline(fw_oob_ip: str = "10.6.239.195") -> bool:
    """Post-reseed hardening: enable the monitoring/reporting features that make
    the FW immediately usable for incident response and traffic visibility.

    Idempotent — re-running re-asserts the same settings. Run order matters:
    Unbound stats first (it's the heaviest reconfigure), then NetFlow + Insight.

    What this turns on (and why each matters for "ready to secure the network"):

      1) Unbound DNS reporting (general.stats=1) — Reporting > Unbound DNS
         shows per-client query volume, top blocked domains, cache hit rate.
         Without it, the DNS chain is a black box and DNSBL bypass attempts
         are invisible.

      2) NetFlow v9 capture on every internal VLAN + LAN_TRUNK + WAN egress
         — populates the kernel flow exporter. Required for Insight.

      3) Insight local aggregator (collect.enable=1) — Reporting > Insight
         shows per-host bandwidth, top talkers, top destinations, geo. This
         is the OPNsense equivalent of nProbe; pfSense has nothing native.

    Not yet baked in (follow-ups in this same function): WireGuard reporting,
    Suricata IDS event log, AdGuard log forwarding, CrowdSec LAPI registration.
    """
    try:
        import requests, urllib3
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    except ImportError:
        print("[h] requests not available — skipping security baseline")
        return False
    if not _FW_API_SECRET_PATH.exists():
        print(f"[h] {_FW_API_SECRET_PATH.name} not found — skipping security baseline")
        return False
    d = json.loads(_FW_API_SECRET_PATH.read_text())["fields"]
    auth = (d["key"], d["secret"])
    B = f"https://{fw_oob_ip}/api"

    def post(path, body=None, t=30):
        r = requests.post(f"{B}{path}", auth=auth, verify=False, timeout=t,
                          json=body) if body else \
            requests.post(f"{B}{path}", auth=auth, verify=False, timeout=t)
        return r.status_code, r.text[:160]

    # Wait for the WebUI/API to come up — Unbound restart is the slowest leg
    print("[h] applying security/reporting baseline...")
    deadline = time.time() + 120
    while time.time() < deadline:
        try:
            r = requests.get(f"{B}/diagnostics/system/systemTime",
                             auth=auth, verify=False, timeout=8)
            if r.status_code == 200:
                break
        except Exception:
            pass
        time.sleep(5)
    else:
        print("    API never became reachable")
        return False

    # 1) Unbound DNS stats — Reporting > Unbound DNS
    sc, txt = post("/unbound/settings/set", {"unbound": {"general": {"stats": "1"}}})
    print(f"    unbound stats=1: {sc}")
    sc, txt = post("/unbound/service/reconfigure", t=90)
    print(f"    unbound reconfigure: {sc}")

    # 2) DHCP server: Kea on, dnsmasq off. The complete-config seed has
    #    historically left both enabled — they collide on UDP/67 (dnsmasq
    #    grabs it because it starts first) and Kea ends up running idle.
    #    NetBox integrates natively with Kea (Kea Source plugin / netbox-
    #    kea-dhcp) and not with dnsmasq, so Kea is the future SOT. Unbound
    #    is the DNS resolver; dnsmasq's DNS role is also redundant here.
    #
    #    We turn dnsmasq off and (re)start Kea so it can bind UDP/67. Per-
    #    subnet DHCP option 6 (DNS) is set elsewhere — currently to AdGuard
    #    so clients learn the filtering frontend at lease time; eventually
    #    NetBox owns this via a VLAN-role config-context.
    sc, _ = post("/dnsmasq/settings/set", {"dnsmasq": {"enable": "0"}})
    print(f"    dnsmasq enable=0: {sc}")
    sc, _ = post("/dnsmasq/service/stop", t=30)
    print(f"    dnsmasq stop: {sc}")
    sc, _ = post("/dnsmasq/service/reconfigure", t=60)
    print(f"    dnsmasq reconfigure: {sc}")
    sc, _ = post("/kea/service/restart", t=60)
    print(f"    kea restart: {sc}")

    # 3)+4) NetFlow capture (all internal + WAN egress) + Insight local
    ifaces = ",".join([
        "lan",   "opt1",  "opt2",  "opt3",  "opt4",  "opt5",
        "opt6",  "opt7",  "opt8",  "opt9",  "opt10", "opt11", "opt12",
    ])
    body = {"netflow": {
        "capture": {"interfaces": ifaces, "egress_only": "opt12",
                    "version": "v9", "targets": ""},
        "collect": {"enable": "1"},
        "activeTimeout": "1800", "inactiveTimeout": "15",
    }}
    sc, txt = post("/diagnostics/netflow/setconfig", body)
    print(f"    netflow setconfig: {sc}")
    sc, txt = post("/diagnostics/netflow/reconfigure", t=30)
    print(f"    netflow reconfigure: {sc}")

    # Verify
    try:
        v = requests.get(f"{B}/diagnostics/netflow/isEnabled",
                         auth=auth, verify=False, timeout=10).json()
        print(f"    netflow_capture={v.get('netflow')} insight_local={v.get('local')}")
    except Exception as e:
        print(f"    verify err: {e}")
    return True


def start_vm_and_drive():
    print("[d] starting VM + opening termproxy...")
    api("POST", f"/nodes/{NODE}/qemu/{VMID}/status/start")
    # give qemu time to initialize VNC/serial
    time.sleep(3)
    tp = api("POST", f"/nodes/{NODE}/qemu/{VMID}/termproxy")["data"]
    qs = urllib.parse.urlencode({"port": tp["port"], "vncticket": tp["ticket"]})
    ws_url = f"wss://{HOST}:8006/api2/json/nodes/{NODE}/qemu/{VMID}/vncwebsocket?{qs}"
    ws = websocket.WebSocket(sslopt={"cert_reqs": ssl.CERT_NONE})
    ws.connect(ws_url, header=[f"Authorization: {AUTH}"], subprotocols=["binary"])
    ws.settimeout(0.1)
    ws.send_binary(f"{tp['user']}:{tp['ticket']}\n".encode())
    # Helper to send input via Proxmox termproxy channel-0 framing
    def send_input(b: bytes) -> None:
        ws.send_binary(f"0:{len(b)}:".encode() + b)
    # consume OK
    deadline = time.time() + 5
    auth_buf = b""
    while time.time() < deadline:
        try:
            c = ws.recv()
            if isinstance(c, str):
                c = c.encode()
            auth_buf += c
            if b"OK" in auth_buf:
                break
        except websocket.WebSocketTimeoutException:
            continue
    print(f"    auth: {auth_buf[:32]!r}")

    # Strategy: event-driven — DO NOT spam. Spam pollutes the input buffer and
    # the importer's `read DEV` later consumes our junk as empty device name.
    # Instead: detect "configuration importer" → send ONE \r;
    #         detect "Select device" → send "cd1\n".
    print("[e] event-driven importer drive (no spam)...")
    log = Path(f"/tmp/vm{VMID}-recreate-{int(time.time())}.log")
    f = log.open("ab")
    buf = b""
    importer_keyed = False
    device_sent = False
    success = False
    started = time.time()
    last_status = time.time()
    while time.time() - started < 240:
        try:
            chunk = ws.recv()
            if isinstance(chunk, str):
                chunk = chunk.encode()
            if chunk:
                buf += chunk
                f.write(chunk)
                f.flush()
                if len(buf) > 8192:
                    buf = buf[-4096:]
        except websocket.WebSocketTimeoutException:
            pass
        except websocket.WebSocketConnectionClosedException:
            print("    WS closed"); break

        # Step A: importer prompt detected → send single \r
        if not importer_keyed and b"configuration importer" in buf:
            print("    [A] importer prompt detected — sending single \\r")
            send_input(b"\r")
            importer_keyed = True
            buf = b""  # clear so we look for Select device next

        # Step B: device selection prompt → send DEVICE.
        # virtio-block devices (vtbdN) attach EARLY in boot, before the importer.
        # No need to wait — just send the name immediately.
        if importer_keyed and not device_sent and (b"Select device" in buf or b"leave blank" in buf):
            print(f"    [B] sending '{DEVICE}\\n'")
            time.sleep(0.5)
            send_input(f"{DEVICE}\n".encode())
            device_sent = True
            buf = b""

        # Detect success
        if device_sent and b"Restoring " in buf:
            print("    [C] config restoration started — letting it finish")
            success = True
            # let import + boot complete
            time.sleep(45)
            done = True
            break

        # Detect failure: default interface assignment
        if not device_sent and b"Default interfaces not found" in buf:
            print("    [!] importer skipped — default interface assignment is running")
            break

        if time.time() - last_status > 3:
            elapsed = int(time.time() - started)
            tail = buf[-160:].decode("utf-8", errors="replace").replace("\n", " ↩ ")
            print(f"  +{elapsed:3d}s  ik={importer_keyed} ds={device_sent}  tail=...{tail!r}")
            last_status = time.time()

    f.close()
    ws.close()
    print(f"\n[f] log saved: {log}  device_sent={device_sent}  success={success}")
    return 0 if success else 1


def check_only() -> int:
    """--check: compare the live VM hardware with the seed profile. Never writes."""
    cur = api("GET", f"/nodes/{NODE}/qemu/{VMID}/config")
    if cur.get("_missing") or not cur.get("data"):
        print(f"[check] {PROFILE['name']} (vmid {VMID}): VM ABSENT on {NODE}")
        return 2
    drift = check_drift(PROFILE, cur["data"])
    print(format_drift(PROFILE, drift))
    return 2 if drift else 0


# Hardware keys the seed may change on a LIVE VM without a recreate (no disk, no NIC).
HW_APPLY_KEYS = ("memory", "cores", "onboot", "tags")
# ... of which these only take effect after a full stop/start (not hot-pluggable here).
COLD_RESTART_KEYS = ("memory", "cores")


def apply_hardware() -> int:
    """--apply-hw: converge the in-place hardware keys of the live VM to the seed profile.

    Pushes memory/cores/onboot/tags through the PVE API (`PUT .../config`), then, when a
    cold-restart key changed and the VM is running, does a guest shutdown (ACPI/agent) and
    a start so the new memory/cores are live. Refuses when the drift includes anything
    outside HW_APPLY_KEYS (that is a recreate). Prod needs --confirm-prod-restart because
    the restart takes the running firewall down. Returns 0 = converged, 2 = drift remains.
    """
    cur = api("GET", f"/nodes/{NODE}/qemu/{VMID}/config")
    if cur.get("_missing") or not cur.get("data"):
        print(f"[apply-hw] {PROFILE['name']} (vmid {VMID}): VM ABSENT on {NODE} — nothing to apply")
        return 2
    drift = check_drift(PROFILE, cur["data"])
    print(format_drift(PROFILE, drift))
    wanted = [k for k, _, _ in drift if k in HW_APPLY_KEYS]
    other = [k for k, _, _ in drift if k not in HW_APPLY_KEYS]
    if other:
        print(f"[apply-hw] REFUSED: drift outside the in-place set {HW_APPLY_KEYS}: {other} — needs a recreate")
        return 2
    if not wanted:
        print("[apply-hw] nothing to apply")
        return 0
    needs_restart = any(k in COLD_RESTART_KEYS for k in wanted)
    if is_prod(PROFILE) and needs_restart and "--confirm-prod-restart" not in sys.argv:
        raise SystemExit(
            f"{SEED_NAME} is a PROD profile (vmid {VMID}): {wanted} needs a cold restart of the running "
            "firewall — pass --confirm-prod-restart inside a maintenance window."
        )
    body = {k: (int(PROFILE[k]) if k in ("memory", "cores", "onboot") else PROFILE[k]) for k in wanted}
    api("PUT", f"/nodes/{NODE}/qemu/{VMID}/config", body)
    print(f"[apply-hw] set {body}")
    if needs_restart:
        status = api("GET", f"/nodes/{NODE}/qemu/{VMID}/status/current")["data"].get("status")
        if status == "running":
            print("[apply-hw] cold restart (guest shutdown → start) so memory/cores take effect …")
            upid = api("POST", f"/nodes/{NODE}/qemu/{VMID}/status/shutdown", {"timeout": 180})["data"]
            print(f"[apply-hw] shutdown: {wait_task(upid, 240)}")
            upid = api("POST", f"/nodes/{NODE}/qemu/{VMID}/status/start")["data"]
            print(f"[apply-hw] start: {wait_task(upid, 120)}")
        else:
            print(f"[apply-hw] VM is {status}: the new values apply on the next start")
    cur = api("GET", f"/nodes/{NODE}/qemu/{VMID}/config")
    drift = check_drift(PROFILE, cur["data"])
    print(format_drift(PROFILE, drift))
    return 2 if drift else 0


def main():
    if "--check" in sys.argv:
        return check_only()
    if "--apply-hw" in sys.argv:
        return apply_hardware()
    if is_prod(PROFILE) and "--confirm-prod-recreate" not in sys.argv:
        raise SystemExit(
            f"{SEED_NAME} is a PROD profile (vmid {VMID}): only --check is allowed. "
            "Recreating destroys the running firewall — pass --confirm-prod-recreate "
            "inside a maintenance window if that is really intended."
        )
    if "--no-recreate" not in sys.argv:
        if not is_prod(PROFILE):  # the test FW must never carry prod ISP identities
            _assert_no_prod_isp_identity(SEED_PATH)
        recreate_vm()
    rc = start_vm_and_drive()
    # After the importer + first reboot, qemu-agent comes up — grow root.
    if rc == 0 and "--no-growfs" not in sys.argv:
        grow_root_filesystem()
    # Then turn on the monitoring/reporting features so the FW is usable for
    # incident response from the first second post-reseed (no manual WebUI
    # clicks required for "is the chain even working").
    if rc == 0 and "--no-baseline" not in sys.argv:
        apply_security_baseline()
    return rc


if __name__ == "__main__":
    sys.exit(main())

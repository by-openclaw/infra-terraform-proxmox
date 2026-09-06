#!/usr/bin/env python3
# Copyright (c) BY-SYSTEMS SRL
# SPDX-License-Identifier: Apache-2.0
#
# Destroy + recreate vm-opns-test-01 from the verified nano image, then
# drive the importer over Proxmox termproxy. Idempotent.
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
NODE = "srv-proxmox-poc-01"
VMID = 199
# ISP uplinks of the TEST FW (see the NIC block below and seed/ISP-ALLOCATION.md):
#  - net3 / Telenet (vmbrWAN2): link_down=1 by DEFAULT. The seed still carries the
#    test FW's OWN address (fabric/net-isp-telenet-test.json = 213.214.47.220/29 +
#    2a02:1802:21::6/64, borrowed from the HA-Phase2 pool) so seed rendering and
#    rule tests are realistic, but the cable stays DOWN: proven twice (2026-08-30
#    and 2026-09-06) that a second OPNsense booting live on the prod Telenet segment
#    sends a boot-time gratuitous ARP that POISONS the shared Telenet CPE's cache for
#    .222 -> prod loses Telenet v4 and does NOT self-heal (needs a manual
#    `configctl interface reconfigure opt13` on prod). Testing seeds/rules does NOT
#    need live Internet. Set TELENET_UPLINK=True ONLY for a deliberate, supervised
#    Internet test, and expect to reconfigure prod's opt13 afterwards.
#  - net2 / Proximus (vmbrWAN1): link_down=1 ALWAYS — one PPPoE account = one
#    session, a second session would fight prod. opt12 still exists in the seed so
#    catalog rules bound to it can be tested.
TELENET_UPLINK = False
PROXIMUS_UPLINK = False
TELENET_LINK = "" if TELENET_UPLINK else ",link_down=1"
PROXIMUS_LINK = "" if PROXIMUS_UPLINK else ",link_down=1"
SECRETS_DIR = Path.home() / ".openclaw/workspace/infra/secrets/fabric"
PROD_TELENET_FILE = "net-isp-telenet.json"          # pragma: allowlist secret (file NAME)
PROD_PPPOE_FILE = "net-isp-proximus-pppoe.json"     # pragma: allowlist secret (file NAME)
NANO = "poc-iso:import/OPNsense-26.7-nano-amd64.raw"  # test FW tracks latest CE for lib/MVC work
SEED_IMPORT = "poc-iso:import/vm-opns-test-01-seed.raw"
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
    """Destroy VM 199 (if it exists) and recreate it from the nano image."""
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
    config = {
        "vmid": VMID,
        "name": "vm-opns-test-01",
        "bios": "seabios", "machine": "q35", "scsihw": "virtio-scsi-single",
        "tablet": 0, "onboot": 0, "ostype": "other",
        "cpu": "host", "cores": 2, "sockets": 1, "memory": 3072,
        "boot": "order=virtio0",
        "tags": "layer0;opnsense;env-test;seed-nano",
        "agent": "0",
        "keyboard": "fr-be",
        "serial0": "socket", "vga": "std",
        "virtio0": f"poc-data:0,import-from={NANO},iothread=1,discard=on",
        "virtio1": f"poc-data:0,import-from={SEED_IMPORT},iothread=1,discard=on",
        # vtnet0 = trunk (SDN VLANs), vtnet1 = OOB, vtnet2 = WAN1 parent (PPPoE),
        # vtnet3 = WAN2 (Telenet). All four NICs must exist so the seed JSON's
        # physical_interfaces map and the rendered config.xml's interface
        # assignments (opt12 = Proximus, opt13 = Telenet) match the prod layout
        # the FW catalog expects. firewall=0 because pf rules are managed by OPNsense.
        #
        # INCIDENT 2026-08-30..09-06: this test FW carried the SAME Telenet identity
        # as prod (seed read fabric/net-isp-telenet.json). Live on vmbrWAN2 it answered
        # ARP/ND for prod's 213.214.47.222 / 2a02:1802:21::5 -> prod WAN_TELENET_GW
        # flapped 12-20 % loss and WAN_TELENET_GWv6 went Offline (92 % loss) for a
        # week. Now: net3 carries the test FW's OWN Telenet address (guarded above),
        # net2 (Proximus, single PPPoE account) is ADMINISTRATIVELY DOWN.
        "net0": "virtio,bridge=vmbrAPPS,firewall=0",
        "net1": "virtio,bridge=vmbrOOB,firewall=0",
        "net2": f"virtio,bridge=vmbrWAN1,firewall=0{PROXIMUS_LINK}",
        "net3": f"virtio,bridge=vmbrWAN2,firewall=0{TELENET_LINK}",
    }
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


def main():
    if "--no-recreate" not in sys.argv:
        _assert_no_prod_isp_identity(Path(__file__).parent / "seeds" / "vm-opns-test-01.json")
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

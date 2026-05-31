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
    p = Path("/home/by-systems/.openclaw/workspace/infra/secrets/infra-proxmox-poc.json")
    f = json.loads(p.read_text())["fields"]
    return f["host"], f["admin_token_id"], f["admin_token_secret"]


HOST, TID, TSEC = load()
AUTH = f"PVEAPIToken={TID}={TSEC}"
NODE = "srv-proxmox-poc-01"
VMID = 199
NANO = "poc-iso:import/OPNsense-26.1.6-nano-amd64.raw"
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
        # vtnet3 = WAN2 (Telenet). Without net2/net3 the seed comes up without
        # WAN — PPPoE has no parent NIC, pkg can't download plugins, recovery
        # is manual. All four are required to match the seed JSON's
        # physical_interfaces map and the rendered config.xml's interface
        # assignments. firewall=0 because pf rules are managed by OPNsense.
        "net0": "virtio,bridge=vmbrAPPS,firewall=0",
        "net1": "virtio,bridge=vmbrOOB,firewall=0",
        "net2": "virtio,bridge=vmbrWAN1,firewall=0",
        "net3": "virtio,bridge=vmbrWAN2,firewall=0",
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
        recreate_vm()
    rc = start_vm_and_drive()
    # After the importer + first reboot, qemu-agent comes up — grow root.
    if rc == 0 and "--no-growfs" not in sys.argv:
        grow_root_filesystem()
    return rc


if __name__ == "__main__":
    sys.exit(main())

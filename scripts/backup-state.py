#!/usr/bin/env python3
"""Post-apply Terraform state backup to Synology NAS.

Usage (called automatically via wrapper or manually):
    python3 scripts/backup-state.py [--env poc]

Reads state from environments/<env>/terraform.tfstate
Uploads to NAS /by-terraform-state/<env>/terraform.tfstate
"""

import argparse
import json
import os
import sys
from pathlib import Path

# Allow running from repo root without install
sys.path.insert(0, str(Path(__file__).parent.parent.parent / "lib-synology-dsm" / "src"))

try:
    from synology_dsm.client import DSMClient
    from synology_dsm.filestation import FileStationManager
except ImportError:
    # Fallback: try installed package
    from synology_dsm.client import DSMClient
    from synology_dsm.filestation import FileStationManager

# Credentials come from the controller's secret store, never from this file. They used to be
# literals here: the account was rotated, every apply since has printed a login failure nobody
# read, and the state of every environment existed only on this controller.
SECRET_FILE = Path(
    os.environ.get(
        "NAS_SECRET_FILE",
        Path.home() / ".openclaw/workspace/infra/secrets/fabric/infra-synology-nas.json",
    )
)
NAS_SHARE = os.environ.get("NAS_SHARE", "by-terraform-state")


def _nas_credentials() -> tuple[str, int, str, str]:
    """host, port, user, password — from the fabric secret (Vault mirrors it)."""
    if not SECRET_FILE.exists():
        print(f"❌ NAS credential not found: {SECRET_FILE}")
        sys.exit(2)
    fields = json.loads(SECRET_FILE.read_text()).get("fields", {})
    user = fields.get("svc_rune_username") or fields.get("svc_opus_username")
    password = fields.get("svc_rune_password") or fields.get("svc_opus_password")
    if not (fields.get("host") and user and password):
        print(f"❌ NAS credential incomplete in {SECRET_FILE}")
        sys.exit(2)
    return fields["host"], int(fields.get("port", 5001)), user, password


def backup(env: str = "poc") -> None:
    repo_root = Path(__file__).parent.parent
    state_file = repo_root / "environments" / env / "terraform.tfstate"

    if not state_file.exists():
        print(f"❌ State file not found: {state_file}")
        sys.exit(1)

    print(f"📦 Backing up {state_file} → NAS /{NAS_SHARE}/{env}/")

    nas_host, nas_port, nas_user, nas_pass = _nas_credentials()
    c = DSMClient(nas_host, port=nas_port, https=True, verify_ssl=False)
    c.login(nas_user, nas_pass)

    fs = FileStationManager(c)
    result = fs.upload(
        local_path=str(state_file),
        dest_folder=f"/{NAS_SHARE}/{env}",
        overwrite=True,
    )

    if result.get("action") in ("uploaded", "skipped"):
        print(f"✅ State backed up → /{NAS_SHARE}/{env}/terraform.tfstate")
    else:
        print(f"❌ Backup failed: {result}")
        sys.exit(1)

    c.logout()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Backup Terraform state to NAS")
    parser.add_argument("--env", default="poc", help="Environment name (default: poc)")
    args = parser.parse_args()
    backup(args.env)

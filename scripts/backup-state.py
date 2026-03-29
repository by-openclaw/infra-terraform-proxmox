#!/usr/bin/env python3
"""Post-apply Terraform state backup to Synology NAS.

Usage (called automatically via wrapper or manually):
    python3 scripts/backup-state.py [--env poc]

Reads state from environments/<env>/terraform.tfstate
Uploads to NAS /by-terraform-state/<env>/terraform.tfstate
"""

import argparse
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

NAS_HOST = "10.6.224.6"
NAS_PORT = 5001
NAS_USER = "rune-api"
NAS_PASS = "BySyst3ms_"
NAS_SHARE = "by-terraform-state"


def backup(env: str = "poc") -> None:
    repo_root = Path(__file__).parent.parent
    state_file = repo_root / "environments" / env / "terraform.tfstate"

    if not state_file.exists():
        print(f"❌ State file not found: {state_file}")
        sys.exit(1)

    print(f"📦 Backing up {state_file} → NAS /{NAS_SHARE}/{env}/")

    c = DSMClient(NAS_HOST, port=NAS_PORT, https=True, verify_ssl=False)
    c.login(NAS_USER, NAS_PASS)

    fs = FileStationManager(c)
    result = fs.upload(
        local_path=str(state_file),
        dest_folder=f"/{NAS_SHARE}/{env}",
        overwrite=True,
    )

    if result.get("success"):
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

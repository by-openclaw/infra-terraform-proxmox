#!/bin/bash
# tf.sh — Terraform wrapper with auto state backup to NAS after apply
# Usage: ./scripts/tf.sh [apply|plan|destroy|...] [args...]
#
# After a successful apply or destroy, state is automatically backed up to NAS.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# The backup helper lives in lib-synology-dsm; its checkout moved out of the workspace path.
# Resolve it, and fail loudly rather than silently skipping the state backup.
VENV_PYTHON="${TF_BACKUP_PYTHON:-$HOME/repos/lib-synology-dsm/.venv/bin/python}"
ENV="${TF_ENV:-poc}"

# Determine working dir from env
TF_DIR="${REPO_ROOT}/environments/${ENV}"

if [[ ! -d "$TF_DIR" ]]; then
  echo "❌ Environment directory not found: $TF_DIR"
  exit 1
fi

cd "$TF_DIR"
echo "📁 Working in: $TF_DIR"

# Run terraform
terraform "$@"
EXIT_CODE=$?

# Auto-backup state after apply or destroy
if [[ $EXIT_CODE -eq 0 ]] && [[ "${1:-}" =~ ^(apply|destroy)$ ]]; then
  echo ""
  echo "🔄 Backing up state to NAS..."
  if [[ ! -x "$VENV_PYTHON" ]]; then
    echo "❌ state NOT backed up: $VENV_PYTHON is missing (set TF_BACKUP_PYTHON)." >&2
    echo "   The state of $ENV exists only on this controller until that is fixed." >&2
    exit 2
  fi
  "$VENV_PYTHON" "${SCRIPT_DIR}/backup-state.py" --env "$ENV"
fi

exit $EXIT_CODE

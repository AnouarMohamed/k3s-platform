#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_DIR}"

encrypted="${SOPS_ENCRYPTED_SECRETS_FILE:-secrets/production.enc.yaml}"

if ! command -v sops >/dev/null 2>&1; then
  echo "sops is required. Install SOPS before applying production secrets." >&2
  exit 1
fi

if [[ ! -f "${encrypted}" ]]; then
  echo "Missing ${encrypted}. Production secrets must be encrypted in Git with SOPS + Age." >&2
  exit 1
fi

sops --decrypt "${encrypted}" | kubectl apply -f -

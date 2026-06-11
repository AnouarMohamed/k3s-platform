#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_DIR}"

plain="${SOPS_PLAIN_SECRETS_FILE:-secrets/production.plain.yaml}"
encrypted="${SOPS_ENCRYPTED_SECRETS_FILE:-secrets/production.enc.yaml}"

if ! command -v sops >/dev/null 2>&1; then
  echo "sops is required. Install SOPS before encrypting production secrets." >&2
  exit 1
fi

if [[ -z "${SOPS_AGE_RECIPIENTS:-}" ]]; then
  echo "SOPS_AGE_RECIPIENTS must contain one or more Age public recipients." >&2
  exit 1
fi

if [[ ! -f "${plain}" ]]; then
  echo "Missing ${plain}. Start from secrets/production.plain.example.yaml." >&2
  exit 1
fi

if grep -Eq 'replace-|change-me|example\.com|admin@example\.com' "${plain}"; then
  echo "${plain} still contains placeholders." >&2
  exit 1
fi

sops --encrypt \
  --age "${SOPS_AGE_RECIPIENTS}" \
  --encrypted-regex '^(data|stringData)$' \
  "${plain}" > "${encrypted}"

echo "Encrypted ${plain} -> ${encrypted}"

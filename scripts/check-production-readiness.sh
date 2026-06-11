#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_DIR}"

KUSTOMIZE_PATH="${KUSTOMIZE_PATH:-.}"
REQUIRE_REAL_PRODUCTION_VALUES="${REQUIRE_REAL_PRODUCTION_VALUES:-false}"

./scripts/check-manifests.sh

if [[ "${REQUIRE_REAL_PRODUCTION_VALUES}" == "true" ]]; then
  if [[ ! -f secrets/production.enc.yaml ]]; then
    echo "Missing secrets/production.enc.yaml. Production state is not reproducible from Git." >&2
    exit 1
  fi

  if grep -REq 'example\.com|admin@example\.com|203\.0\.113\.|0\.0\.0\.0/0' platform/settings.yaml; then
    echo "Example settings or unsafe admin allowlist still present." >&2
    exit 1
  fi
fi

rendered="$(mktemp)"
trap 'rm -f "${rendered}"' EXIT
kubectl kustomize "${KUSTOMIZE_PATH}" > "${rendered}"

for required in \
  'kind: CronJob' \
  'name: prometheus' \
  'name: alertmanager' \
  'name: node-exporter' \
  'name: prometheus-rules' \
  'name: grafana' \
  'name: loki' \
  'namespace: data' \
  'namespace: ops' \
  'nginx.ingress.kubernetes.io/whitelist-source-range'; do
  if ! grep -q "${required}" "${rendered}"; then
    echo "Rendered manifests missing required production control: ${required}" >&2
    exit 1
  fi
done

if [[ "${REQUIRE_REAL_PRODUCTION_VALUES}" == "true" ]]; then
  echo "Strict production readiness check passed."
else
  echo "Structural production readiness check passed. Set REQUIRE_REAL_PRODUCTION_VALUES=true for real cutover gates."
fi

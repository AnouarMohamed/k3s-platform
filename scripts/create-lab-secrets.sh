#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_DIR}"

if [[ ! -f ".env" ]]; then
  echo "Missing .env. Copy .env.example first." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source ".env"
set +a

kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f -

kubectl -n apps create secret generic wordpress-demo-secret \
  --from-literal=MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:?}" \
  --from-literal=WORDPRESS_DB_PASSWORD="${WORDPRESS_DB_PASSWORD:?}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n apps create secret generic superset-secret \
  --from-literal=SUPERSET_SECRET_KEY="${SUPERSET_SECRET_KEY:?}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n apps create secret generic passbolt-secret \
  --from-literal=PASSBOLT_DB_PASSWORD="${PASSBOLT_DB_PASSWORD:?}" \
  --dry-run=client -o yaml | kubectl apply -f -

PORTAINER_ADMIN_PASSWORD_HASH="${PORTAINER_ADMIN_PASSWORD_HASH:-}"
if [[ -z "${PORTAINER_ADMIN_PASSWORD_HASH}" ]]; then
  PORTAINER_ADMIN_PASSWORD_HASH='$2y$05$replace-this-with-real-hash'
fi

kubectl -n apps create secret generic portainer-secret \
  --from-literal=PORTAINER_ADMIN_PASSWORD_HASH="${PORTAINER_ADMIN_PASSWORD_HASH}" \
  --dry-run=client -o yaml | kubectl apply -f -

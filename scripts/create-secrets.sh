#!/usr/bin/env bash
# Purpose: Generates and applies Kubernetes Secrets in the 'apps' namespace from local environment variables.
# This script ensures that all sensitive configuration is properly loaded and validated before creation.
#
# Environment Variables:
#   Loaded from .env. See .env.example for a full list of required variables (passwords, API keys, etc).
#
# Error Handling:
#   The script will exit if .env is missing or if any required secret contains placeholder values
#   like 'change-me' or 'example.com'.

set -Eeuo pipefail

# Ensure we are in the repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_DIR}"

# Check for existence of .env file
if [[ ! -f ".env" ]]; then
  echo "Error: Missing .env file. Copy .env.example first and replace every placeholder." >&2
  exit 1
fi

# Load environment variables into the script
set -a
# shellcheck disable=SC1091
source ".env"
set +a

# Function: require_secret
# Validates that a secret is set and does not look like a default placeholder.
# Arguments:
#   $1 - Name of the environment variable to check.
require_secret() {
  local name="$1"
  local value="${!name:-}"

  if [[ -z "${value}" ]]; then
    echo "Error: ${name} must be set in .env" >&2
    exit 1
  fi

  # Security check: Prevent using common placeholder strings in production
  case "${value}" in
    *change-me*|*replace-*|admin|password|example|*example.com*|admin@example.com)
      echo "Error: ${name} still looks like a placeholder value" >&2
      exit 1
      ;;
  esac
}

# Validate all required secrets for the applications
require_secret MYSQL_ROOT_PASSWORD
require_secret WORDPRESS_DB_PASSWORD
require_secret SUPERSET_SECRET_KEY
require_secret SUPERSET_ADMIN_USERNAME
require_secret SUPERSET_ADMIN_FIRSTNAME
require_secret SUPERSET_ADMIN_LASTNAME
require_secret SUPERSET_ADMIN_EMAIL
require_secret SUPERSET_ADMIN_PASSWORD
require_secret PASSBOLT_DB_PASSWORD
require_secret PORTAINER_ADMIN_PASSWORD_HASH

# Ensure the 'apps' namespace exists before creating secrets
echo "Ensuring 'apps' namespace exists..."
kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f -

# Create or update secrets in the cluster.
# We use --dry-run=client -o yaml piped to kubectl apply -f - to make the operation idempotent.

echo "Applying wordpress-demo-secret..."
kubectl -n apps create secret generic wordpress-demo-secret \
  --from-literal=MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
  --from-literal=WORDPRESS_DB_PASSWORD="${WORDPRESS_DB_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Applying superset-secret..."
kubectl -n apps create secret generic superset-secret \
  --from-literal=SUPERSET_SECRET_KEY="${SUPERSET_SECRET_KEY}" \
  --from-literal=SUPERSET_ADMIN_USERNAME="${SUPERSET_ADMIN_USERNAME}" \
  --from-literal=SUPERSET_ADMIN_FIRSTNAME="${SUPERSET_ADMIN_FIRSTNAME}" \
  --from-literal=SUPERSET_ADMIN_LASTNAME="${SUPERSET_ADMIN_LASTNAME}" \
  --from-literal=SUPERSET_ADMIN_EMAIL="${SUPERSET_ADMIN_EMAIL}" \
  --from-literal=SUPERSET_ADMIN_PASSWORD="${SUPERSET_ADMIN_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Applying passbolt-secret..."
kubectl -n apps create secret generic passbolt-secret \
  --from-literal=PASSBOLT_DB_PASSWORD="${PASSBOLT_DB_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Applying portainer-secret..."
kubectl -n apps create secret generic portainer-secret \
  --from-literal=PORTAINER_ADMIN_PASSWORD_HASH="${PORTAINER_ADMIN_PASSWORD_HASH}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secrets applied successfully."

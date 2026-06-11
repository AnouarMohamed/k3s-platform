#!/usr/bin/env bash
# Purpose: Applies the Kustomize manifests to the Kubernetes cluster.
# This script handles the deployment of both platform-level components and applications.
#
# Environment Variables:
#   ALLOW_EXAMPLE_VALUES: Set to "true" to bypass the check for "example.com" in settings.yaml.
#                         Useful for local development or testing.

set -Eeuo pipefail

# Ensure we are in the repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_DIR}"

# Safety check: Prevent accidental deployment with example production values.
# It searches for 'example.com' or 'admin@example.com' in platform/settings.yaml.
# This ensures that users have configured their own domain and email for Let's Encrypt.
if grep -Eq '(^|[^[:alnum:]])(example\.com|admin@example\.com)([^[:alnum:]]|$)' platform/settings.yaml; then
  if [[ "${ALLOW_EXAMPLE_VALUES:-false}" != "true" ]]; then
    echo "Error: platform/settings.yaml still contains example production values." >&2
    echo "Replace domains and letsencryptEmail, or set ALLOW_EXAMPLE_VALUES=true for a non-production test apply." >&2
    exit 1
  fi
fi

# Apply all manifests using Kustomize. 
# This will create/update resources defined in kustomization.yaml and its references.
echo "Applying manifests..."
kubectl apply -k .

# Post-apply summary: Display the status of namespaces and ingresses to verify deployment.
echo "Verifying deployment..."
kubectl get namespaces
kubectl get ingress -A
